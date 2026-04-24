import FlashBannerSetup from './flash_banner_setup';

let userNotWarnedYet = true;

const showSaveWorkWarning = (msgText) => {
  if (userNotWarnedYet) {
    FlashBannerSetup.init();
    FlashBannerSetup.showWarning(
      "You only have two minutes left. Submit soon so you don't lose your work.",
      {
        announce: true,
        fade: true,
      }
    );

    userNotWarnedYet = false;
  }
};

export default showSaveWorkWarning;
