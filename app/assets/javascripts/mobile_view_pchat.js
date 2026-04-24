/**
 * Class to handle/initialize UI states for mobile view with tabs, for pchat
 */

VHL = VHL || {};

class MobileViewPChat {

  constructor() {}

  init() {
    this._initializeMobileTabsView();
    this._setMobileTabsViewLaunchState();
    this._bindChosePartnerClickHandler();
    $('.js-mobile-activity-start-container').removeClass("u-hidden");
  }
  
  /**
   * This function initializes Mobile Tabs View component with tabs details json
   */
  _initializeMobileTabsView() {
    if (VHL && VHL.MobileTabsViewCls) {
      let tabsConfig = {
        PRIMARY: {name: "VIDEO"},
        REFERENCE: {name: "REFERENCE"},
        // TODO: Audio text related tab should come based on detection of audio text content in pchat activity.
        // This use case is not clear yet. Use - OTHER: {name: "AUDIO TEXT"} for this case.
      }
      
      // This variable 'VHL.MobileTabsViewPchat' points to pchat version of instance of
      // Mobile Tabs View component. This var would be used to change mobile UI via component's APIs.
      VHL.MobileTabsViewPchat = new VHL.MobileTabsViewCls(tabsConfig);
    }
  }
    
  /**
   * This function would set relevant Mobile Tabs View component state on page load
   * based on page's meta attribute 'VHL.MobileTabsView.pchatMobileViewOnLaunch'
   */
  _setMobileTabsViewLaunchState() {
    if (VHL && VHL.MobileTabsViewPchat) {
      let pchatMobileViewOnLaunch = $('meta[name="VHL.MobileTabsView.pchatMobileViewOnLaunch"]').attr('content');
      switch (pchatMobileViewOnLaunch) {
        case "TABSET_VISIBLE":

          // Set pchat mobile view when call is connected on launch page itself.
          // This view would have Mobile Tabs View component's tabset visible and shows primary content
          VHL.MobileTabsViewPchat.setState("TABSET_VISIBLE");
          VHL.MobileTabsViewPchat.setActiveTab("PRIMARY");

          // As per the use case footer is to be visible here, which otherwise is hidden by default via css
          $(".js-mobile-tabs-view").addClass("c-mobile-chat-activity-show-footer");
          break;
        case "LANDING_PAGE":
        default:

          // Set pchat mobile view to default screen/ landing page (the one with Choose Partner button)
          // This view would have Mobile Tabs View component's tabset hidden and shows reference content
          VHL.MobileTabsViewPchat.setState("TABSET_HIDDEN");
          VHL.MobileTabsViewPchat.setActiveTab("REFERENCE");

          // This is to enable landing page specific UI changes eg. show Choose Partner button
          $(".js-mobile-tabs-view").addClass("c-mobile-chat-activity-landing-page");
          break;
      }
    }
  }

  _bindChosePartnerClickHandler() {
    $('.js-mobile-pchat-start-button').on('click', () => {

      // Set pchat mobile view to roster pane
      // This view would have Mobile Tabs View component's tabset hidden and shows primary content
      if (VHL.MobileTabsViewPchat) {
        VHL.MobileTabsViewPchat.setState("TABSET_HIDDEN");
        VHL.MobileTabsViewPchat.setActiveTab("PRIMARY");
      }

      // This is to remove landing page specific UI changes
      $(".js-mobile-tabs-view").removeClass("c-mobile-chat-activity-landing-page");
      if (VHL.ActivityShell
          && typeof VHL.ActivityShell.setActivityHeight == "function") {
        VHL.ActivityShell.setActivityHeight();
      }
    });
  }
}

$(document).ready(() => {
  let mobileViewPChat = new MobileViewPChat();
  mobileViewPChat.init();
});
