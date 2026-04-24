import FormComponent from 'institution_admin/shared/form_component.js';
import { metaTagContent } from 'shared/utils.js';
import ConfirmModal from '../shared/confirm_modal.js';
import { postToEndpoint } from 'shared/ajax_utils.js';

class CourseOrSectionModal extends FormComponent {
  /* Post data for sections to endpoint. */
  postSectionData() {
    /**
     * If data are already submitted, bail.
     * This is to guard against duplicate submissions.
     */
    if (this.submitted) {
      return;
    }

    postToEndpoint(
      this.initialContext.endpoint,
      this.data,
      (data) => {
        /** navigate back to courses view to update list
         *    and see flash message re: course creation
         */
        location.reload(true);
      }
    );

    this.submitted = true;
  }

  /**
   * @summary Submit data for the course to be created.
   */
  postCourseData() {
    /**
     * If data are already submitted, bail.
     * This is to guard against duplicate submissions.
     */
    if (this.submitted) {
      return;
    }

    postToEndpoint(
      this.initialContext.endpoint,
      this.data,
      (data) => {
        /* Store the course ID to select it when view is reloaded. */
        sessionStorage.setItem('selectedCourseId', data.course_id);

        /**
         * Navigate back to courses view to update list, select course,
         * and see flash message re: course creation/update.
         */
        location.reload(true);
      }
    );

    this.submitted = true;
  };

  /* @summary Save course ID in session storage.
   * Save course ID so that it will be available on reload
   * for setting the selected state of the course.
   * @param {Event} event - the click event from the save or delete button (not used)
   */
  storeSelectedCourseId(event) {
    sessionStorage.setItem('selectedCourseId', this.model.courseId);
  }

  /**
   * @summary Update model with course name.
   * @param {Event} event - change event from the course-name input
   */
  setCourseName(event) {
    this.model.name = event.target.value;
  }

  /**
   * Updates model with course owner ID.
   * NOTE: When the course owner changes, the hide-from-instructor-dashboard
   * state also needs to change to a default of false. Otherwise, there's
   * a risk that the state will be set to true for an admin and then
   * remain true after ownership is changed to a non-admin.
   * @param {Event} event - change event from the course-owner select
   */
  setCourseOwnerID(event) {
    this.model.selectedOwnerIndex = event.target.selectedIndex;
    this.model.selectedOwnerID = event.target.value;
    this.model.hideFromDashCheckboxStatus = false;

    // if admin is owner, hide-from-dash checkbox should be visible.
    this.setVisible('js-hide-from-dash-form-item', this.adminIsOwner());
  }

  /**
   * Returns whether admin is the selected owner for the course.
   * @return {Boolean} whether admin ID matches the selected course owner ID
   */
  adminIsOwner() {
    this.userId ??= metaTagContent('VHL.user_id');
    return this.userId === this.model.selectedOwnerID;
  }

  /**
   * @summary Update model with show/hide checkbox status.
   * @param {Event} event - change event from the checkbox-status toggle
   */
  setHideFromDashCheckboxStatus(event) {
    this.model.hideFromDashCheckboxStatus = event.target.checked;
  }

  /**
   * @summary Update the course template data.
   * This is passed as a change event handler for the source-template select.
   * Most of the work is delegated to the course-template-data component,
   * which gets data based on the selected template ID.
   * @param {Event} event - change event from the source-template select
   */
  drawCourseTemplateData(event) {
    this.model.selectedTemplateIndex = event.target.selectedIndex;
    this.model.selectedTemplateID = event.target.value;

    /** Subcomponents are stored in arrays by component-class name.
     *    There is always exactly one course-template-data component, so it's
     *    referenced by the 0-index.
     */
    this.courseTemplateDataComponents[0].draw(
      { courseTemplateId: event.target.value }
    );
  };

  /* @summary Enable submit button if section data are complete.
   *
   * NOTE: in EditSectionModal, it would also be good to disable
   * the button unless data have actually changed from their original
   * state (i.e., no need to enable it if the user has changed
   * data and then reverted the changes).
   */
  toggleSubmitButton() {
    if (this.model.valid()) {
      this.getElm('fc-submit-button').removeAttribute('disabled');
      return;
    }

    this.getElm('fc-submit-button').setAttribute('disabled', '');
  }

  /**
   * @summary Submit request to delete section.
   */
  postDelete() {
    postToEndpoint(
      this.initialContext.deletionEndpoint,
      this.data,
      (data) => {
        // navigate back to courses view to update list and see flash message re: course or section deletion
        location.reload(true);
      }
    );
  }

  /**
   * @summary Confirmation message modal to courses and sections.
  */
  openConfirmDelete() {
    let confirmDeleteModalElm = this.getElm('js-confirm-modal');
    let dataForModal = this.dataForConfirmDeleteModal();
    let callback = (closeModalCallback) => {
      postToEndpoint(
        dataForModal.endpoint,
        this.data,
        closeModalCallback
      );
    };

    let modalText = {
      modalHeaderText: dataForModal.headerText,
      modalBodyText: `<p>Are you sure you want to delete <b>${ dataForModal.name }</b>?</p>
      <p>All data will be deleted. <span class="u-txt-red">This action cannot be undone.</span></p>`
    };

    //create and open confirm modal
    new ConfirmModal(confirmDeleteModalElm, callback, modalText).open();
  }
}

/**
 * Make common event-listener mappings available to subclasses.
 *
 * In both 'section' and 'course', most of the CSS-class keys are common to
 * both the 'create' and 'edit' modal. The exceptions are
 * 'js-delete-section-button' and 'js-delete-course-button', each of which
 * occurs in the 'edit' modal only. They are included here because they are
 * both mapped to the 'postDelete' callback, which is defined above, and I
 * wanted to keep the mapping in the same file as the callback definition.
 *
 * Where a subclass needs other CSS-class keys unique to it, I've used
 * Object.assign to merge them into a copy of the event-listener map.
 */
CourseOrSectionModal.elmEventListenerMap = {
  section: {
    'fc-submit-button': ['click', 'postSectionData'],
    'js-delete-section-button': ['click', 'openConfirmDelete'],
    'js-form-component--section-subform-collection': ['change', 'toggleSubmitButton'],
    'js-store-selected-course-id': ['click', 'storeSelectedCourseId']
  },
  course: {
    'fc-course-name-elm': ['change', 'setCourseName'],
    'fc-course-owner-id-elm': ['change', 'setCourseOwnerID'],
    'fc-source-template-id-elm': ['change', 'drawCourseTemplateData'],
    'fc-hide-from-dash-checkbox-status': ['change', 'setHideFromDashCheckboxStatus'],
    'fc-submit-button': ['click', 'postCourseData'],
    'js-course-form': ['change', 'toggleSubmitButton'],
    'js-delete-course-button': ['click', 'openConfirmDelete']
  }
}

export default CourseOrSectionModal;
