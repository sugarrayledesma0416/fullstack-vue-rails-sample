import HelpableElement from './common/helpable_element';
import HelpRequestOverlay from './common/help_request_overlay';
import {
  clearForReview, setRequestModeBodyClass, updateSaveSubmit, enableVtextLink,
} from './common/utils.js';
import { dispatchCustomEvent } from 'shared/utils';

/**
 * Class that handles the actions of Student Help Request.
 */
class StudentRequest {
  /**
   * Instantiate the Student Request class.
   * @param {Object} requestRules
   */
  constructor(requestRules) {
    this.setAskInstructorLinkVisibility(true);
    this.setHelpNavMenuItemsVisibility(true);
    this.requestMode = 'default';
    this.userMode = 'student';
    this.requestRules = requestRules;
    this.activityFormData = '';

    // Bind the resize handler to the current context
    this.onResizeRequestModeHandler = this.onResizeRequestModeHandler.bind(this);
  }

  /**
   * Activate the Request with different modes.
   * @param {String} requestMode
   */
  activateRequestMode(requestMode) {
    this.requestMode = requestMode;
    if (['report_technical_problem', 'report_content_problem'].includes(this.requestMode)) {
      this.setAskInstructorLinkVisibility(true);
      this.setHelpNavMenuItemsVisibility(false);
    } else {
      this.setAskInstructorLinkVisibility(false);
      this.setHelpNavMenuItemsVisibility(true);
    }

    clearForReview();
    setRequestModeBodyClass(this.requestMode);
    updateSaveSubmit(this.requestMode);
    this.activityFormData = this.serializeActivityForm();

    if (this.requestMode === 'report_technical_problem') {
      this.showCommentsDialog(this.requestMode, this.activityFormData);
    } else {
      this.openFlashBanner();
      HelpRequestOverlay.init();
      // Sends a message to the helpable-type scopes
      this.dispatchHighlightEvt();
      HelpRequestOverlay.createCancelBtnProxy(
        this, document.querySelector('.js-help-request-cancel')
      );
      HelpRequestOverlay.addAccessibility(this);
    }
  }

  /**
   * This method serializes activity_form's data
   * For reference - this method replaces $('#activity_form').serialize();
   * @return {String} - Serialized string
   */
  serializeActivityForm() {
    const formElm = document.querySelector('#activity_form');
    // URLSearchParams returns in the format of "key1=value1&key2=value2&..." with encoded values
    if (formElm) {
      return new URLSearchParams(new FormData(formElm)).toString();
    }
  }

  /**
   * This method triggers event 'helpable_was_chosen' to open the add help request dialog
   * @param {String} requestMode
   * @param {String} activityFormData - Serialized activity form data
   * @param {String} helpableItemId
   * @param {String} helpableItemType
   */
  showCommentsDialog(requestMode, activityFormData, helpableItemId, helpableItemType) {
    dispatchCustomEvent({
      name: 'helpable_was_chosen',
      detail: { requestMode, activityFormData, helpableItemId, helpableItemType },
    });
  }

  /**
   * Calls function that display Elements
   */
  dispatchHighlightEvt() {
    document.querySelectorAll('[data-helpable-type]').forEach((item) => {
      const helpableElm = new HelpableElement({ elm: item, studentRef: this });
      helpableElm.displayElement();
    });
  }

  /**
   * Calls function that unhighlight Elements
   */
  dispatchUnhighlightEvt() {
    document.querySelectorAll('[data-helpable-type]').forEach((item) => {
      const helpableElm = new HelpableElement({ elm: item, studentRef: this });
      if (item.parentNode.classList.contains('helpable')) {
        helpableElm.removeFocusElements();
      }
    });
  }

  /**
   * Open Banner for displaying information regarding Help Request.
   */
  openFlashBanner() {
    const flashBanner = document.querySelector('.js-help-request-flash');
    flashBanner.classList.remove('u-hidden');
    flashBanner.querySelector('.js-help-request-flash-msg')
      .innerText = 'Choose the selectable area to add your request.';
    flashBanner.querySelector('.js-help-request-cancel').addEventListener('click', () => {
      this.cancelRequest();
    });
  }

