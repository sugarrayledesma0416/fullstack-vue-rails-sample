import HighlightElements from './highlight_elements.js';
import NotesOverlayBuilder from './notes_overlay_builder.js';

let allowsExpandedNotes;

/**
 * Class for overlay operations.
 */
class Overlay {
  /**
  * Initialise the overlay.
  */
  static attachEvtHandler() {
    const notesBanner = document.querySelector('.js-instructor-note-flash');
    const cancelFlashBtn = notesBanner.querySelector('.js-instructor-note-cancel');

    allowsExpandedNotes = document
      .querySelector('.js-allows-expanded-notes')
      .getAttribute('data-allows-expanded-notes');

    const notableElements = new HighlightElements(
      document.querySelectorAll('[data-instructor-notable]'),
      allowsExpandedNotes
    );

    document
      .querySelector('.js-add-instructor-note')
      .addEventListener('click', (evt) => {
        Overlay.show(notesBanner, cancelFlashBtn);
      });

    Overlay.allowFlashGracefulExit(notesBanner, cancelFlashBtn);

    document.addEventListener('unselect_notable', (evt) => {
      notableElements.unselectNotable(evt.detail);
    });
  }

  /**
  * Show Overlay.
  * @param {HTMLElement} notesBanner Instructor notes information display banner.
  * @param {HTMLElement} cancelFlashBtn Cancel Button over banner.
  */
  static show(notesBanner, cancelFlashBtn) {
    const notesOverlay = NotesOverlayBuilder;
    const overlay = notesOverlay.overlay();
    notesBanner.classList.remove('u-hidden');

    const proxyCancelFlashBtn = notesOverlay.addProxyHotspot(
      overlay,
      cancelFlashBtn,
      'notes'
    );
    proxyCancelFlashBtn.classList.add('u-pad-8', 'test-instructor-note-cancel');
    proxyCancelFlashBtn.setAttribute(
      'aria-label',
      'cancel instructor note button'
    );
    Overlay.allowFlashGracefulExit(notesBanner, proxyCancelFlashBtn);
    Overlay.displayHighlightedElement();

    // Accessibility Section.
    notesOverlay.addCircularNavigation();
    notesOverlay.showOverlay(overlay);
  }

  /**
  * Closes the Overlay.
  * @param {HTMLElement} notesBanner Instructor notes information display banner.
  */
  static close(notesBanner) {
    const notesOverlay = NotesOverlayBuilder;
    const overlay = notesOverlay.overlay();

    notesOverlay.hideOverlay(overlay);
    notesOverlay.removeProxyHotspots(overlay);
    notesBanner.classList.add('u-hidden');
  }

  /**
  * Binds event when click on banner cancel button.
  * @param {HTMLElement} notesBanner Instructor notes information display banner.
  * @param {HTMLElement} cancelFlashButton Cancel Button over banner.
  */
  static allowFlashGracefulExit(notesBanner, cancelFlashButton) {
    const eventsToListen = ['click', 'keyup'];
    eventsToListen.forEach((eventType) => {
      cancelFlashButton.addEventListener(eventType, (evt) => {
        // 13 is for Enter Key & 32 is for Space Bar key.
        if (evt.type === 'click' || evt.keyCode === 13 || evt.keyCode === 32) {
          const instructorNotables = document.querySelectorAll('[data-instructor-notable]');
          instructorNotables.forEach((item) => {
            const notableElements = new HighlightElements(
              instructorNotables,
              allowsExpandedNotes
            );
            notableElements.unhighlightNotable(item);
            notableElements.unselectNotable(item);
          });

          notesBanner.classList.add('u-hidden');
          Overlay.close(notesBanner);
        }
      });
    });
  }

  /**
  * Highlights the element over overlay.
  */
  static displayHighlightedElement() {
    const instructorNotables = document.querySelectorAll('[data-instructor-notable]');
    instructorNotables.forEach((item) => {
      const notableElements = new HighlightElements(
        instructorNotables,
        allowsExpandedNotes
      );
      notableElements.highlightNotable(item);
    });
  }
}

export default Overlay;
