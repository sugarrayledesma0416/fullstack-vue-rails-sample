import CourseSerializer from 'features/course_wizard/services/course_serializer';
let courseSerializer;
let course = {
  allowsHelpRequests: true,
  allowsReviewRequests: true,
  categories: [
    {
      acceptLateWork: true,
      creditOnly: false,
      currentScoringRuleset: 'Baz',
      dropLowScores: 3,
      enhancedFeedbackDisabled: false,
      hasAssessmentAssignments: true,
      id: 1,
      lateWorkPenalty: 'percent_per_day',
      maxAttempts: 2,
      name: 'Bar',
      penaltyPercent: 5,
      rank: 0,
      structure: 'by_lesson_and_strand',
      weightingPercent: 100,
      _destroy: false,
    },
  ],
  chatLevel: 'partner_chat_only',
  aiVirtualChatLevel: false,
  copyCreatedActivitiesFromPreviousCourse: true,
  courseLibraryFrom: 789,
  components: [5],
  endDate: '1/1/2022',
  firstUnitId: 2,
  id: 99,
  lastUnitId: 3,
  level: 4,
  name: 'Foo',
  sections: [{ name: 'Quux' }],
  schoolId: 1,
  startDate: '1/1/2021',
};

describe('Coure Serializer', () => {
  describe('init course serializer', () => {
    beforeEach(() => {
      courseSerializer = new CourseSerializer(course);
    });

    it('returns an object with attributes in the correct format', () => {
      expect(courseSerializer.serialize()).toEqual({
        course: {
          allow_audio_transcripts: undefined,
          allow_individual_assign: undefined,
          allow_video_popup_translation: undefined,
          allows_help_requests: true,
          allows_review_requests: true,
          categories_attributes: [
            {
              accept_late_work: true,
              credit_only: false,
              drop_low_scores: 3,
              enhanced_feedback_disabled: false,
              id: 1,
              late_work_penalty: 'percent_per_day',
              max_attempts: 2,
              name: 'Bar',
              penalty_percent: 5,
              rank: 0,
              scoring_rulesets_attributes: [
                {
                  ignore_accents: true,
                  ignore_punctuation: true,
                  ignore_capitalization: true,
                },
              ],
              structure: 'by_lesson_and_strand',
              weighting_percent: 100,
              _destroy: false,
            },
          ],
          chat_level: 'partner_chat_only',
          copy_created_activities_from_previous_course: true,
          copy_shared_activities_from_previous_course: undefined,
          course_library_from: 789,
          course_package_ids: [4, 5],
          enable_vocab_tutorial_translations: undefined,
          end_date: '1/1/2022',
          first_unit_id: 2,
          hide_from_instructor_dashboard: true,
          id: 99,
          is_template: false,
          last_unit_id: 3,
          lti_roster_linked: undefined,
          name: 'Foo',
          one_roster_linked: undefined,
          owner_id: undefined,
          portfolio_activity_types: undefined,
          school_id: 1,
          selected_learning_track: undefined,
          share_to_google_classroom: undefined,
          share_to_portfolio: undefined,
          show_estimated_times: undefined,
          standard_set_ids: undefined,
          start_date: '1/1/2021',
          video_subtitle_languages: undefined,
          video_transcript_languages: undefined,
          ai_virtual_chat_level: false,
        },
        section: {
          class_days: ''
        },
        sections: ['Quux'],
      });
    });
  });

  describe('#course_packages_names', () => {
    let courseOptions;
    beforeEach(() => {
      course = { level: 1, components: [2] };
      courseSerializer = new CourseSerializer(course);
      courseOptions = {
        levels: [{ id: 1, name: 'level 1' }, { id: 2, name: 'level 2' }],
        components: [{ id: 2, name: 'component 1' }, { id: 3, name: 'component 2' }],
      };
    });

    it('returns an array of Level name selected and Component names selected', () => {
      expect(courseSerializer.coursePackagesNames(
        courseOptions.levels, courseOptions.components
      )).toEqual(['level 1', 'component 1']);
    });
  });

  describe('serialize', () => {
    it('includes ai_virtual_chat_level in the serialized course', () => {
      const serialized = courseSerializer.serialize();
      expect(serialized.course).toHaveProperty('ai_virtual_chat_level');
    });

    it('converts aiVirtualChatLevel to ai_virtual_chat_level', () => {
      course.aiVirtualChatLevel = true;
      const serialized = courseSerializer.serialize();
      expect(serialized.course.ai_virtual_chat_level).toBe(true);
    });
  });
});