  /**
   * Closes Banner that displays information regarding Help Request.
   */
  closeFlashBanner() {
    document.querySelector('.js-help-request-flash').classList.add('u-hidden');
  }

  /**
   * Trigger action on cancel the help request.
   * @param {Boolean} removeResizeListener - Whether to remove the resize listener or not
   */
  cancelRequest(removeResizeListener = true) {
    this.requestMode = removeResizeListener ? 'default' : this.requestMode;
    this.activityFormData = '';
    this.setAskInstructorLinkVisibility(true);
    this.setHelpNavMenuItemsVisibility(true);
    setRequestModeBodyClass(this.requestMode);
    updateSaveSubmit(this.requestMode);
    enableVtextLink();
    // Ugly for the moment. Close the menu in the Account Tools Menu.
    document.querySelector('#account_menu')?.querySelectorAll('.help_menu')?.forEach((elm) => {
      elm.classList.add('hidden_helper');
    });

    this.closeFlashBanner();
    // Sends a message to the helpable-type scopes
    this.dispatchUnhighlightEvt();
    HelpRequestOverlay.removeProxyHotspots(
      document.querySelector('.js-transparent-hr-overlay')
    );

    // On close of request modal, move accent bar element back to accent bar container in activity.
    // this.moveAccentBarBackToActivity();

    if (removeResizeListener) {
      window.removeEventListener('resize', this.onResizeRequestModeHandler);
    }
  }

  /**
   * Click Handler based on help requests type.
   */
  clickRequestTypes() {
    document.querySelector('.js-help-request-mode')?.addEventListener('click', () => {
      this.activateRequestMode('request_help');
      window.addEventListener('resize', this.onResizeRequestModeHandler);
    });

    document.querySelector('.js-review-request-mode')?.addEventListener('click', () => {
      this.activateRequestMode('request_review');
      window.addEventListener('resize', this.onResizeRequestModeHandler);
    });

    document.querySelector('.js-content-request-mode')?.addEventListener('click', () => {
      this.activateRequestMode('report_content_problem');
      window.addEventListener('resize', this.onResizeRequestModeHandler);
    });

    document.addEventListener('connectivityTestLoaded', () => {
      document.querySelector('.js-contact-technical-support')?.addEventListener('click', () => {
        this.activateRequestMode('report_technical_problem');
      });
    });
  }

  /**
   * This method handles the resize event when the request mode is active.
   * It cancels the current request and activates the request mode again.
   * This is useful for resizing the help request overlay.
   */
  onResizeRequestModeHandler() {
    this.cancelRequest(false);
    this.activateRequestMode(this.requestMode);
  }

  /**
   * This binds on event 'requestEnded' which is fired when add help request dialog is closed
   */
  bindRequestEnded() {
    document.addEventListener('requestEnded', (event) => {
      const requestMode = event?.detail?.requestMode;
      if ( requestMode === 'report_technical_problem' ) {
        this.cancelRequest();
      }
    });
  }

  /**
   * Show / hide following Help Menu Items on navbar:
   * 'Report a technical problem'
   * 'Report a content problem'
   * @param {Boolean} bShow - Whether to show or hide
   */
  setHelpNavMenuItemsVisibility(bShow) {
    this.setElementVisibility('.js-content-request-mode-wrapper', bShow);
  }

  /**
   * Show / Hide 'Ask Your Instructor link'.
   * @param {Boolean} bShow - Whether to show or hide
   */
  setAskInstructorLinkVisibility(bShow) {
    this.setElementVisibility('.js-help-request-mode', bShow);
    this.setElementVisibility('.js-review-request-mode', bShow);
  }

  /**
   * This method shows / hides an element:
   * @param {String} selector - Css selector for the element
   * @param {Boolean} bShow - Whether to show or hide
   */
  setElementVisibility(selector, bShow) {
    const elmClassList = document.querySelector(selector)?.classList;
    if (bShow) {
      elmClassList?.remove('u-hidden');
    } else {
      elmClassList?.add('u-hidden');
    }
  }
}

export default StudentRequest;
