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
 * This class has methods to maintain and compare course form state.
 */
export default class CourseFormState {
  /**
   * @constructor
   * @param {NewCourseDataStoreType|EditCourseDataStoreType} courseDataStore - Course Data Store's
   * reactive store
   */
  constructor(courseDataStore) {
    this.store = courseDataStore;
    this.initialFormState = '';
  }

  /**
   * Get whether form state has changed from initial value
   * @return {boolean} - Whether form changed
   */
  get isChanged() {
    if (this.initialFormState !== this.calculateFormState()) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * Set initialFormState to current form state value.
   */
  markClean() {
    this.initialFormState = this.calculateFormState();
  }

  /**
   * @private
   * Calculare course form state based on current state in data store.
   * Dates are set without timestamp values
   * @return {string} - Course form state as json string
   */
  calculateFormState() {
    const courseInputs = {
      endDate: this.store.course.endDate,
      name: this.store.course.name,
      numSections: this.store.numSections?.chosen,
      sections: this.store.course.sections,
      startDate: this.store.course.startDate,
    };
    return JSON.stringify(courseInputs);
  }
}
