import { reactive, toRef, watch } from 'vue';
import Category from 'features/category_wizard/models/category';
import CourseHttp from 'features/course_wizard/services/course_http';
import CourseSerializer from 'features/course_wizard/services/course_serializer';
import { reject } from 'shared/utils';
import getCourseOptions from 'features/course_wizard/services/course_options_http';
import CourseValidator from './course_validator';
import EditCourseFormState from './edit_course_form_state';
import FlashMessageState from 'shared/flash_message_state';
import DataStoreHelper from './data_store_helper';

/**
 * @typedef {import('./course_validation.js').CourseValidation} CourseValidation
 */

/**
 * @typedef {
 *  import('features/course_wizard/models/new_course_data_store.js').CourseOptionsResponseDataType
 * } CourseOptionsResponseDataType
 */

/**
 * @typedef {
 *  import('features/course_wizard/models/new_course_data_store.js').CourseDataType
 * } CourseDataType
 */

/**
 * @typedef {
 *  import('features/course_wizard/models/new_course_data_store.js').SettingsCoursesType
 * } SettingsCoursesType
 */

/**
 * @typedef {EditCourseDataStoreType}
 * @property {Course} course - course object.
 * @property {boolean} courseHasIndividualAssignments
 * @property {CourseOptionsResponseDataType} courseOptions - course info Object.
 * @property {string} errorMessage
 * @property {boolean} generatingPdf
 * @property {boolean} instAdmin
 * @property {('loading'|'success'|'error')} contentStepDataFetchState
 * @property {boolean} loadingOptions
 * @property {boolean} saving
 * @property {SettingsCoursesType} settingsCourses
 * @property {Array} unitOptions - array of unit options
 * @property {Array.<CourseValidation>} validations - Validations run against
 * this instance.
 * @property {boolean} hasFailedValidations - True if this instance has
 * validations that failed.
 */

const SUCCESS_MSG = 'Successfully saved course settings.';

/**
 * This class initializes edit course wizard app state and has methods to manipulate the app state.
 */
export default class EditCourseDataStore {
  /**
   * @constructor
   * @param {Course} course
   * @param {boolean} instAdmin
   * @param {number} programId
   * @param {number} schoolId
   * @param {string} languageCode
   */
  constructor(course, instAdmin, programId, schoolId, languageCode = null) {
    this.store = reactive(this.getDefaultsForStore(course, instAdmin));
    this.programId = programId;
    this.editCourseMode = true;
    this.courseHttp = new CourseHttp({ instAdmin, programId, schoolId });
    this.courseFormState = new EditCourseFormState(this.store);
    this.flashMessageState = new FlashMessageState();
    this.courseValidator = new CourseValidator(this.store);
    this.courseSerializer = new CourseSerializer(this.store.course);
    this.dataStoreHelper = new DataStoreHelper(this.store);
    this.languageCode = languageCode;
    this.store.course.dateSettingsCourseSource = 'course';
    this.store.course.contentSettingsCourseSource = 'course';
    this.store.course.categorySettingsCourseSource = 'course';
    this.fetchCourseOptionsAndUpdateData();
    this.fetchContentStepData();
  }

  /**
   * This returns whether Update button should be disabled
   * @return {boolean}
   */
  get isUpdateDisabled() {
    return this.store.saving ||
      this.courseValidator.isCourseNameOrDatesInvalid() ||
      this.courseValidator.isContentStepFormInvalid() ||
      this.courseValidator.isTotalCategoryWeightInvalid() ||
      this.courseValidator.isStandardsInvalid();
  }

  /**
   * This method posts updated course data to the server
   */
  async postCourseUpdate() {
    this.store.saving = true;
    try {
      const response = await this.courseHttp.update(this.store.course);
      if (response && !response.errors?.length) {
        this.store.course.removedCategories = [];
        this.store.course.categories = response.categories?.map((category) => {
          category['languageCode'] = this.languageCode;
          return new Category(category);
        }) ?? [];
        this.store.saving = false;
        this.store.flashNotice = SUCCESS_MSG;
        this.flashMessageState.displayNotice();
        window.scrollTo(0, 0);
        this.courseFormState.markClean();
      } else {
        this.store.saving = false;
        this.store.errorMessage = this.getErrorMessages(response.errors);
        this.flashMessageState.displayError();
        window.scrollTo(0, 0);
      }
    } catch (error) {
      console.log(error);
      this.store.saving = false;
    }
  }

  /**
   * This method returns combined weight for all the categories
   * except deleted categories
   * @return {number}
   */
  totalWeight() {
    const categories = reject(
      this.store.course.categories,
      (cat) => cat._destroy === true
    ) ?? [];
    return categories.reduce(function(memo, category) {
      // Undefined weights are zeroes instead.
      return memo + (category.weightingPercent || 0);
    }, 0);
  }

