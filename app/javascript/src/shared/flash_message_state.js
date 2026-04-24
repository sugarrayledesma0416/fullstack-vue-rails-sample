import { reactive } from 'vue';

/**
 * Class representing flash error/notice messages reactive state.
 */
class FlashMessageState {
  /**
   * Instantiate the FlashMessageState class.
   */
  constructor() {
    this.state = reactive({
      showError: false,
      showNotice: false,
    });
  }

  /**
   * Get whether to show error message
   * @return {boolean}
   */
  get showError() {
    return this.state.showError;
  }

  /**
   * Get whether to show notice message
   * @return {boolean}
   */
  get showNotice() {
    return this.state.showNotice;
  }

  /**
   * Display error for 10 seconds.
   */
  displayError() {
    this.state.showError = true;
    setTimeout(() => {
      this.state.showError = false;
    }, 10000);
  }

  /**
   * Display notice for 10 seconds.
   */
  displayNotice() {
    this.state.showNotice = true;
    setTimeout(() => {
      this.state.showNotice = false;
    }, 10000);
  }
}

export default FlashMessageState;
