import { reactive, toRef, watch } from 'vue';
import CourseHttp from 'features/course_wizard/services/course_http';
import CourseSerializer from 'features/course_wizard/services/course_serializer';
import { firstInArray, lastInArray } from 'shared/utils';
import getCourseOptions from 'features/course_wizard/services/course_options_http';
import UnitRange from 'features/learning_tracks/models/unit_range';
import CourseValidator from './course_validator';
import CourseFormState from './course_form_state';
import { getDefaultDaysOfWeek } from 'features/learning_tracks/models/common_data';
import FlashMessageState from 'shared/flash_message_state';
import DataStoreHelper from './data_store_helper';

/**
 * @typedef {import('features/learning_tracks/models/due_date_updater.js').DueDateType} DueDateType
 */

/**
 * @typedef {
 *  import('features/assignment_wizard/models/assignment_wizard.js').DayOfWeekObject
 * } DayOfWeekObject
 */

/**
 * @typedef {
  *  import('features/assignment_wizard/models/assignment_wizard.js').SectionSourceObject
  * } SectionSourceObject
  */

/**
 * @typedef {
 *  import('features/assignment_wizard/models/assignment_wizard_init_data.js').LearningTrackType
 * } LearningTrackType
 */

/**
 * @typeDef ComponentInResponseDataType
 * @property {number} id
 * @property {string} name
 */

/**
 * @typeDef {NewCourseDataStoreType}
 * @property {Array.<DueDateType>} allDueDates
 * @property {Object} calendar - calendar object.
 * @property {Course} course - course object.
 * @property {CourseOptionsResponseDataType} courseOptions - course info Object.
 * @property {Array.<DayOfWeekObject>} daysOfWeek
 * @property {boolean} disableAllControls
 * @property {string} errorMessage
 * @property {boolean} includeInstructorGradedActivities
 * @property {boolean} includeMicrophoneActivities
 * @property {boolean} includePartnerActivities
 * @property {boolean} instAdmin
 * @property {LearningTrackType} learningTrack - learning track object
 * @property {LearningTracksConfigType} learningTracksConfig - configuration for learning tracks.
 * @property {boolean} loadingLearningTracks
 * @property {boolean} loadingOptions
 * @property {Object} numSections
 * @property {boolean} respectDueDates
 * @property {boolean} saving
 * @property {boolean} sectionHasAssignments
 * @property {SectionSourceObject} sectionSource
 * @property {String} selectedTrackName
 * @property {SettingsCoursesType} settingsCourses
 * @property {Object} setupDescriptions
 * @property {Array} strands - array of strands
 * @property {Array} unitOptions - array of unit options
 * @property {UnitRange} unitRange
 * @property {boolean} usingPredefinedTrack - whether to use predefined tracks
 */

/**
 * @typedef {
 *  import('features/category_wizard/models/category.js').CategoryArgsObject
 * } CategoryArgsObject
 */

/**
 * @typeDef CourseOptionsResponseDataType
 * @property {Array.<Object>} units
 * @property {Array.<Object>} levels
 * @property {Array.<ComponentInResponseDataType>} components
 * @property {Array.<ContentSettingsCourseDataType>} settings
 * @property {Object} video_languages
 * @property {Object} setup_descriptions
 * @property {Object} program
 * @property {CourseDataType} course
 * @property {Array.<Object>} schools
 * @property {Array.<Object>} previous_courses
 * @property {Array.<CoursePackageDataType>} available_course_packages
 * @property {number} selected_school_id
 * @property {boolean} has_one_roster_academic_session
 * @property {boolean} one_roster_linked
 * @property {boolean} autorostering_linked
 * @property {Array.<ContentSettingsCourseDataType>} template_settings
 * @property {Array.<Object>} previous_course_templates
 */

/**
 * @typeDef ContentSettingsCourseDataType
 * @property {boolean} allow_audio_transcripts
 * @property {string} allow_individual_assign
 * @property {boolean} allow_video_popup_translation
 * @property {boolean} allows_help_requests
 * @property {boolean} allows_review_requests
 * @property {Array.<CategoryArgsObject>} categories
 * @property {string} chat_level
 * @property {Array.<ComponentInResponseDataType>} components
 * @property {string} end_date
 * @property {number} first_unit_id
 * @property {number} id
 * @property {boolean} is_template
 * @property {number} last_unit_id
 * @property {number} level
 * @property {string} name
 * @property {number} school_id
 * @property {Array} sections
 * @property {boolean} share_to_google_classroom
 * @property {boolean} show_estimated_times
 * @property {string} start_date
 * @property {string} video_subtitle_languages
 * @property {string} video_transcript_languages
 */

/**
 * @typeDef CourseDataType
 * @property {boolean} allow_audio_transcripts
 * @property {string} allow_individual_assign
 * @property {boolean} allow_video_popup_translation
 * @property {boolean} allows_help_requests
 * @property {boolean} allows_review_requests
 * @property {Array.<CategoryArgsObject>} categories
 * @property {string} chat_level
 * @property {Array.<ComponentInResponseDataType>} components
 * @property {string} end_date
 * @property {number} first_unit_id
 * @property {number} id
 * @property {boolean} is_template
 * @property {number} last_unit_id
 * @property {number} level
 * @property {string} name
 * @property {number} school_id
 * @property {Array} sections
 * @property {boolean} share_to_google_classroom
 * @property {boolean} show_estimated_times
 * @property {string} start_date
 * @property {string} video_subtitle_languages
 * @property {string} video_transcript_languages
 */

