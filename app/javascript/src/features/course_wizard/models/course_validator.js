import { reject } from 'shared/utils';
import { CourseValidation } from './course_validation';

/** @type {import('./course_validation').Status} Status */

/**
 * @typedef errorDataType
 * @property {string} msg
 * @property {boolean} value
 */

/**
 * @typedef ErrorWithAlias
 * @property {errorDataType} result
 * @property {string} alias
 */

/**
 * This class has methods to validate course fields.
 */
export default class CourseValidator {
  /**
   * @constructor
   * @param {NewCourseDataStore} courseDataStore - New Course Data Store's reactive store
   */
  constructor(courseDataStore) {
    this.store = courseDataStore;
  }

  /**
   * checks for the type of error and returns it's corresponding message
   * @param {string} type - error type
   * @return {errorDataType} - object that contains its value and error message.
   */
  hasCourseError(type) {
    let returnObject;

    switch (type) {
    case 'name':
      returnObject = this.isNameReadonly ?
        true :
        this.hasErrorInCourseName();
      break;
    case 'endDate':
      returnObject = this.hasErrorInCourseEndDate();
      break;
    case 'date':
      returnObject = this.hasErrorInCourseDate();
      break;
    case 'total_weight':
      returnObject = this.hasErrorInCategoryWeight();
      break;
    case 'standards':
      returnObject = this.hasErrorInStandards();
      break;
    }
    return returnObject;
  }

  /**
   * @private
   * checks for error in course date and returns it's corresponding message
   * @return {errorDataType} - object that contains its value and error message.
   */
  hasErrorInCourseDate() {
    let msg = '';
    let value = false;
    if (!this.validateDates()) {
      msg = 'Your end date cannot be before your start date.';
      value = true;
    }
    return { msg, value };
  }

  /**
   * @private
   * checks for error in course end date and returns it's corresponding message
   * @return {errorDataType} - object that contains its value and error message.
   */
  hasErrorInCourseEndDate() {
    let msg = '';
    let value = false;
    if (!this.validateEndDateInFuture()) {
      msg = 'Your end date cannot be in the past.';
      value = true;
      return { msg, value };
    } else if (this.endDateIsThreeYearsOrMoreFromNow()) {
      msg = 'Your end date must not be more than 3 years from now.';
      value = true;
    }
    return { msg, value };
  }

  /**
   * @private
   * checks for error in course name and returns it's corresponding message
   * @return {errorDataType} - object that contains its value and error message.
   */
  hasErrorInCourseName() {
    let msg = '';
    let value = false;
    if (!this.store.course.name) {
      msg = 'Course name is required.';
      value = true;
    } else if (this.store.course.name.length > 75 && !this.isNameReadonly) {
      msg = 'Your course name cannot be longer than 75 characters.';
      value = true;
    }
    return { msg, value };
  }

  /**
   * @private
   * @return {errorDataType}
   */
  hasErrorInCategoryWeight() {
    const totalWeight = this.calcTotalCategoryWeight();
    const value = totalWeight !== 100;
    const msg = value ?
      'The total weight of all course categories must equal 100.  ' +
      'Please contact technical support to resolve this issue.':
      '';
    return { value, msg };
  }

  /**
   * @private
   * @return {errorDataType}
   */
  hasErrorInEnterpriseSectionClassDays() {
    let msg = '';
    let value = false;
    if (
      this.store.isEnterprise &&
      (this.store.course.classDays.length === 0 ||
      !this.store.course.classDays.some(day => day === true))
    ) {
      msg = 'Days are required.';
      value = true;
    }
    return { msg, value };
  }

  /**
   * @private
   * @return {errorDataType}
   */
  hasErrorInStandards() {
    const value = (
      !this.store.isEnterprise &&
      this.numSupportedStandardSets() > 0 &&
      this.store.course.standardSetIds.length === 0
    );
    const msg = value ? 'You must select at least one standard.': '';
    return { value, msg };
  }

  /**
   * @private
   * @return {number}
   */
  numSupportedStandardSets() {
    // If the course is slow to load, this.store.courseOptions will be undefined.
    if (typeof this.store.courseOptions !== 'undefined') {
      return this.store.courseOptions.supported_standard_sets.length;
    } else {
      return 0;
    }
  }

