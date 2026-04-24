import { createApp } from 'vue';
import FlashBannerComponent from './FlashBannerComponent';

/** Class representing a Flash Banner Setup. */
class FlashBannerSetup {
  /**
   * Mounts a FlashBannerComponent app on rootEl('.js-vue-flash-banner').
   */
  static init() {
    this.rootEl = document.querySelector('.js-vue-flash-banner');
    this.app = createApp(FlashBannerComponent);
    this.vm = this.app.mount(this.rootEl);
  }

  /**
   * Show the success message.
   *  @param {string} msgText Message that needs to be displayed.
   */
  static showSuccess(msgText) {
    this.showMessage(msgText, 'success');
  }

  /**
   * Show the warning message.
   * Settings include:
   *   - announce: boolean - whether to force announcing by screen reader
   *   - fade: boolean - whether to fade banner at end of timeout
   * @param {string} msgText Message that needs to be displayed.
   * @param {object} settings Object with message settings
   */
  static showWarning(msgText, settings) {
    this.showMessage(msgText, 'warning', settings);
  }

  /**
   * Show the error message.
   * @param {string} msgText Message that needs to be displayed.
   */
  static showError(msgText) {
    this.showMessage(msgText, 'error');
  }

  /**
   * Show the message with given class name and settings;
   * hides message after 10 seconds.
   *
   * If the settings object includes `'fade': true`, the message is faded out
   * by CSS animation. Otherwise, the message is immediately removed from the
   * DOM in the FlashBannerComponent.
   *
   * @param {string} msgText Message that needs to be displayed.
   * @param {string} className Class name for display.
   * @param {object} settings Object with message settings
   */
  static showMessage(msgText, className, settings = {}) {
    const updatedSettings = {
      announce: settings.announce || false,
      className: className || 'success',
      shown: true,
      text: msgText,
    };

    this.vm?.updateCurrentMessage(updatedSettings);

    const fadeCallback = () => {
      /**
       * Call with the same settings as before (except for `fadedOut`).
       * Otherwise, `shown` will end up as `false`, removing the whole
       * div.
       */
      this.vm?.updateCurrentMessage(
        Object.assign(
          updatedSettings,
          {
            fadedOut: true,
          }
        )
      );
    };

    const resetMessageCallback = () => {
      this.resetMessage();
    };

    const hideMessageCallback = settings.fade ? fadeCallback : resetMessageCallback;
    setTimeout(hideMessageCallback, 10000);
  }

  /**
   * Reset the message.
   */
  static resetMessage() {
    this.vm?.updateCurrentMessage({
      text: '',
      className: '',
      shown: false,
    });
  }
}

const showMessage = (text, evt) => {
  if (evt === 'showSuccessMsg') {
    FlashBannerSetup.showSuccess(text);
  } else {
    FlashBannerSetup.showError(text);
  }
};

['showSuccessMsg', 'showErrorMsg'].forEach( (evt) =>
  document.addEventListener(evt, (arg) => {
    const { text } = arg.detail;
    showMessage(text, evt);
  })
);

export default FlashBannerSetup;
