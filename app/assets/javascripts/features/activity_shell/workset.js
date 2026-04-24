/**
 * Assignment Workset
 *
 * Attach event handlers and set visibility
 * and ARIA attributes. Persist the state of
 * the workset to localStorage.
 *
 */
class WorkSetBehavior {
  constructor() {
    // Cache the UI elements involved:
    this._$workset = $('.js-workset');
    this._$worksetToggle = $('.js-toggle-workset');
    this._$closeWorksetTop = $('.js-close-workset-top');
    this._$closeWorkset = $('.js-close-workset');
    this._$currentActivity = $('.is-current');
    this._$navbarAccount = $('.js-navbar--account');
    this.worksetIsOpen = null;
  }

  /**
   * @constant
   * @type {string}
   * @default
   */
  static get WORKSET_OPEN_CLASS() {
    return 'is-open';
  }

  /**
   * @constant
   * @type {string}
   * @default
   */
  static get DEFAULT_TOGGLE_STATE() {
    return 'open';
  }

  /**
   *  Initialize workset
   *
   * Workset initially has class u-hidden,
   * to prevent it displaying during page load.
   * After that show/hide is done with
   * position & opacity CSS transitions.
   *
   * Load saved state, then animate and/or set u-hidden
   * and ARIA attributes appropriately.
   *
   * @public
   */
  init() {
    const openingWorkset = (this._loadWorksetState() == 'open');
    if (openingWorkset) {
      // Slide open the workset;
      // This also sets ARIA/visibility attributes.
      this.openWorkset();
    } else {
      // No need to animate anything;
      // Only set ARIA/visibility attributes:
      this._$workset.addClass('u-hidden');
      this._$workset.attr('aria-hidden', true);
      this._$worksetToggle.setState('expanded', false);
    }
    this._attachEventHandlers();
    this.addScrollObserver();
    this.worksetIsOpen = openingWorkset;
  }

    /**
     * Set UI behaviors for the Workset.
     *
     * @private
     */
  _attachEventHandlers() {
    // Handle open/close workset via "Show Assignments" button:
    this._$worksetToggle.on('click', () => {this.toggleWorkset()});

    // Clicking on close button closes the workset.
    this._$closeWorkset.on('click', () => {this.closeWorkset()});
  }

  /**
   *  Set visibility of the workset and handle
   *  transitions and accessibility properties.
   *
   * @private
   * @param {Boolean} openingWorkset - true = opening, false = closing.
   */
  _updateUI(openingWorkset = true) {
    // If opening, make visible before sliding in:
    if (openingWorkset) {
      this._$workset.removeClass('u-hidden');
    }
    // After making visible, need to wait til next render cycle
    // or else the browser batches the UI changes, thus no slide.
    window.requestAnimationFrame(() => {
      // Start the slide/fade:
      this._$workset.toggleClass(WorkSetBehavior.WORKSET_OPEN_CLASS, openingWorkset);
      // Update ARIA attributes:
      this._$workset.attr('aria-hidden', !openingWorkset);
      this._$worksetToggle.setState('expanded', openingWorkset);

      // Some actions need to happen only after the slide/fade ends:
      this._$workset.on('transitionend', () => {
        if (openingWorkset) {
          this._$closeWorksetTop.focus();
          this._scrollToCurrentActivity();
        } else {
          this._$workset.addClass('u-hidden');
          this._$worksetToggle.focus();
        }
        this._$workset.off('transitionend');
      })
    });
  }

  /**
   * Toggle the open/closed state of the workset.
   *
   * @public
   */
  toggleWorkset() {
    const openingWorkset = !this.worksetIsOpen;
    this._updateUI(openingWorkset);
    this._saveWorksetState(openingWorkset);
    this.worksetIsOpen = openingWorkset;
  }

  /**
   * Open the workset.
   *
   * @public
   */
  openWorkset() {
    this._updateUI(true);
    this._saveWorksetState(true);
    this.worksetIsOpen = true;
  }

  /**
   * Close the workset.
   */
  closeWorkset() {
    this._updateUI(false);
    this._saveWorksetState(false);
    this.worksetIsOpen = false;
  }

  /**
   * Move the workset to the top when scrolling down the page and move it to
   * under masthead when scrolling up until the top of the page
   */
  addScrollObserver() {
    // mastHeadHeight is negative because the scroll down movement is calculated negatively.
    let mastHeadHeight = document.querySelector('.js-navbar--account').offsetHeight * -1;
    let observer = new IntersectionObserver(entries => {
      // when masthead moves out of the current view the observer will get tiggered.
      if (entries[0].boundingClientRect.y < mastHeadHeight) {
        this._$workset.addClass('c-workset--top-0');
      } else {
        this._$workset.removeClass('c-workset--top-0');
      }
    });
    observer.observe(document.querySelector('.js-navbar--account'));
  }

  /**
   * Fetch the _saved_ Workset state from localStorage.
   * If localStorage undefined, set to default.
   *
   * @private
   */
  _loadWorksetState() {
    return localStorage.getItem('workset_state') || WorkSetBehavior.DEFAULT_TOGGLE_STATE;
  }

  /**
   * Save the workset state.
   *
   * @private
   */
  _saveWorksetState(openingWorkset) {
    const newStoredValue = (openingWorkset) ? 'open' : 'closed';
    localStorage.setItem('workset_state', newStoredValue);
  }

  /**
   *Move scroll to activity with 'is-current' class.
   *
   * @private
   */
  _scrollToCurrentActivity(){
    /*staticOffsetTop get the nav height and add 20 to calculate the space betwen the nav and current actibity item on workset.*/
    const staticOffsetTop = this._$navbarAccount.height() + 20;
    const offsetTop = this._$currentActivity.offset().top;
    this._$workset.scrollTop(offsetTop - staticOffsetTop);
  }
}

window.addEventListener('DOMContentLoaded', () => {
  const workset = new WorkSetBehavior();
  workset.init();
});

