import NotesOverlayBuilder from 'views/instructor_notes/instructor_notes/notes_overlay_builder';
import { getHtmlDocument } from '../../../support/utils';

describe('Activity Notes Overlay Builder class', () => {
  beforeEach(() => {});

  describe('#overlayClass', () => {
    it('returns a string that contains the class of the overlay', () => {
      expect(
        NotesOverlayBuilder.overlayClass()
      ).toBe('js-transparent-overlay-instructor-note');
    });
  });

  describe('#overlay', () => {
    it('returns a div where instructor note overlay class is append', () => {
      expect(
        NotesOverlayBuilder.overlay()
      ).toHaveClass(NotesOverlayBuilder.overlayClass());
    });
  });

  describe('#addCircularNavigation', () => {
    it('checks ciruclar navigation over the hotspot of overlay', () => {
      const overlay = NotesOverlayBuilder.overlay();

      let htmlDOM = getHtmlDocument(`
        <button class="c-proxy-hotspot  c-no-button  js-proxy-hotspot"
              aria-label="Selectable Area" id="overlay-direction_line">
        </button>`);
      overlay.appendChild(
        htmlDOM.querySelector('#overlay-direction_line')
      );

      htmlDOM = getHtmlDocument(`
        <button class="c-proxy-hotspot c-no-button js-proxy-hotspot u-pad-8
        test-instructor-note-cancel" aria-label="cancel instructor note button"
        id="overlay-cancel">
        </button>`);
      overlay.appendChild(
        htmlDOM.querySelector('#overlay-cancel')
      );

      NotesOverlayBuilder.addCircularNavigation();
      const hotspotElmsLength = overlay.querySelectorAll('.js-proxy-hotspot').length;

      expect(
        overlay.querySelectorAll('.js-proxy-hotspot')[0]
      ).toHaveClass('js-modal-a11y__first-focus-element');

      expect(
        overlay.querySelectorAll('.js-proxy-hotspot')[0]
      ).toHaveClass('js-modal-a11y__default-focus');

      expect(
        overlay.querySelectorAll('.js-proxy-hotspot')[hotspotElmsLength - 1]
      ).toHaveClass('js-modal-a11y__last-focus-element');
    });
  });
});