  /**
   * @private
   * @return {number}
   */
  calcTotalCategoryWeight() {
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
   * returns whether required fields in content step are not present.
   * @return {boolean}
   */
  isContentStepFormInvalid() {
    return !(
      this.store.course.level &&
      this.store.course.firstUnitId &&
      this.store.course.lastUnitId &&
      this.store.course.videoSubtitleLanguages &&
      this.store.course.videoTranscriptLanguages
    );
  }

  /**
   * returns whether course name or start/end dates are not valid.
   * @return {boolean}
   */
  isCourseNameOrDatesInvalid() {
    return this.hasCourseError('name').value ||
      this.hasCourseError('endDate').value ||
      this.hasErrorInEnterpriseSectionClassDays().value ||
      this.hasCourseError('date').value;
  }

  /**
   * @private
   * Validates startDate and endDate values
   * @return {boolean}
   */
  validateDates() {
    if (this.store.course.startDate === '' || this.store.course.endDate === '') {
      return false;
    }
    const startDate = new Date(this.store.course.startDate);
    const endDate = new Date(this.store.course.endDate);
    return (startDate < endDate);
  }

  /**
   * @private
   * Validates endDate is today or after.
   * @return {boolean} - true if the endDate is valid
   */
  validateEndDateInFuture() {
    if (this.store.course.endDate === '') {
      return true;
    }
    const endDate = new Date(this.store.course.endDate).setHours(0, 0, 0, 0);
    const today = new Date().setHours(0, 0, 0, 0);
    const validEnd = !(today > endDate);
    return validEnd;
  }

  /**
   * @private
   * @return {boolean} - true if endDate is 3 years from now or later
   */
  endDateIsThreeYearsOrMoreFromNow() {
    if (this.store.course.endDate === '') {
      return false;
    }
    const endDate = new Date(this.store.course.endDate).setHours(0, 0, 0, 0);
    const threeYearsFromNow = new Date();
    // If the end date is February 29th
    if (threeYearsFromNow.getMonth() === 1 && threeYearsFromNow.getDate() === 29) {
      threeYearsFromNow.setDate(28);
    }
    threeYearsFromNow.setFullYear(threeYearsFromNow.getFullYear() + 3);
    return (endDate >= threeYearsFromNow.setHours(0, 0, 0, 0));
  }

  /**
   * It returns whether the name is readonly or not.
   * @return {boolean}
   */
  get isNameReadonly() {
    return this.store.courseOptions.autorostering_linked;
  }

  /**
   * @return {boolean}
   */
  isTotalCategoryWeightInvalid() {
    return this.hasErrorInCategoryWeight().value;
  }

  /**
   * It returns true if a list of standards exists but none is selected.
   * @return {boolean}
   */
  isStandardsInvalid() {
    return this.hasErrorInStandards().value;
  }

  /**
   * @return {Array.<CourseValidation>}
   */
  get validations() {
    const validators = [
      { result: this.hasErrorInCourseName(), alias: 'course-name' },
      { result: this.hasErrorInCourseDate(), alias: 'course-start-date' },
      { result: this.hasErrorInCourseEndDate(), alias: 'course-end-date' },
      { result: this.hasErrorInCategoryWeight(), alias: 'total-category-weight' },
      { result: this.hasErrorInStandards(), alias: 'standards-count' },
    ];
    /* @type {Array.<CourseValidation>} */
    return validators.map((result) => this.mapErrorDataTypeToValidation(result));
  }

  /**
   * @param {ErrorWithAlias} errorWithAlias
   * @return {CourseValidation}
   */
  mapErrorDataTypeToValidation(errorWithAlias) {
    const status = errorWithAlias.result.value ? 'invalid' : 'valid';
    return this.buildValidation(
      errorWithAlias.alias,
      status,
      errorWithAlias.result.msg
    );
  }

  /**
   * @private
   * @param {string} alias
   * @param {Status} status
   * @param {string} description
   * @return {CourseValidation}
   */
  buildValidation(alias, status, description) {
    return new CourseValidation({
      alias,
      status,
      description,
      errorHandler: (message) => console.error(message),
    });
  }

  /**
   * Searches the validations in this instance for a matching alias, and returns
   * the first match.  If no result is found, returns undefined.
   * @param {string} alias The alias of the validation to find.
   * @return {CourseValidation | undefined}
   */
  findValidation(alias) {
    return this.validations.find((validation) => validation.alias === alias);
  }
}