/**
 * @typeDef LearningTracksConfigType
 * @property {boolean} chooseTrack
 * @property {string} end_date
 * @property {Array.<Object>} previous_courses
 * @property {string} previous_course_templates
 * @property {string} start_date
 * @property {string} unit_label
 * @property {Array.<Object>} units
 */

/**
 * @typeDef SettingsCoursesType
 * @property {Object} categorySettingsCourse
 * @property {Object} contentSettingsCourse
 * @property {Object} dateSettingsCourse
 */

/**
 * @typeDef CoursePackageDataType
 * @property {string} content_type
 * @property {number} id
 * @property {Array.<Object>} license_groups
 * @property {string} name
 * @property {number} program_id
 * @property {number} rank
 */

/**
 * @typeDef errorDataType
 * @property {string} msg
 * @property {boolean} value
 */

/**
 * This class initializes new course wizard app state and has methods to manipulate the app state.
 */
export default class NewCourseDataStore {
  /**
   * @constructor
   * @param {Course} course
   * @param {boolean} instAdmin
   * @param {boolean} isEnterprise
   * @param {number} programId
   * @param {number} schoolId
   * @param {string} [languageCode]
   */
  constructor(course, instAdmin, isEnterprise, programId, schoolId, languageCode = null) {
    this.store = reactive(this.getDefaultsForStore(course, instAdmin));
    this.programId = programId;
    this.confirmOptions = {},
    this.newCourseMode = true;
    this.courseHttp = new CourseHttp({ instAdmin, programId, schoolId });
    this.courseFormState = new CourseFormState(this.store);
    this.flashMessageState = new FlashMessageState();
    this.languageCode = languageCode;
    this.store.isEnterprise = isEnterprise;
    this.store.course.isTemplate = instAdmin;
    this.store.course.dateSettingsCourseSource = 'course';
    this.store.course.contentSettingsCourseSource = 'course';
    this.store.course.categorySettingsCourseSource = 'course';
    this.store.course.allowIndividualAssign = true;
    this.store.course.enableVocabTutorialTranslations = false;
    this.store.courseNameValidator = false;
    this.courseValidator = new CourseValidator(this.store);
    this.courseSerializer = new CourseSerializer(this.store.course);
    this.dataStoreHelper = new DataStoreHelper(this.store);
    this.fetchCourseOptionsAndUpdateData();
  }

  /**
   * Navigate to dashboard
   */
  returnToDashboard() {
    this.courseHttp.returnToDashboard();
  }

  /**
   * This method posts course data to the server
   */
  async save() {
    this.store.saving = true;
    try {
      this.store.saveCourseResponse = await this.courseHttp.save(this.store.course);
      if (this.store.saveCourseResponse) {
        this.store.saving = false;
        this.store.courseSaved = true;
        if (this.store.isEnterprise) {
          await this.courseHttp.gotoSectionWizard(this.store.saveCourseResponse);
        }
      }
    } catch (error) {
      this.store.saving = false;
      this.store.errorMessage = this.handleError(error);
      this.flashMessageState.displayError();
    }
  }

  /**
   * This method handles the different types of response that server could have
   */
  handleError(error) {
    const errorHandlers = {
      array: (errors) => `The course could not be created because of the following errors: ${errors.join(' ')}`,
      string: (errors) => `The course could not be created because of the following error: ${errors}`,
      default: () => 'An unknown error occurred while saving the course.',
    };

    if (error.errors) {
      const errorType = Array.isArray(error.errors)
        ? 'array'
        : typeof error.errors === 'string'
        ? 'string'
        : 'default';
      return errorHandlers[errorType](error.errors);
    }
    return error.message || errorHandlers.default();
  }

  /**
   * Sets pathType in the course and navigate to next step
   * @param {string} type - path type
   */
  setPathAndGo(type) {
    this.store.course.pathType = type;
  }

  /**
   * @private
   * Initialize store data for new course for learning tracks.
   *
   * For reference, following properties were not present in angular implementation of
   * course-wizard but included here because learning tracks module expects them in parentModel.
   * allDueDates
   * daysOfWeek
   * learningTrack
   * loadingLearningTracks
   * respectDueDates
   * sectionHasAssignments
   * unitRange
   *
   * This is because in earlier angular code $scope is shared so while porting code, we had to
   * move any commonly used property (between learning tracks and assignment wizard)
   * out of learning tracks module and define it in parent model so that both can share it.
   */
  get getDefaultsForStoreForLearningTracks() {
    return {
      allDueDates: undefined,
      calendar: undefined,
      daysOfWeek: getDefaultDaysOfWeek(),
      disableAllControls: undefined,
      includeInstructorGradedActivities: true,
      includeMicrophoneActivities: true,
      includePartnerActivities: true,
      learningTrack: undefined,
      learningTracksConfig: {},
      loadingLearningTracks: true,
      respectDueDates: false,
      sectionHasAssignments: false,
      selectedTrackName: '',
      strands: undefined,
      unitRange: new UnitRange(undefined, undefined, []),
      usingPredefinedTrack: false,
    };
  }

