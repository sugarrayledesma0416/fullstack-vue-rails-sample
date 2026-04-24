import Course from '../shared/course.js';
import CourseOrSectionModal from '../shared/course_or_section_modal.js';

/**
 * @summary Component class for the create-course modal.
 */
class CreateCourseModal extends CourseOrSectionModal {
  /**
   * @summary Configure and instantiate create-course-modal component.
   * The event listener map configures the component to
   * 1. update course-template data, on changing the course-template selection
   * 2. post data for the course to be created, on clicking "submit"
   */
  constructor(rootElm) {
    let config = {
      elmEventListenerMap: CourseOrSectionModal.elmEventListenerMap['course'],
      context: {
        endpoint: `${location.origin}/institution_admin/create_course`,
        model: new Course()
      }
    };

    super(rootElm, config);
  }

  /**
   * @summary Reset the modal to its initial state and open it.
   * Called when user clicks "Create course".
   */
  open() {
    this.model.reset();
    this.getElm('fc-course-owner-id-elm').selectedIndex = this.model.selectedOwnerIndex;
    this.getElm('fc-course-name-elm').value = this.model.name;
    this.getElm('fc-hide-from-dash-checkbox-status').checked = this.model.hideFromDashCheckboxStatus;
    this.getElm('fc-source-template-id-elm').selectedIndex = this.model.selectedTemplateIndex;
    this.courseTemplateDataComponents[0].erase();

    this.toggleSubmitButton();
    $(this.rootElm).vhlModal('open');
  }

  /**
   * @summary Return data to be submitted.
   * @returns {Object} data for the course to be created
   */
  get data() {
    return this.model.data;
  }
};

export default CreateCourseModal;
