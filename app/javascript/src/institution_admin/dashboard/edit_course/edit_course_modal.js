import Course from '../shared/course.js';
import CourseOrSectionModal from '../shared/course_or_section_modal.js';
import ConfirmModal from '../shared/confirm_modal.js';
import { postToEndpoint } from 'shared/ajax_utils.js';

/**
 * @summary Component class for the create-course modal.
 */
class EditCourseModal extends CourseOrSectionModal {
  /**
   * @summary Configure and instantiate edit-course-modal component.
   * The event listener map configures the component to
   * 1. update course-template data, on changing the course-template selection
   * 2. post data for the course to be created, on clicking "submit"
   */
  constructor(rootElm, courseData) {
    const templateOptions = rootElm.querySelector('.fc-source-template-id-elm').options;
    const selectedTemplateIndex = [...templateOptions].findIndex((item) => {
      return item.value == courseData.sourceTemplateId;
    });

    const ownerOptions = rootElm.querySelector('.fc-course-owner-id-elm').options;
    const selectedOwnerIndex = [...ownerOptions].findIndex((item) => {
      return item.value == courseData.courseOwnerId;
    });

    let config = {
      elmEventListenerMap: CourseOrSectionModal.elmEventListenerMap['course'],
      context: {
        endpoint: `${location.origin}/institution_admin/update_course`,
        deletionEndpoint: `${location.origin}/institution_admin/delete_course`,
        /**
         * TODO: Course needs to be instantiated with current data for course.
         *       That means also that course constructor needs to accept params.
         */
        model: new Course(
          Object.assign(
            {},
            courseData,
            { selectedTemplateIndex: selectedTemplateIndex,
              selectedOwnerIndex: selectedOwnerIndex }
          )
        )
      }
    };

    super(rootElm, config);
  }

  /**
   * @summary Open the modal.
   * Called when user clicks "Edit course".
   */
  async open() {
    this.getElm('fc-course-owner-id-elm').selectedIndex = this.model.selectedOwnerIndex;
    this.getElm('fc-course-name-elm').value = this.model.name;
    this.getElm('fc-hide-from-dash-checkbox-status').checked = this.model.hideFromDashCheckboxStatus === 'true';
    this.setVisible('js-hide-from-dash-form-item', this.adminIsOwner());
    this.getElm('fc-source-template-id-elm').selectedIndex = this.model.selectedTemplateIndex;
    await this.confirmInitialization();

    // The course-template-data component makes an AJAX request;
    // wait for the draw() to resolve before opening the modal
    // to avoid screen flicker from erasing previous content.
    await this.courseTemplateDataComponents[0].draw(
      { courseTemplateId: this.model.selectedTemplateID }
    );

    this.toggleSourceTemplateSelect();
    this.toggleDeleteButton();
    this.toggleSubmitButton();
    $(this.rootElm).vhlModal('open');
  }

  dataForConfirmDeleteModal() {
    return {
      endpoint: `${location.origin}/institution_admin/delete_course`,
      headerText: 'Delete Course',
      name: this.data.name
    };
  }

  toggleSourceTemplateSelect() {
    if (this.model.hasSections) {
      this.getElm('fc-source-template-id-elm').setAttribute('disabled', '');
      return;
    }

    this.getElm('fc-source-template-id-elm').removeAttribute('disabled');
  }

  /* @summary Disable "Delete" button if there are sections. */
  toggleDeleteButton() {
    if (this.model.hasSections) {
      this.getElm('js-delete-course-button').setAttribute('disabled', '');
      return;
    }

    this.getElm('js-delete-course-button').removeAttribute('disabled');
  }

  /**
   * @summary Return data to be submitted.
   * @returns {Object} data for the course to be created
   */
  get data() {
    return this.model.data;
  }
};

export default EditCourseModal;
