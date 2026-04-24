import HelpRequestOverlay from './help_request_overlay';
import { disableVtextLink } from './utils.js';

/**
* Class the defines the operation of Elements eligible for Highlighting.
*/
class HelpableElement {
  /**
  * instantiate HelpableElement class.
  * @param {Object} detail
  */
  constructor(detail) {
    this.element = detail.elm;
    this.ref = detail.studentRef;
    this.helpableType = this.element.getAttribute('data-helpable-type');
  }

  /**
  * Displays the element for Adding Help Request.
  */
  displayElement() {
    if (this.validateHelpableElements()) {
      this.highlightElement();

      if (this.helpableType === 'vtext_reference') {
        disableVtextLink();
      }
    }
  }

  /**
  * Remove the elements
  */
  removeFocusElements() {
    this.enableInputs(this.element.parentNode);

    const elementToRemove = this.element.parentNode;
    if (elementToRemove.dataset.helpableParent === 'helpable-parent') {
      // Remove the target anchor
      document.querySelector('.helpable_anchor').remove();
      elementToRemove.classList.remove('helpable');
    } else {
      // Otherwise, remove the entire helpable div.
      const elParentNode = this.element.parentNode;
      if (elParentNode !== document.body) {
        elParentNode.parentNode.insertBefore(this.element, elParentNode);
        elParentNode.parentNode.removeChild(elParentNode);
      }
    }
  }

  /**
  * Validates whether the elements are allowed to highlight.
  * @return {Object}
  */
  validateHelpableElements() {
    if (this.ref.userMode === 'instructor') {
      return true;
    }

    // Prevents a prompt with no text from having a helpable container added around it.
    // Empty ones are created particularly in cases such as Exams / Recap.
    if ((this.helpableType === 'question_prompt') && (this.element.textContent.trim() === '')) {
      this.helpableType = null;
    }

    // Check to see if the item has been answered, and if it was answered correctly.
    const answered = this.element.dataset.response === 'true';
    const correctness = this.element.dataset.correctness;

    return this.checkHighlight(answered, correctness);
  }

  /**
  * Check if element is highlightable.
  * @param {string} answered
  * @param {string} correctness
  * @return {boolean}
  */
  checkHighlight(answered, correctness) {
    if (this.ref.requestMode === 'request_review') {
      if (!answered || ((correctness == 'true') || (correctness == 'correct'))) {
        return false;
      }
    }

    let shouldHighlight = this.ref.requestRules[this.ref.requestMode];
    if (shouldHighlight) {
      shouldHighlight = shouldHighlight[this.helpableType];
      shouldHighlight = this.checkQuestionTypeHighlight(shouldHighlight);
    }
    return shouldHighlight || false;
  }

  /**
  * Check if element is highlightable on the basis of Question Type.
  * @param {boolean} shouldHighlight
  * @return {boolean}
  */
  checkQuestionTypeHighlight(shouldHighlight) {
    if (shouldHighlight) {
      // If the Helpable Type is true or false for something
      // like the direction line, we'll just return that. Otherwise:
      if (Array.isArray(shouldHighlight)) {
        // We check for the presence of the question type
        // within the helpable type array.
        return shouldHighlight.includes(this.questionType());
      }
    }
    return shouldHighlight;
  }


  /**
  * Activities that deal with Flash have to have the the helpable class
  * added to an existing div. Because the act of wrapping a flash element
  * in a div can be problematic. As such, many activity types have a
  * parent div now with a helpable type that we can tap into.
  */
  highlightElement() {
    const elementToModify = this.element.parentNode;

    if (elementToModify.dataset.helpableParent === 'helpable-parent') {
      elementToModify.classList.add('helpable');
      this.prependHtmlElm(elementToModify);
      HelpRequestOverlay.createProxyHotspot(this.ref, this, this.element, true);
      this.preventClickEventPropagation(elementToModify);
    } else {
      this.wrapDiv();
      HelpRequestOverlay.createProxyHotspot(this.ref, this, this.element);
    }

    this.disableInputs(elementToModify);
    [...elementToModify.getElementsByTagName('a')].forEach((elm) => {
      elm.addEventListener('click', this.linkControl);
    });

    this.addClickEventToHelpable(elementToModify);
  }

