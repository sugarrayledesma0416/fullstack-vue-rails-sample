VHL = VHL || {};

/**
 * Class to handle/initialize UI states for mobile view with tabs, for group chat
 */
class MobileViewGroupChat {
  /**
   * This function initialize the group chat mobile view.
   */
  init() {
    this.initializeMobileTabsView();
    this.setMobileTabsViewLaunchState();
    this.bindStartActivityClickHandler();
    const containerElm = document.querySelector('.js-mobile-activity-start-container');
    containerElm?.classList.remove('u-hidden');
  }

  /**
   * @private
   * This function handles the click event on the start activity button.
   */
  bindStartActivityClickHandler() {
    const startActivityBtnElm = document.querySelector(
      '.js-mobile-group-chat-start-button'
    );

    startActivityBtnElm?.addEventListener('click', () => {
      const tabsViewElm = document.querySelector('.js-mobile-tabs-view');
      if (VHL.MobileTabsViewGroupchat) {
        VHL.MobileTabsViewGroupchat.setState('TABSET_HIDDEN');
        VHL.MobileTabsViewGroupchat.setActiveTab('PRIMARY');
      }

      tabsViewElm.classList.remove('c-mobile-chat-activity-landing-page');

      if (VHL.ActivityShell &&
          typeof VHL.ActivityShell.setActivityHeight == 'function') {
        VHL.ActivityShell.setActivityHeight();
      }
      document.querySelector('.js-open-av-check')?.focus();
    });
  }

  /**
   * @private
   * This function initializes Mobile Tabs View component with tabs details json
   */
  initializeMobileTabsView() {
    if (VHL?.MobileTabsViewCls) {
      const tabsConfig = {
        PRIMARY: { name: 'VIDEO' },
        REFERENCE: { name: 'REFERENCE' },
      };

      VHL.MobileTabsViewGroupchat = new VHL.MobileTabsViewCls(tabsConfig);
    }
  }

  /**
   * @private
   * This function set relevant Mobile Tabs View component state on page load
   * based on page's meta attribute 'VHL.MobileTabsView.groupChatMobileViewOnLaunch'
   */
  setMobileTabsViewLaunchState() {
    if (VHL && VHL.MobileTabsViewGroupchat) {
      const groupChatMobileViewOnLaunch = document.querySelector(
        'meta[name="VHL.MobileTabsView.groupChatMobileViewOnLaunch"]'
      ).content;

      const tabsViewElm = document.querySelector('.js-mobile-tabs-view');

      switch (groupChatMobileViewOnLaunch) {
      case 'TABSET_VISIBLE':

        VHL.MobileTabsViewGroupchat.setState('TABSET_VISIBLE');
        VHL.MobileTabsViewGroupchat.setActiveTab('PRIMARY');

        tabsViewElm.classList.add('c-mobile-chat-activity-show-footer');
        break;
      case 'LANDING_PAGE':
      default:

        VHL.MobileTabsViewGroupchat.setState('TABSET_HIDDEN');
        VHL.MobileTabsViewGroupchat.setActiveTab('REFERENCE');

        tabsViewElm.classList.add('c-mobile-chat-activity-landing-page');
        break;
      }
    }
  }
}

window.addEventListener('DOMContentLoaded', () => {
  const mobileViewGroupChat = new MobileViewGroupChat();
  mobileViewGroupChat.init();
});
