/**
 * Js class to handle events on student assessment page
 */

VHL = VHL || {};

VHL.AssessmentPage = class AssessmentPage {
  constructor() {
    this._addNavTabHandler();
  }

  /**
   * handle click event on selected tab button
   * @param {Jquery Object} $tabButton - Clicked Tab button 
   */
  _navTabHandler($tabButton) {
    let selectedTabContent = $tabButton.data('tab-content-target');
    let $contentElement = $('.' + selectedTabContent);
    
    $('.js-tab-button').removeClass('is-selected').attr("aria-selected", false);
    $tabButton.addClass('is-selected').attr("aria-selected", true);

    // Hide content of previously selected tab and show content of selected tab
    $('.js-tabset__content').removeClass('is-selected');
    $contentElement.addClass('is-selected');
  }

  /**
   * Attach click handler to navigation tabs
   */
  _addNavTabHandler() {
    this._navTabHandler($('.js-tab-button').first());
    $('.js-tab-button').click((event) => {
      this._navTabHandler($(event.currentTarget));
    });
  }
}

$(document).ready(function(){
  new VHL.AssessmentPage();
});
