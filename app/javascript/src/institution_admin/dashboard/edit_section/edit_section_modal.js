import CourseOrSectionModal from '../shared/course_or_section_modal.js';
import ConfirmModal from '../shared/confirm_modal.js';
import { postToEndpoint } from 'shared/ajax_utils.js';

/**
 * @summary Component class for the create-course modal.
 */
class EditSectionModal extends CourseOrSectionModal {
  /**
   * @summary Configure and instantiate edit-section-modal component.
   */
  constructor(rootElm, context = {}) {
    let config = {
      elmEventListenerMap: CourseOrSectionModal.elmEventListenerMap['section'],
      context: Object.assign(
        {},
        context,
        { endpoint: `${location.origin}/institution_admin/update_section`,
          deletionEndpoint: `${location.origin}/institution_admin/delete_section` }
      )
    };

    super(rootElm, config);
  }

  /**
   * @summary Get data for the section, render the modal, and open it.
   * Called when user clicks to edit a section.
   */
  async redrawSectionSubforms() {
    await this.confirmInitialization();
    const context = {
      sections: this.model.sections,
      sectionOptions: this.model.sectionOptions
    };

    this.sectionSubformCollectionComponents[0].init(context);
    this.toggleSubmitButton();

    $(this.rootElm).vhlModal('open');
  }

  dataForConfirmDeleteModal() {
    return {
      endpoint: `${location.origin}/institution_admin/delete_section`,
      headerText: 'Delete Section',
      name: this.data.section.name
    };
  }

  /**
   * @summary Return data for section to be updated.
   */
  get data() {
    const sectionData = this.model.sections[0].data;
    return {
      section: Object.assign(
        {},
        sectionData,
        { id: this.model.sections[0].id }
      )
    };
  }
};

export default EditSectionModal;
