import { pluck, pick } from 'shared/utils';

/**
 * @typedef CategoryObject
 * @property {number} id
 * @property {string} name
 * @property {number} weightingPercent
 * @property {boolean} hasAssessmentAssignments
 * @property {boolean} hasAssignments
 * @property {boolean} creditOnly
 * @property {number} maxAttempts
 * @property {boolean} enhancedFeedbackDisabled
 * @property {boolean} acceptLateWork
 * @property {string} lateWorkPenalty
 * @property {number} penaltyPercent
 * @property {number} rank
 * @property {number} dropLowScores
 */

/**
 * @typeDef CourseObject
 * @property {boolean} allowMultipleLessonsOnDates
 * @property {boolean} allowsHelpRequests
 * @property {boolean} allowsReviewRequests
 * @property {boolean} breakGroupAcrossDates
 * @property {boolean} breakStrandAcrossDates
 * @property {Array.<CategoryObject>} categories
 * @property {string} chatLevel
 * @property {boolean} copyCreatedActivitiesFromPreviousCourse
 * @property {boolean} copySharedActivitiesFromPreviousCourse
 * @property {Array} components
 * @property {string} currentStep
 * @property {boolean} enableVocabTutorialTranslations
 * @property {string} endDate
 * @property {number} firstUnitId
 * @property {boolean} isTemplate
 * @property {number} lastUnitId
 * @property {number} level
 * @property {number} ltiRosterLinked
 * @property {string} name
 * @property {string} namePlaceholder
 * @property {string} oneRosterLinked
 * @property {string} pathType
 * @property {Array.<CategoryObject>} removedCategories
 * @property {Array.<SectionObject>} sections
 * @property {string} selectedLearningTrack
 * @property {boolean} shareToGoogleClassroom
 * @property {boolean} showEstimatedTimes
 * @property {string} startDate
 * @property {Array.<StandardObject>} standards
 */

/**
 * @typedef CourseSerializedObject
 * @property {CourseObject} course
 * @property {Array.<string>} sections
 */

/**
 * Course Serializer Class.
 */
class CourseSerializer {
  /**
   * Initialize Course Serializer
   * @constructor
   * @param {CourseObject} course - Either Assignment Wizard or Course Express
   */
  constructor(course) {
    this.course = course;
  }

  /**
   * returns course package names.
   * @param {Array.<LevelObject>} levelOpts
   * @param {Array.<ComponentObject>} componentOpts
   * @return {Array.<string>}
   */
  coursePackagesNames(levelOpts, componentOpts) {
    const courseLevel = levelOpts.filter((level) => {
      return level.id === this.course.level;
    });
    const courseLevelName = pluck(courseLevel, 'name');
    const courseComponents = componentOpts.filter((component) => {
      return this.course.components.includes(component.id);
    });
    const courseComponentsNames = pluck(courseComponents, 'name');
    return courseLevelName.concat(courseComponentsNames);
  }

  /**
   * Format class days of a course.
   * Only relevant for enterprise courses
   * @param {Object} course - Instance of Course model.
   * @return {string} A comma separated list of the days on which
   * the course meets, with each day represented by an index, with 0
   * equal to Sunday.
   */
  prepClassDays(course) {
    const classDays = [];
    if (course.classDays) {
      for (const index in course.classDays) {
        if (course.classDays[index]) {
          classDays.push(index);
        }
      }
    }

    return classDays.join(',');
  }

