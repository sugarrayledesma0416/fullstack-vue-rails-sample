var VHL = VHL || {};

VHL.RequestTasks = (function() {

  function init() {
    bind_menu_toggles();
    initialize_menus();
  }

  function bind_menu_toggles() {
    // Display Unprocessed Help Requests.
    $('[data-js-link="toggle_help_unprocessed"]').find('a').on("click", function() {
      hide_requests();
      display_help_unprocessed();
    });

    // Display Processed Help Requests.
    $('[data-js-link="toggle_help_processed"]').find('a').on("click", function() {
      hide_requests();
      display_help_processed();
    });

    // Display Unprocessed Review Requests.
    $('[data-js-link="toggle_review_unprocessed"]').find('a').on("click", function() {
      hide_requests();
      display_review_unprocessed();
    });

    // Display Processed Review Requests.
    $('[data-js-link="toggle_review_processed"]').find('a').on("click", function() {
      hide_requests();
      display_review_processed();
    });
  }

  function display_help_processed() {
    $('[data-js-link="toggle_help_processed"]').addClass('expanded program-header-bar');
    $('#processed_help_request_list').removeClass('hidden_helper');
  }

  function display_help_unprocessed() {
    $('[data-js-link="toggle_help_unprocessed"]').addClass('expanded program-header-bar');
    $('#unprocessed_help_request_list').removeClass('hidden_helper');
  }

  function display_review_processed() {
    $('[data-js-link="toggle_review_processed"]').addClass('expanded program-header-bar');
    $('#processed_review_request_list').removeClass('hidden_helper');
  }

  function display_review_unprocessed() {
    $('[data-js-link="toggle_review_unprocessed"]').addClass('expanded program-header-bar');
    $('#unprocessed_review_request_list').removeClass('hidden_helper');
  }

  function hide_requests() {
    $('[data-js-link="toggle_help_processed"]').removeClass('expanded program-header-bar');
    $('[data-js-link="toggle_help_unprocessed"]').removeClass('expanded program-header-bar');
    $('[data-js-link="toggle_review_processed"]').removeClass('expanded program-header-bar');
    $('[data-js-link="toggle_review_unprocessed"]').removeClass('expanded program-header-bar');

    $('#processed_help_request_list').addClass('hidden_helper');
    $('#unprocessed_help_request_list').addClass('hidden_helper');
    $('#processed_review_request_list').addClass('hidden_helper');
    $('#unprocessed_review_request_list').addClass('hidden_helper');
  }

  function initialize_menus() {
    // Display Details when (see details) is clicked.
    $('.request_toggle').on("click", function() {
      $('#request_details').toggleClass('hidden_helper');
    });

    // Start with Unprocessed Help Requests open.
    hide_requests();
    display_help_unprocessed();
  }

  return {
    init: init
  }

})();

$(document).ready(function() {
  VHL.RequestTasks.init();
});
