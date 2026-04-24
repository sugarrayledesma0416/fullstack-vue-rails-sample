import FormComponent from 'institution_admin/shared/form_component.js';
import ExternalItemModal from './external_item_modal.js';

class ExternalItemTemplatesComponent extends FormComponent {
  constructor(rootElm, context) {
    let config = {
      elmEventListenerMap: {
        'js-add-external-item': ['click', 'showAddExternalItemModal'],
        'js-edit-external-item': ['click', 'showEditExternalItemModal']
      },
      context: context
    };

    super(rootElm, config);
  }

  /**
   * @summary Open modal for adding external item.
   * NOTE: the add- and edit-item modals are both instances of
   * ExternalItemModal and take the same element as rootElm.
   * The mode value passed in via the context customizes the
   * behavior and display of the modal.
   */
  showAddExternalItemModal() {
    let modalElm = this.getElm('js-external-item-modal');
    let context = {
      mode: 'add',
      sectionId: this.initialContext.sectionId
    };
    new ExternalItemModal(modalElm, context).open();
  }

  /**
   * @summary Open modal for editing external item.
   * Unlike `showAddExternalItemModal`, this method accepts an event
   * argument so that it can get access to the dataset of the clicked element,
   * which contains the current state of the external item that is to be edited.
   * It initializes the form fields with this state.
   * @param {Event} event - the click event that caused the method call
   */
  showEditExternalItemModal(event) {
    event.preventDefault();
    const dataset = event.currentTarget.dataset;

    let modalElm = this.getElm('js-external-item-modal');
    let context = {
      mode: 'edit',
      externalActivityId: event.currentTarget.dataset.externalActivityId,
      sectionId: this.initialContext.sectionId,
      initialFormValues: {
        categoryId: dataset.categoryId,
        dueDate: dataset.dueDate,
        lessonId: dataset.lessonId,
        title: dataset.title,
        pointsPossible: dataset.pointsPossible
      }
    };

    new ExternalItemModal(modalElm, context).open();
  }
}

export default ExternalItemTemplatesComponent;
