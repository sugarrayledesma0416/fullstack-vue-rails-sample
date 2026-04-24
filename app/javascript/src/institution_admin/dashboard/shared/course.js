/**
 * @summary Model class for the create-course modal.
 */
class Course {
  /**
   * @summary Instantiate and initialize model.
   */
  constructor(courseData = {}) {
    if (Object.keys(courseData).length === 0) {
      this.reset();
    } else {
      this.courseId = courseData.courseId;
      this.hasSections = courseData.sectionCount > 0;
      this.name = courseData.courseName;
      this.selectedOwnerID = courseData.courseOwnerId;
      this.selectedOwnerIndex = courseData.selectedOwnerIndex;
      this.hideFromDashCheckboxStatus = courseData.hideFromDashCheckboxStatus;
      this.selectedTemplateID = courseData.sourceTemplateId;
      this.selectedTemplateIndex = courseData.selectedTemplateIndex;
    }
  }

  /**
   * @summary Reset to initial values.
   */
  reset() {
    this.name = '';
    this.selectedOwnerID = '';
    this.selectedOwnerIndex = 0;
    this.hideFromDashCheckboxStatus = false;
    this.selectedTemplateID = '';
    this.selectedTemplateIndex = '';
  }

  /**
   * @summary Return whether course is in valid state.
   * Array of functions, combined with `every()`, acts as a series of guard
   *   clauses.
   * @returns {Boolean} true if all validations pass, false otherwise
   */
  valid() {
    return [
      () => { return this.name !== ''; },
      () => { return this.selectedTemplateID !== ''; },
      () => { return this.selectedOwnerID !== ''; }
    ].every(func => func());
  }

  /**
   * @summary Return data for the course.
   */
  get data() {
    return {
      course_id: this.courseId,
      owner_id: this.selectedOwnerID,
      name: this.name,
      source_template_id: this.selectedTemplateID,
      hide_from_dash_checkbox_status: this.hideFromDashCheckboxStatus
    };
  }
}

export default Course;