  /**
   * returns serialized object.
   * Generate summary pdf (in edit course) fails when categories_attributes
   * key is before the id key. So made the categories_attributes as the last
   * key in payload to server.
   * @return {CourseSerializedObject}
   */
  serialize() {
    return {
      course: {
        allow_audio_transcripts: this.course.allowAudioTranscripts,
        allow_individual_assign: this.course.allowIndividualAssign,
        allow_video_popup_translation: this.course.allowVideoPopupTranslation,
        portfolio_activity_types: this.course.portfolioActivityTypes,
        allows_help_requests: this.course.allowsHelpRequests,
        allows_review_requests: this.course.allowsReviewRequests,
        chat_level: this.course.chatLevel,
        ai_virtual_chat_level: this.course.aiVirtualChatLevel,
        copy_created_activities_from_previous_course:
          this.course.copyCreatedActivitiesFromPreviousCourse,
        copy_shared_activities_from_previous_course:
          this.course.copySharedActivitiesFromPreviousCourse,
        course_library_from: this.course.courseLibraryFrom,
        owner_id: this.course.courseOwnerUserId,
        course_package_ids: this.coursePackageIds(),
        enable_vocab_tutorial_translations: this.course.enableVocabTutorialTranslations,
        end_date: this.course.endDate,
        first_unit_id: this.course.firstUnitId,
        hide_from_instructor_dashboard: !this.course.displayOnDashboard,
        id: this.course.id,
        is_template: false, // We no longer allow course templates
        last_unit_id: this.course.lastUnitId,
        lti_roster_linked: this.course.ltiRosterLinked,
        name: this.course.name,
        one_roster_linked: this.course.oneRosterLinked,
        school_id: this.course.schoolId,
        selected_learning_track: this.course.selectedLearningTrack,
        share_to_google_classroom: this.course.shareToGoogleClassroom,
        share_to_portfolio: this.course.shareToPortfolio,
        show_estimated_times: this.course.showEstimatedTimes,
        start_date: this.course.startDate,
        video_subtitle_languages: this.course.videoSubtitleLanguages,
        video_transcript_languages: this.course.videoTranscriptLanguages,
        categories_attributes: this.categories(),
        standard_set_ids: this.course.standardSetIds,
      },
      section: {
        class_days: this.prepClassDays(this.course)
      },
      sections: this.sectionNames(),
    };
  }

  /**
   * @private
   * Return category attributes in a form that Rails can easily work with.
   * @return {Array.<CategoryObject>}
   */
  categories() {
    const categories = this.course.categories?.map((category) => {
      return Object.assign(
        this.serializeCategory(pick(
          category,
          'acceptLateWork',
          'creditOnly',
          'dropLowScores',
          'enhancedFeedbackDisabled',
          'id',
          'lateWorkPenalty',
          'maxAttempts',
          'name',
          'penaltyPercent',
          'rank',
          'structure',
          'weightingPercent',
          '_destroy'
        )),
        {
          scoring_rulesets_attributes: [this.rulesetAttributes(category.currentScoringRuleset)],
        }
      );
    }) ?? [];

    return categories.filter(Boolean);
  }

  /**
   * @private
   * Pluck ids from levels and components.
   * @return {Array.<number>}
   */
  coursePackageIds() {
    return [this.course.level].concat(this.course.components).filter(Boolean);
  }

  /**
   * @private
   * Always invert the attributes because the attrs on the server side
   * are negative (ignore_accent instead of must_match_accents).
   * @param {Object} ruleset
   * @return {Object}
   */
  rulesetAttributes(ruleset) {
    return {
      ignore_accents: !ruleset.mustMatchAccents,
      ignore_capitalization: !ruleset.mustMatchCapitalization,
      ignore_punctuation: !ruleset.mustMatchPunctuation,
    };
  }

  /**
   * @private
   * Pluck section names only
   * @return {Array.<string>} section names
   */
  sectionNames() {
    let sections = this.course.sections ? this.course.sections : [];
    sections = sections.map((section) => {
      return section.name;
    });
    return sections.filter(Boolean);
  }

  /**
   * @private
   * Serialize Category Object.
   * @param {Category} category
   * @return {Category}
   */
  serializeCategory(category) {
    return {
      accept_late_work: category.acceptLateWork,
      credit_only: category.creditOnly,
      drop_low_scores: category.dropLowScores,
      enhanced_feedback_disabled: category.enhancedFeedbackDisabled,
      id: category.id,
      late_work_penalty: category.lateWorkPenalty,
      max_attempts: category.maxAttempts,
      name: category.name,
      penalty_percent: category.penaltyPercent,
      rank: category.rank,
      structure: category.structure,
      weighting_percent: category.weightingPercent,
      _destroy: category._destroy ? true : false,
    };
  }
}

export default CourseSerializer;
