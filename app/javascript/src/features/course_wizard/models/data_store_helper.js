import { toRef, watch } from 'vue';
import { omit } from 'shared/utils';
import Category from 'features/category_wizard/models/category';
import { createSection } from 'features/section_wizard/models/section';
import { maxInArray, pluck } from 'shared/utils';

/**
 * @typedef {
 *  import('features/course_wizard/models/new_course_data_store.js').CourseOptionsResponseDataType
 * } CourseOptionsResponseDataType
 */

/**
 * @typedef {
 *  import('features/course_wizard/models/new_course_data_store.js').CoursePackageDataType
 * } CoursePackageDataType
 */

/**
 * @typedef {
 *  import('features/course_wizard/models/new_course_data_store.js').NewCourseDataStoreType
 * } NewCourseDataStoreType
 */

/**
 * @typedef {
 *  import('features/course_wizard/models/edit_course_data_store.js').EditCourseDataStoreType
 * } EditCourseDataStoreType
 */

/**
 * This class has common methods used in New/EditDataStore to manipulate the app state.
 */
export default class DataStoreHelper {
  /**
   * @constructor
   * @param {NewCourseDataStoreType|EditCourseDataStoreType} store
   */
  constructor(store) {
    this.store = store;
  }

  /**
   * Adds watcher on firstUnitId
   * @param {CourseOptionsResponseDataType} courseOptions
   * @param {Array.<number>} unitIds
   */
  addWatcherForFirstUnitId(courseOptions, unitIds) {
    const firstUnitIdRef = toRef(this.store.course, 'firstUnitId');
    watch(firstUnitIdRef, (firstUnitId) => {
      this.updateUnitOptions(courseOptions, unitIds, firstUnitId);
    });
  }

  /**
   * Adds watcher on contentSettingsCourse
   * @param {CourseOptionsResponseDataType} courseOptions
   */
  addWatcherForContentSettingsCourse(courseOptions) {
    const contentSettingsCourseRef = toRef(this.store.settingsCourses, 'contentSettingsCourse');
    watch(contentSettingsCourseRef, (contentSettings) => {
      if (contentSettings) {
        this.updateCourseFromContentSettings(contentSettings);

        /* @see: https://vistahl.atlassian.net/browse/MAE-15659 is dealt with. */
        if (this.store.course.level === null) {
          // Temporary Fix
          this.store.course.level = courseOptions.levels[0] ? courseOptions.levels[0].id : null;
        }
        this.store.course.components = contentSettings.components;
      }
      this.setLevelAndComponents(courseOptions);
    });
  }

  /**
   * This method gets new category instances from category data in categorySettingsCourse.
   * We are making new categories so id is removed from category and scoring ruleset.
   * @param {Array.<CategoryArgsObject>} categories - categories in categorySettingsCourse
   * @param {string} languageCode - Program language code
   * @return {Array.<Category>}
   */
  getCategoriesFromSettingsData(categories, languageCode) {
    return categories?.map((category) =>{
      const scoringRuleset = {
        current_scoring_ruleset: omit(['id'], category.current_scoring_ruleset),
      };
      const cleanCategory = omit(['id'], category);
      const newCategory = Object.assign({}, cleanCategory, scoringRuleset);
      newCategory['languageCode'] = languageCode;
      return new Category(newCategory);
    }) ?? [];
  }

  /**
   * This method converts to Section instances from section objects in course options
   * @param {CourseOptionsResponseDataType} courseOptions
   */
  loadSections(courseOptions) {
    courseOptions.settings.forEach((courseOptionsSetting) => {
      courseOptionsSetting.sections = courseOptionsSetting.sections ?
        courseOptionsSetting.sections.map(createSection) : [];
    });
  }

  /**
   * Setup level and components automatically (SL)
   * @param {CourseOptionsResponseDataType} courseOptions
   */
  setLevelAndComponents(courseOptions) {
    if (courseOptions.available_course_packages?.length) {
      this.store.course.level = this.selectedLevel(courseOptions).id;
      const selectedComponents = this.getCoursePackagesByContentType(courseOptions, 'component');
      this.store.course.components = pluck(selectedComponents, 'id');
    }
  }

