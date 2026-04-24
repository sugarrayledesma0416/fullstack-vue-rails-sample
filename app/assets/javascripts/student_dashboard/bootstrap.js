var VHL = VHL || {};

VHL.StudentDashboard = angular.module('student_dashboard_app', []);

VHL.NewStudentDashBoard = (function() {
  function init() {
    load_summary();
    attach_tabs();
    load_due_dates();
    bind_start_buttons();
  }

  function duedate_expander_handler_wrapper() {
    due_date_expander_handler(this);
  }

  function due_date_expander_handler(ele) {
    var _ele = $(ele.closest("li"));

    /**
     * If element is already expanded then collapse the element.
     */
    if(!_ele.hasClass('is-expanded')){
      // Collapse open blocks
      let $dueDate = $('.js-due-date');
      _collapseDueDate($dueDate);

      var url = $(_ele).data('duedate-url');
      $.ajax({
        url: url,
        type: 'GET',
        dataType: 'html',
        complete: function (jqXHR, textStatus) {
        },
        success: function (htmlresp, textStatus, jqXHR) {
          $(_ele).find('.js-strands-container').html(htmlresp).removeClass('u-hidden');
          $(_ele).addClass('is-expanded');
          $(_ele).find('.js-duedate-expander').attr('aria-expanded', true);
          bind_start_buttons(_ele);
        },
        error: function (jqXHR, textStatus, errorThrown) {
          $(_ele).find('.js-strands-container').html("<span> Data load failed.</span>");
          // error callback
        }
      });
    }
    else{
      // In case not collapse the open block
      _collapseDueDate($(_ele));
    }
  }

  // Collapse due date block and set appropriate ARIA
  function _collapseDueDate($element) {
    if ($element) {
      $element.removeClass('is-expanded');
      $element.find('.js-duedate-expander').attr('aria-expanded', false);
      $element.find('.js-strands-container').addClass('u-hidden');
    }
  }

  function load_summary() {
    $('.js-past-tab-button').click(function() {
      if (!$('.js-past-tab').find('.js-summaries').length) {
        url = $('.js-past-tab').data('past-summaries-url');
        $.ajax({
          url: url,
          type: 'GET',
          dataType: 'html',
          complete: function (jqXHR, textStatus) {
          },
          success: function (htmlresp, textStatus, jqXHR) {
            $('.js-past-tab').html(htmlresp);
            const dueDateExpander = $('.js-past-tab').find('.js-duedate-expander')
            dueDateExpander.click(duedate_expander_handler_wrapper);
            dueDateExpander.keydown(function(event){
              /**
               * Keyboard handling for enter and spacebar key.
               */
              if(event.keyCode === 13 || event.keyCode === 32){
                duedate_expander_handler_wrapper.call(this);
                event.preventDefault();
              }
            });
            bind_start_buttons();
            _setToggleListLabel();
          },
          error: function (jqXHR, textStatus, errorThrown) {
            $('.js-past-tab').html("<span> Data load failed.</span>");
            // error callback
          }
        });
      }
    });
  }

  function load_due_dates() {
    $('.js-duedate-expander').click(function() {
        due_date_expander_handler(this);
    }).keydown(function(event){
      /**
       * Keyboard handling for enter and spacebar key.
       */
      if(event.keyCode === 13 || event.keyCode === 32){
        due_date_expander_handler(this);
        event.preventDefault();
      }
    });
  }

  function attach_tabs() {
    $('.js-future-tab-button').addClass('is-selected-tab');
    $('.js-future-tab').addClass('is-selected-tab-content');
    _setToggleListLabel();

    $('.js-tab-button').click(function() {
      var $tab_button = $(this);
      var newContentClass = $tab_button.data('content-target');
      $('.js-tab-button').removeClass('is-selected-tab').attr("aria-selected",false);
      $('.js-tab').removeClass('is-selected-tab-content');
      $tab_button.addClass('is-selected-tab').attr("aria-selected",true);
      $('.' + newContentClass).addClass('is-selected-tab-content');
      _setToggleListLabel();
    });
    // Toggle due date lists - display/hide all due dates (except first) when user clicks on "Show/Hide future due dates"
    $('.js-toggle-due-date-list').click(function () {
      _toggleDueDates();
    });
  }

  /**
   * This function originally was in the old chat_client gem:
   *
   * https://github.com/vhl/chat_client/blob/master/app/assets/javascripts/partner_chat/utils.js#L218-L234
   */
  function parse_location(url) {
    var anchor = document.createElement("a");
    anchor.href = url;
    return {
      protocol : anchor.protocol,
      hostname : anchor.hostname,
      host : anchor.host,
      hash : anchor.hash,
      pathname : anchor.pathname,
      port : anchor.port,
      search : anchor.search
    };
  }

 /**
 * Formulates workset urls and
 * binds click handlers to start buttons
 *
 * @param {elm} html_reference Optional. The container for the group of due date
 * activity that was just loaded.
 */
  function bind_start_buttons(elm) {
    /**
     * bind_start_buttons is called either on page load with no arguments,
     * or from due_date_expander_handler success callback
     * with one argument. If the argument (html reference) is present,
     * we want to initialize only the button for the due dates
     * that we just loaded. Otherwise, initialize any present start button.
     */
    var $element_list = elm ? $(elm).find('[data-js-workset-path]') : $('[data-js-workset-path]');
    $element_list.each(function(){
      var $this = $(this);

      /* make url for workset */
      var location = parse_location();
      var workset_path = location.protocol + "//"
            + location.host
            + $this.data().jsWorksetPath;

      $this.click(function(e) {
        window.location.href = workset_path;
      });
    });
  }

  /**
   * Show/ Hide due dates list
   */
  function _toggleDueDates() {
    let $selectedTab = $('.is-selected-tab-content');
    // Get list of all due dates other than the first one
    let $dueDateList = $selectedTab.find('.js-due-date:not(:first-child)');
    $dueDateList.toggleClass('u-hidden');
    _setToggleListLabel();
  }

  /**
   * update show/hide label
   */
  function _setToggleListLabel() {
    let $selectedTab = $('.is-selected-tab-content');
    let $dueDateList = $selectedTab.find('.js-due-date');
    if ($dueDateList.length == 0) {
      $('.js-toggle-due-date-list').text('No due dates available');
    } else if ($dueDateList.length == 1) {
      $('.js-toggle-due-date-list').text('No more due dates').attr('disabled', true);
    } else {
      let isHidden = $dueDateList.hasClass('u-hidden');
      let $toggleLabel = $('.js-toggle-due-date-list');

      if (isHidden) {
        $toggleLabel.text('Show more due dates');
      } else {
        $toggleLabel.text('Hide due dates');
      }
    }
  }

  return {
    init: init,
  };

})();



$(document).ready(function(){
  VHL.NewStudentDashBoard.init();
});
