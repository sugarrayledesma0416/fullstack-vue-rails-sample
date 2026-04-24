import FormComponent from 'institution_admin/shared/form_component.js';

/**
 * @summary Component class for the confirm modal.
 */
class ConfirmModal extends FormComponent {
  /**
   * @summary Configure and instantiate confirm-modal component.
   * @param {HTMLElement} rootElm - the root element of the modal
   * @param {Function} callback - function to be called on confirm
   * @param {String} modalText - the text to be displayed in the modal
   */
  constructor(rootElm, callback, modalText = { modalHeaderText: '', modalBodyText: '' }) {
    let config = {
      context: {
        callback: callback,
        modalText: modalText
      },
      elmEventListenerMap: {
        'js-confirm': ['click', 'runCallback']
      },
    };

    super(rootElm, config);
  }

  /**
   * @summary Open.
   */
  open() {
    this.getElm('modal-header-text').innerHTML = this.initialContext.modalText.modalHeaderText;
    this.getElm('modal-body-text').innerHTML = this.initialContext.modalText.modalBodyText;
    $(this.rootElm).vhlModal('open');
  }

  runCallback() {
    let rootElm = this.rootElm;
    let closeModalCallback = () => {
      $(rootElm).vhlModal('close');
      location.reload();
    };

    /** NOTE: the callback passed into the constructor should accept a single
     *        parameter - the callback to close the modal - and call it when
     *        it is done with its work.
     */
    this.initialContext.callback(closeModalCallback);
  }
}

export default ConfirmModal;