  /**
   * Update course settings from server response.
   *
   * Copy settings from previous courses. Each of the 3 main custom
   * course steps can copy different settings. These used to live in
   * the individual step controllers, but this caused problems when
   * the controller was re-instantiated and cloberred the user's
   * custom settings.
   * @param {CourseOptionsResponseDataType} courseOptions
   */
  updateCourseSettings(courseOptions) {
    this.store.settingsCourses.dateSettingsCourse = courseOptions.settings[0];
    this.store.settingsCourses.contentSettingsCourse = courseOptions.settings[0];
    this.store.settingsCourses.categorySettingsCourse = courseOptions.settings[0];
  }

  /**
   * This method updates school id in course in store.
   * @param {CourseOptionsResponseDataType} courseOptions
   */
  updateSchoolId(courseOptions) {
    if (courseOptions.selected_school_id) {
      this.store.course.schoolId = parseInt(courseOptions.selected_school_id);
    } else if (courseOptions.course) {
      this.store.course.schoolId = courseOptions.course.school_id;
    }
  }

  /**
   * @private
   * Returns available course packages for given content
   * @param {CourseOptionsResponseDataType} courseOptions
   * @param {string} contentType
   * @return {Array.<CoursePackageDataType>}
   */
  getCoursePackagesByContentType(courseOptions, contentType) {
    return courseOptions.available_course_packages?.reduce((memo, packageObj) => {
      if (packageObj.content_type === contentType) {
        memo.push(packageObj);
      }
      return memo;
    }, []);
  }

  /**
   * @private
   * Returns available course packages which have content type as level
   * @param {CourseOptionsResponseDataType} courseOptions
   * @return {CoursePackageDataType}
   */
  selectedLevel(courseOptions) {
    const levels = this.getCoursePackagesByContentType(courseOptions, 'level');
    return maxInArray(levels, (level) => level.rank);
  }

  /**
   * @private
   * Update Course in the store from ContentSettingsCourse
   * @param {ContentSettingsCourseDataType} contentSettings
   */
  updateCourseFromContentSettings(contentSettings) {
    this.store.course.firstUnitId = contentSettings.first_unit_id;
    this.store.course.lastUnitId = contentSettings.last_unit_id;
    this.store.course.allowAudioTranscripts = contentSettings.allow_audio_transcripts;
    this.store.course.videoSubtitleLanguages = contentSettings.video_subtitle_languages;
    this.store.course.videoTranscriptLanguages = contentSettings.video_transcript_languages;
    this.store.course.allowVideoPopupTranslation = contentSettings.allow_video_popup_translation;
    this.store.course.allowsReviewRequests = contentSettings.allows_review_requests;
    this.store.course.allowsHelpRequests = contentSettings.allows_help_requests;
    this.store.course.chatLevel = contentSettings.chat_level;
    this.store.course.shareToGoogleClassroom = contentSettings.share_to_google_classroom;
    this.store.course.showEstimatedTimes = contentSettings.show_estimated_times;
    this.store.course.courseLibraryFrom = contentSettings.id;
    this.store.course.allowIndividualAssign = contentSettings.allow_individual_assign;

    this.store.course.level = contentSettings.level;
    this.store.course.shareToPortfolio = contentSettings.share_to_portfolio;
    this.store.course.portfolioActivityTypes = contentSettings.portfolio_activity_types;
    this.store.course.canShareToPortfolio = contentSettings.can_share_to_portfolio;

    const enableVocabTutorialTranslations = contentSettings.enable_vocab_tutorial_translations;
    this.store.course.enableVocabTutorialTranslations = enableVocabTutorialTranslations;
    if (contentSettings.id !== null) {
      // if course is a template only copy shared IGC
      if (this.store.course.isTemplate) {
        this.store.course.copySharedActivitiesFromPreviousCourse = true;
      } else {
        this.store.course.copyCreatedActivitiesFromPreviousCourse = true;
      }
    }
    this.store.course.standardSetIds = contentSettings.standard_set_ids;
  }

  /**
   * @private
   * This method updates unit options when user chooses the first unit.
   * This filters out the ones prior to the chosen unit so that last unit select box
   * contains options for the chosen unit upto the last unit.
   * @param {CourseOptionsResponseDataType} courseOptions
   * @param {Array.<number>} unitIds
   * @param {number} firstUnitId
   */
  updateUnitOptions(courseOptions, unitIds, firstUnitId) {
    const firstUnitIndex = unitIds?.indexOf(firstUnitId);
    this.store.unitOptions = courseOptions.units.slice(firstUnitIndex);
    if (!this.store.course.lastUnitId ||
      firstUnitIndex > unitIds?.indexOf(this.store.course.lastUnitId)) {
      this.store.course.lastUnitId = firstUnitId;
    }
  }
}
