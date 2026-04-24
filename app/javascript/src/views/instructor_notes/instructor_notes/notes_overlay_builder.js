import OverlayBuilder from 'shared/accessible_hotspots/overlay_builder';

/**
 * Class required to perform some overlay operation specific to
 * Instructor Notes.
 */
class NotesOverlayBuilder extends OverlayBuilder {
  /**
   * Returns a string which is the overlay class.
   * @return {string} Overlay class.
   */
  static overlayClass() {
    return 'js-transparent-overlay-instructor-note';
  }

  /**
   * Returns overlay DOM element.
   * @return {HTMLElement} Overlay.
   */
  static overlay() {
    return this.append(this.overlayClass());
  }

  /**
   * Defines the accessibility over highlighted element.
   * Returns overlay DOM element.
   */
  static addCircularNavigation() {
    this.overlayAccessibility(this.overlayClass());
  }
}

export default NotesOverlayBuilder;
