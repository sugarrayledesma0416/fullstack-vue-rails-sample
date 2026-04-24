import NotesOverlayBuilder from './notes_overlay_builder.js';
import Overlay from './overlay.js';

/**
 * Class for display of Hotspot Elements.
 */
class HighlightElements {
  /**
  * Initialise function for HighlightElements
  * @param {array} elements Array of Elements that needs to be highlighted.
  * @param {string} allowsExpandedNotes defines whether expanded notes are allowed or not.
  */
  constructor(elements, allowsExpandedNotes) {
    this.elements = elements;
    this.allowsExpandedNotes = allowsExpandedNotes === 'true';
    this.clickCallbacks = this.processCallbacks(this.elements);
  }

  /**
  * Highlight notable element. Append the element over Overlay.
  * @param {HTMLElement} elm Element that needs to be highlighted.
  * @return {void}.
  */
  highlightNotable(elm) {
    // For chat activities like - Vchat, VVchat, Pchat & InfoGap-Pchat
    // we don't allow adding notes on any notable element except the direction line.
    if (!elm.classList.contains('js-direction-line') && !this.allowsExpandedNotes) {
      return;
    }
    elm.classList.add('highlighted_notable');
    elm.addEventListener('click', this.clickCallbacks[elm.id]);
    this.appendToOverlay(elm);
  }

  /**
  * UnHighlight notable element.
  * @param {HTMLElement} elm Element that needs to be unhighlighted.
  */
  unhighlightNotable(elm) {
    elm.classList.remove('highlighted_notable');
    elm.removeEventListener('click', this.clickCallbacks[elm.id]);
  }

  /**
  * unselectNotable element.
  * @param {HTMLElement} elm Element that needs to be unselected.
  */
  unselectNotable(elm) {
    elm.classList.remove('selected_notable');
    elm
      .querySelectorAll('.helpable_anchor')
      .forEach((e) => e.parentNode.removeChild(e));
  }

  /**
  * It appends the element over overlay
  * @param {HTMLElement} elm Element that needs to be append.
  */
  appendToOverlay(elm) {
    const notesOverlay = NotesOverlayBuilder;
    const overlay = notesOverlay.overlay();
    const proxyElm = notesOverlay.addProxyHotspot(overlay, elm, 'notes');
    const eventsToListen = ['click', 'keyup'];
    eventsToListen.forEach((eventType) => {
      proxyElm.addEventListener(eventType, (evt) => {
        // 13 is for Enter Key & 32 is for Space Bar key.
        if (evt.type === 'click' || evt.keyCode === 13 || evt.keyCode === 32) {
          this.dispatchChosenEvent(elm);
          notesOverlay.hideOverlay(overlay);
        }
      });
    });
  }

  /**
  * It dispatch event(i_was_chosen) to all the highlightable element.
  * @param {HTMLElement} elm Element that needs to be highlighted.
  */
  dispatchChosenEvent(elm) {
    elm.classList.add('selected_notable');
    const selectedElementEvent = new CustomEvent('i_was_chosen', {
      'detail': elm.id,
    });
    document.dispatchEvent(selectedElementEvent);

    document
      .querySelectorAll('[data-instructor-notable]')
      .forEach((item) => {
        this.unhighlightNotable(item);
      });
    Overlay.close(document.querySelector('.js-instructor-note-flash'));
  }

  /**
  * It defines the callback that needs to be attachhed the highlightable elements.
  * @param {HTMLElement} elements Array of Elements that requires the attachement of callbacks.
  * @return {object}
  */
  processCallbacks(elements) {
    const clickCallbackObj = {};
    for (const elm of elements) {
      clickCallbackObj[elm.id] = () => {
        this.dispatchChosenEvent(elm);
      };
    }
    return clickCallbackObj;
  }
}

export default HighlightElements;
