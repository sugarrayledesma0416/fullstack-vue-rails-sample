/* global VHL */

VHL.DashboardAnnouncement = class DashboardAnnouncement {
  /**
   * Class that handles changes for instructor dashboard Announcements
   **/
  /**
   * Function that requires user acknowledgement to change visible announcement
   * volVisible = vol announcement is currently visible (from DB)
   * ssVisible = supersite announcement is currently visible (from DB)
   * volChecked = vol checkbox is currently checked
   * ssChecked = supersite checkbox is currently checked
   **/
  makeVisible() {
    const volVisible = $('.js-vol-true').length;
    const ssVisible = $('.js-ss-true').length;
    const volChecked = $('.js-vol').is(":checked");
    const ssChecked = $('.js-supersite').is(":checked");
    if((volVisible > 0 && volChecked) || (ssVisible > 0 && ssChecked)) {
      $('.js-modal-visible').vhlModal('open');
      event.preventDefault();
      $('.js-submit-form').on("click", function() {
        $('.js-dashboard-announcement-form').submit();
      });
    };
  };
  /**
   * Keep anouncement visible unless the user dismisses it
   **/
  showUntilDismissed(cookieId) {
    const cookies = document.cookie.split(';');
    const dismissDashboardAnnouncement = cookies.filter((item) => item.includes(cookieId));
    if (dismissDashboardAnnouncement.length > 0) {
      $('.js-dashboard-announcement-notification').setState('hidden');
    } else {
      $('.js-dashboard-announcement-notification').setState('visible');
    };
  }
  /**
   * Hides announcement on request from the user
   **/
  dismiss(cookieId) {
    document.cookie = cookieId + "=dismissed";
    $('.js-dashboard-announcement-notification').setState('hidden');
  }
};

$(document).ready(function() {
  const dashboardAnnouncement = new VHL.DashboardAnnouncement();
  const cookieId = 'dashboard-announcement-' + $('.js-dashboard-announcement-notification').data('announcement-id');
  dashboardAnnouncement.showUntilDismissed(cookieId);
  $('.js-dashboard-announcement').on('click', function() {
    dashboardAnnouncement.dismiss(cookieId);
  });
  $('.js-check-visibility').on('click', function() {
    dashboardAnnouncement.makeVisible();
  });
});
