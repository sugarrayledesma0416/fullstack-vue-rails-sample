import * as ajaxUtils from 'shared/ajax_utils';
import { omit, reduceObject } from 'shared/utils';
import CalendarProcessor from 'features/learning_tracks/models/calendar_processor';
import CourseSerializer from './course_serializer.js';

/**
 * @typeDef {CourseHttpOptions}
 * @property {boolean} instAdmin - whether current user is institute admin.
 * @property {programId} programId - Id of the program.
 * @property {schoolId} schoolId - Id of the school.
 */

/**
 * @typedef {
 *  import('features/course_wizard/services/course_serializer.js').CourseObject
 * } CourseObject
 */

/**
 * @typedef {
 *  import('features/course_wizard/services/course_serializer.js').CategoryObject
 * } CategoryObject
 */

/**
 * @typedef {
 *  import('features/assignment_wizard/models/assignment_wizard_init_data.js').CalendarObjType
 * } CalendarObjType
 */

/** Class representing CourseHTTP */
class CourseHttp {
  /**
   * Set up the configutation required for initializing CourseHttp.
   * @constructor
   * @param {CourseHttpOptions} options
   */
  constructor(options) {
    this.instAdmin = options.instAdmin;
    this.programId = options.programId;
    this.schoolId = options.schoolId;
  }

  /**
   * Creates a new express course
   * @param {CourseObject} course - course object
   * @param {CalendarObjType} calendar - calendar object
   * @return {Promise} promise for express course creation.
   */
  expressCreate(course, calendar) {
    const courseSerializer = new CourseSerializer(course);
    const courseData = courseSerializer.serialize();
    /* If there are only external assignments, the calendar.calendar will be undefined.
     * Assign empty objects to assignments and categories keys.
     */
    const assignmentData = {
      assignments: calendar.calendar ? CalendarProcessor.stripCalendar(calendar.calendar) : {},
      course_package_ids: calendar.coursePackageIds,
      categories: calendar.calendar ? this.cleanCategories(calendar.categories) : {},
      copy_igc: calendar.copyIgc,
      src_section_id: calendar.srcSectionId,
    };
    const payload = Object.assign({}, courseData, assignmentData);

    return new Promise((resolve) => {
      ajaxUtils.postToEndpoint(
        `${this.baseUrl}/express_create.json`,
        payload,
        (response) => {
          resolve(response);
        }
      );
    });
  }

  /**
   * Deletes a course.
   * @param {CourseObject} course - course object
   * @return {Promise} promise for course delete.
   */
  destroy(course) {
    return ajaxUtils.deleteFromEndpoint(
      `${this.baseUrl}/${course.id}`,
      (data) => {
        this.returnToDashboard();
      }
    );
  }

  /**
   * Get Content Step related information from the server for edit course use case.
   * @return {Promise} - promise which resolves to Content Step data.
   */
  getContentStepData() {
    const url = location.href.replace(/edit#.*/, '') + 'content_step.json';

    return new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        url,
        (data) => {
          resolve(data);
        }
      );
    });
  }

  /**
   * Redirects to Section Wizard.
   * @param {CourseObject} course - course object
   */
  gotoSectionWizard(course) {
    const url = this.instAdmin ?
      `/institution_admin/${this.programId}/school/${this.schoolId}/courses/${course.id}/sections/new` :
      `/instructor/${this.programId}/courses/${course.id}/sections/new`;

    window.location.replace(url);
  }

  /**
   * Redirects to the institute admin/ instructor dashboard.
   * @param {CourseObject} course - course object
   */
  returnToDashboard(course) {
    let url;
    if (this.instAdmin) {
      url = `/institution_admin/templates/${this.programId}?school_id=${this.schoolId}`;
      if (course) {
        url += `&template_id=${course.id}`;
      }
    } else {
      url = `/instructor/dashboard/${this.programId}`;
    }
    window.location.replace(url);
  }

  /**
   * Creates a new course (not express).
   * @param {CourseObject} course - course object
   * @return {Promise} promise for course create.
   */
  save(course) {
    const courseSerializer = new CourseSerializer(course);
    const courseData = courseSerializer.serialize();
    return new Promise((resolve, reject) => {
      ajaxUtils.postToEndpoint(
        `${this.baseUrl}.json`,
        courseData,
        (response) => {
          // Check for the course ID in the response to determine success.
          // The server returns the created course object on success.
          if (response.id) {
            resolve(response);
          } else {
            reject(response);
          }
        },
        (error) => {
          reject(error);
        }
      );
    });
  }

  /**
   * Updates a course.
   * @param {CourseObject} course - course object
   * @return {Promise} promise for course update.
   */
  update(course) {
    const courseSerializer = new CourseSerializer(this.prepCourseForUpdate(course));
    const data = courseSerializer.serialize();
    return new Promise((resolve) => {
      ajaxUtils.putToEndpoint(
        `${this.baseUrl}/${course.id}.json`,
        data,
        (response) => {
          resolve(response);
        }
      );
    });
  }

  /**
   * @private
   * Sets the base url for institute admin and instructor
   * @return {string} base url
   */
  get baseUrl() {
    const baseUrl = this.instAdmin ?
      `/institution_admin/${this.programId}/school/${this.schoolId}/course_templates` :
      `/instructor/${this.programId}/courses`;
    return baseUrl;
  }

  /**
   * @private
   * Removing errors and if from categories.
   * errors, and id should not be passed to the
   * endpoint. If they are, errors  will cause
   * a mass assignment error. id will cause
   * ActiveRecord to assume that the category
   * already exists.
   * @param {Object<string, CategoryObject>} categories - object with keys as
   * category names and values as category infomation
   * @return {Array.<CategoryObject>} - array of categories
   */
  cleanCategories(categories) {
    return reduceObject(categories, {}, (memo, category, name) => {
      memo[name] = omit(['errors', 'id'], category);
      return memo;
    });
  }

  /**
   * @private
   * Prepare params for update.
   * @param {CourseObject} course - course object
   * @return {CourseObject} course object
   */
  prepCourseForUpdate(course) {
    if (course.removedCategories?.length > 0) {
      const data = { ...course };
      data.categories = data.categories.concat(data.removedCategories);
      return data;
    }

    return course;
  }
}

export default CourseHttp;