  /**
   * @private
   * This method converts given string to camel case.
   * @param {string} str - a key name in response from server having underscores.
   * @return {string} - key name in camel case
   */
  camelize(str) {
    return str.replace(/_/g, ' ').replace(/(?:^\w|[A-Z]|\b\w)/g, function(word, index) {
      return index === 0 ? word.toLowerCase() : word.toUpperCase();
    }).replace(/\s+/g, '');
  }

  /**
   * @private
   * Initialise store data for edit course.
   * @param {Course} course
   * @param {boolean} instAdmin
   * @return {EditCourseDataStoreType}
   */
  getDefaultsForStore(course, instAdmin) {
    return {
      contentStepDataFetchState: 'loading',
      course,
      courseHasIndividualAssignments: false,
      courseOptions: undefined,
      errorMessage: '',
      generatingPdf: false,
      instAdmin: instAdmin,
      loadingOptions: true,
      saving: false,
      settingsCourses: {
        categorySettingsCourse: undefined,
        contentSettingsCourse: undefined,
        dateSettingsCourse: undefined,
      },
      unitOptions: undefined,
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
        const newCategories = this.dataStoreHelper.getCategoriesFromSettingsData(
          fromCourse.categories, this.languageCode);
        const prevCategoryNames = this.store.course.categories?.map((item) => {
          return item.name;
        });
        this.store.course.categories?.forEach((item) => {
          item._destroy = true;
        });
        newCategories.forEach((item, index) => {
          const prevIndex = prevCategoryNames.indexOf(item.name);
          if (prevIndex >= 0) {
            const prevId = this.store.course.categories[prevIndex].id;
            newCategories[index].id = prevId;
            this.store.course.categories[prevIndex] = newCategories[index];
          } else {
            this.store.course.categories.push(newCategories[index]);
          }
        });
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
    return `The course could not be updated because of the following errors: ${errors.join(' ')}`;
  }

  /**
   * @private
   * This method fetches content step related data from the server and updates data in the store.
   */
  async fetchContentStepData() {
    try {
      const contentStepData = await this.courseHttp.getContentStepData();
      this.store.contentStepDataFetchState = 'success';
      this.store.courseHasIndividualAssignments = contentStepData.course_has_individual_assignments;
    } catch (error) {
      this.store.contentStepDataFetchState = 'error';
      console.log(error);
    }
  }

  /**
   * @private
   * This method fetches course options data from the server and updates data in the store.
   * This also adds watchers on various properties in the store.
   */
  async fetchCourseOptionsAndUpdateData() {
    const courseOptions = await getCourseOptions();
    if (this.editCourseMode === true) {
      // Filter out the current course from settings dropdown
      courseOptions.settings = courseOptions.settings.filter(
        (item) => item.id != courseOptions.course.id
      );
    }

    this.store.loadingOptions = false;
    // Used for first/last unit select box logic.
    const unitIds = courseOptions.units?.map((unit) => unit.id) ?? [];
    this.dataStoreHelper.loadSections(courseOptions);
    this.store.courseOptions = courseOptions;
    this.store.unitOptions = courseOptions.units;
    this.dataStoreHelper.addWatcherForFirstUnitId(courseOptions, unitIds);
    this.dataStoreHelper.updateCourseSettings(courseOptions);
    this.addWatchers(courseOptions, unitIds);
    this.updateCourse(courseOptions.course);

    this.store.course.categories = this.store.course.categories?.map((category) => {
      category['languageCode'] = this.languageCode;
      return new Category(category);
    }) ?? [];

    this.dataStoreHelper.updateSchoolId(courseOptions);
    this.dataStoreHelper.setLevelAndComponents(courseOptions);
    setTimeout(() => {
      this.courseFormState.markClean();
    });
  }

  /**
   * @private
   * This method update course in datastore from course data from server response.
   * This converts key name in camel case before extracting values.
   * @param {CourseDataType} courseData - course information from server
   */
  updateCourse(courseData) {
    const keysInData = Object.keys(courseData);
    const formattedCourseData = {};
    keysInData?.forEach((key) => {
      formattedCourseData[this.camelize(key)] = courseData[key];
    });
    Object.assign(this.store.course, formattedCourseData);
  }

  /**
   * Exposes validations run by the course validator.
   * @return {Array.<CourseValidation>}
   */
  get validations() {
    return this.courseValidator.validations;
  }

  /**
   * @return {boolean} True if the store has validations that did not pass.
   */
  get hasFailedValidations() {
    const invalids = this.validations.map((validation) => validation.status === 'invalid');
    return invalids.length && !this.store.loadingOptions ? true : false;
  }
}
