import FlashBannerSetup from 'features/flash_banner/flash_banner_setup.js';

describe('FlashBannerSetup', () => {
  const html = '<div class="js-vue-flash-banner"></div>';
  document.body.innerHTML = html;

  const testReset = () => {
    setTimeout(() => {
      expect(FlashBannerSetup.vm.currentMessage).toMatchObject({
        text: '',
        className: '',
        shown: false,
      });
    }, 10000);
  };

  const testShowMessage = (msgText, className) => {
    expect(FlashBannerSetup.vm.currentMessage).toMatchObject({
      text: msgText,
      className: className,
      shown: true,
    });
  };

  describe('init', () => {
    it('mounts vue app on "js-vue-flash-banner"', () => {
      FlashBannerSetup.init();
      expect(FlashBannerSetup.rootEl.classList.contains('js-vue-flash-banner')).toBe(
        true
      );
      expect(
        FlashBannerSetup.rootEl.querySelectorAll('.test-flash-banner')
      ).toHaveLength(1);
    });
  });

  describe('showSuccess', () => {
    const msgText = 'Note successfully saved!';

    beforeEach(() => {
      FlashBannerSetup.init();
      FlashBannerSetup.showSuccess(msgText);
    });

    it('should show success message', () => {
      testShowMessage(msgText, 'success');
    });

    it('sets a timeout to reset the message after 10 seconds', () => {
      testReset();
    });
  });

  describe('showWarning', () => {
    const msgText = "I'd turn back if I were you.";

    beforeEach(() => {
      FlashBannerSetup.init();
      FlashBannerSetup.showWarning(msgText);
    });

    it('should show warning message', () => {
      testShowMessage(msgText, 'warning');
    });

    it('sets a timeout to reset the message after 10 seconds', () => {
      testReset();
    });
  });

  describe('showError', () => {
    const msgText = 'Note Error!';

    beforeEach(() => {
      FlashBannerSetup.init();
      FlashBannerSetup.showError(msgText);
    });

    it('should show error message', () => {
      testShowMessage(msgText, 'error');
    });

    it('sets a timeout to reset the message after 10 seconds', () => {
      testReset();
    });
  });
});