  /**
   * @private
   * Initialise store data for new course.
   * @param {Course} course
   * @param {boolean} instAdmin
   * @return {NewCourseDataStoreType}
   */
  getDefaultsForStore(course, instAdmin) {
    const defaultsForStore = {
      course,
      courseOptions: undefined,
      errorMessage: '',
      generatingPdf: false,
      instAdmin: instAdmin,
      isEnterprise: false,
      loadingOptions: true,
      numSections: { chosen: 1 },
      saving: false,
      sectionSource: { type: 'section' },
      settingsCourses: {
        categorySettingsCourse: undefined,
        contentSettingsCourse: undefined,
        dateSettingsCourse: undefined,
      },
      setupDescriptions: undefined,
      unitOptions: undefined,
    };
    return {
      ...defaultsForStore,
      ...this.getDefaultsForStoreForLearningTracks,
    };
  }

  /**
   * @private
   * Adds watcher on categorySettingsCourse
   */
  addWatcherForCategorySettingsCourse() {
    const categorySettingsCourseRef = toRef(this.store.settingsCourses, 'categorySettingsCourse');
    watch(categorySettingsCourseRef, (fromCourse) => {
      if (fromCourse) {
        this.store.course.categories = this.dataStoreHelper.getCategoriesFromSettingsData(
          fromCourse.categories, this.languageCode);
      }
    });
  }

  /**
   * @private
   * Adds watcher on dateSettingsCourse
   */
  addWatcherForDateSettingsCourse() {
    const dateSettingsCourseRef = toRef(this.store.settingsCourses, 'dateSettingsCourse');
    watch(dateSettingsCourseRef, (fromCourse) => {
      if (fromCourse) {
        this.store.course.startDate = fromCourse.start_date;
        this.store.course.endDate = fromCourse.end_date;
      }
    });
  }

  /**
   * @private
   * Adds watcher
   * @param {CourseOptionsResponseDataType} courseOptions
   * @param {Array.<number>} unitIds
   */
  addWatchers(courseOptions, unitIds) {
    this.addWatcherForDateSettingsCourse();
    this.addWatcherForCategorySettingsCourse();
    this.dataStoreHelper.addWatcherForContentSettingsCourse(courseOptions);
    this.dataStoreHelper.addWatcherForFirstUnitId(courseOptions, unitIds);
  }

  /**
   * @private
   * Returns string informing about errors
   * @param {Array.<string>} errors - Array of error messages
   * @return {string}
   */
  getErrorMessages(errors) {
    return `The course could not be created because of the following errors: ${errors.join(' ')}`;
  }

  get isUpdateDisabled() {
    return this.store.saving || this.courseValidator.isStandardsInvalid();
  }

  /**
   * Exposes validations run by the course validator.
   * @return {Array.<CourseValidation>}
   */
  get validations() {
    return this.courseValidator.validations;
  }

  /**
   * @private
   * This method fetches course options data from the server and updates data in the store.
   * This also adds watchers on various properties in the store.
   */
  async fetchCourseOptionsAndUpdateData() {
    const courseOptions = await getCourseOptions();
    this.store.loadingOptions = false;
    // Used for first/last unit select box logic.
    const unitIds = courseOptions.units?.map((unit) => unit.id) ?? [];
    if (!this.store.isEnterprise) {
      this.dataStoreHelper.loadSections(courseOptions);
    }
    this.store.courseOptions = courseOptions;
    this.store.setupDescriptions = courseOptions.setup_descriptions;
    this.store.unitOptions = courseOptions.units;
    this.store.course.firstUnitId = firstInArray(unitIds);
    this.store.course.lastUnitId = lastInArray(unitIds);
    this.store.course.schoolId = courseOptions.schools ? courseOptions.schools[0].id : 0;
    this.store.course.courseLibraryFrom = null;
    this.store.course.ltiRosterLinked = courseOptions.lti_roster_linked;
    this.store.course.oneRosterLinked = courseOptions.one_roster_linked;

    if (this.store.isEnterprise) {
      const videoLanguages = this.store.courseOptions.video_languages;
      const defaultLangKey = Object.keys(videoLanguages)[0];
      const defaultLang = this.store.courseOptions.video_languages[defaultLangKey];

      this.store.course.videoSubtitleLanguages = defaultLang;
      this.store.course.videoTranscriptLanguages = defaultLang;

      this.store.course.canShareToPortfolio = courseOptions.course.can_share_to_portfolio;
    }

    this.dataStoreHelper.updateSchoolId(courseOptions);
    this.addWatchers(courseOptions, unitIds);
    this.dataStoreHelper.updateCourseSettings(courseOptions);
    // Added timeout so that initial data is set due to watchers, before marking formstate clean
    setTimeout(() => {
      this.courseFormState.markClean();
    });
  }
}