  /**
   * This method opens the add help request dialog with required parameters
   * @param {Event} event - With format of {data: {element, controllerRef}}
   */
  helpableDivClickCallback(event) {
    // We couldn't find a way to detect changes on help request link, there is no
    // directive for it, so, we retrieve the element in order to ask if has been
    // disabled by another js (like virtual_chat.js)
    if (document.querySelector('.js-help-request-mode.disabled')) {
      return;
    }

    const element = event.data.element;
    const controllerRef = event.data.controllerRef;
    if (element && controllerRef) {
      const requestMode = controllerRef.requestMode;
      const helpableItemId = element.getAttribute('id');
      const activityFormData = controllerRef.activityFormData;
      const helpableItemType = element.getAttribute('data-helpable-type');
      controllerRef.showCommentsDialog(
        requestMode, activityFormData, helpableItemId, helpableItemType
      );
      controllerRef.cancelRequest();
    }
  }

  /**
  * Adds an area above the engine specifically to give a place to
  * click for activities with flash.
  * @param {HTMLElement} elm element before a specific div needs to be inserted.
  */
  prependHtmlElm(elm) {
    const prependElm = document.createElement('div');
    prependElm.classList.add('helpable_anchor');
    prependElm.innerText = 'Click this area to select the activity content.';
    elm.insertBefore(prependElm, elm.firstChild);
  }

  /**
  * Wrap the div in a helpable container
  */
  wrapDiv() {
    const helpableDiv = document.createElement('div');
    helpableDiv.classList.add('helpable');
    this.element.parentNode.insertBefore(helpableDiv, this.element);
    helpableDiv.appendChild(this.element);
  }

  /**
  * Add the click function to the helpable div.
  * @param {HTMLElement} elementToModify
  */
  addClickEventToHelpable(elementToModify) {
    elementToModify.addEventListener(
      'click',
      { controllerRef: this.ref, element: this.element },
      this.helpableDivClickCallback
    );
  }

  /**
  * If the element is a map pin, prevent propagation of the click event.
  * because it will also close the info popup box.
  * @param {HTMLElement} elementToModify
  */
  preventClickEventPropagation(elementToModify) {
    if (this.element.classList.contains('pin_text_body')) {
      elementToModify.addEventListener('click', (evt) => {
        evt.stopPropagation();
      });
    }
  }

  /**
  * Disable any links and inputs within the helpable div.
  * @param {HTMLElement} helpable
  */
  disableInputs(helpable) {
    [...helpable.getElementsByTagName('input')].forEach((elm) => {
      elm.setAttribute('disabled', 'disabled');
    });

    [...helpable.getElementsByTagName('select')].forEach((elm) => {
      [...elm.getElementsByTagName('option')].forEach((el) => {
        el.setAttribute('disabled', 'disabled');
      });
    });
  }

  /**
  * Enable any links and inputs within the helpable div.
  * @param {HTMLElement} helpable
  */
  enableInputs(helpable) {
    [...helpable.getElementsByTagName('input')].forEach((elm) => {
      elm.removeAttribute('disabled');
    });

    [...helpable.getElementsByTagName('select')].forEach((elm) => {
      [...elm.getElementsByTagName('option')].forEach((el) => {
        el.removeAttribute('disabled');
      });
    });
  }

  /**
  * This disables / enables links that are within helpable containers so that you
  * can't click to open something in a new window when you're only trying to select it.
  * @param {Object} event
  */
  linkControl(event) {
    event.preventDefault();
  }

  /**
  * Defines the type of question.
  * @return {string}
  */
  questionType() {
    let parentElm = this.element.parentNode;
    while (parentElm.parentNode) {
      if (parentElm.dataset.questionType) {
        return parentElm.dataset.questionType;
      }
      parentElm = parentElm.parentNode;
    }
    return undefined;
  }
}

export default HelpableElement;
