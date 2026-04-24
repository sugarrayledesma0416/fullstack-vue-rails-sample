import CourseFormState from './course_form_state';
import CourseSerializer from 'features/course_wizard/services/course_serializer';

/**
 * @typedef {
 *  import('features/course_wizard/models/edit_course_data_store.js').EditCourseDataStoreType
 * } EditCourseDataStoreType
 */

/**
 * This class has methods to maintain and compare course form state for Edit Course.
 */
export default class EditCourseFormState extends CourseFormState {
  /**
   * @constructor
   * @param {EditCourseDataStoreType} courseDataStore - Edit Course Data Store's reactive store
   */
  constructor(courseDataStore) {
    super(courseDataStore);
    this.courseSerializer = new CourseSerializer(this.store.course);
  }

  /**
   * @private
   * Calculare course form state based on current state in data store.
   * We compare serialized course to cover changes in form controls of all steps
   * Any change in serialized course would mean change in payload while saving.
   * @return {string} - Course form state as json string
   */
  calculateFormState() {
    const serializedCourse = this.courseSerializer.serialize();
    return JSON.stringify(serializedCourse);
  }
}
