/* global VHL */


// The focus namespace
VHL.focus = VHL.focus || (function () {
  var visited = false;
  let fromStandardsSearch = false;

  var init = function () {
    _focus_click_event();

    // Variables for the Ajax Calls
    var auth_token = $('meta[name=csrf-token]').attr('content');
    var ajax_data = 'authenticity_token=' + encodeURIComponent(auth_token);

    $('.current_link').click(function(evt) {
      var link = $(this).attr('href');
      evt.preventDefault();
      update_course_list_with_current_courses(link);
    });

    $('.older_link').click(function (evt) {
      var link = $(this).attr('href');
      evt.preventDefault();
      update_course_list_with_old_courses(link);
    });

    $('.focus_old_courses_header').click(function() {
      $('.focus_old_courses_header a, #focus_current_courses_wrapper').toggle();
    });

    // If this function is defined (possibly some Assignment Calendar state)
    if (typeof warn_on_focus_change === 'function') {
      var prevFocusVal = $('#focus option').filter(':selected').attr('value');
      $('#update_focus_button').click(function(evt) {
        var ok = warn_on_focus_change();
        if (ok) {
          // If they say OK, go ahead and change focus
          return true;
        }

        // if not, reset form field to previous focus value
        $('#focus').val(prevFocusVal);
        evt.preventDefault();
        return false;
      });
    }

    // Load up data automatically if focused on an old course.
    var isCourseClosed = $('#focus_indicator').attr('data-js-course-closed');

    if (isCourseClosed === 'true') {
      var oldYearUrl = $('#focus_indicator').attr('data-js-old-year-path');
      VHL.focus.toggle_focus_show_older();
      $.get(oldYearUrl, function(data) {
        $('#focus_old_courses_list').html(data);
      });
    }

    // Functions for clicking current and older links
    var update_course_list_with_current_courses = function (link) {
      $.ajax({
        beforeSend: function beforeSend(request) {
          VHL.focus.toggle_focus_show_current();
        },
        complete: function complete(request) {
          VHL.focus.get_first_year();
        },
        success: function success(request) {
          $('#focus_old_courses_years').html(request);
        },
        data: ajax_data,
        type: 'get',
        url: link
      });
    };

    var update_course_list_with_old_courses = function(link) {
      $.ajax({
        beforeSend: function beforeSend() {
          VHL.focus.toggle_focus_show_older();
        },
        complete: function complete() {
          VHL.focus.per_year_selecter();
          VHL.focus.get_first_year();
        },
        success: function success(request) {
          $('#focus_old_courses_years').html(request);
        },
        data: ajax_data,
        type: 'get',
        url: link
      });
    };
  };

  var _year_dropdown_active = false;

  var _focus_year_dropdown = function() {
    $('#old_yearsSelectBoxItOptions').hover(
      function() {
        _year_dropdown_active = true;
      },
      function() {
        _year_dropdown_active = false;
      });
  };

  var _focus_click_event = function() {
    var _mouse_is_inside = false;

    var mouseInside = function() {
      _mouse_is_inside = true;
    };
    var mouseOutside = function() {
      _mouse_is_inside = false;
    };

    $('#focus_wrapper').hover(
      function() {
        _mouse_is_inside = true;
      },
      function() {
        _mouse_is_inside = false;
      });

    $('body').mouseup(function() {
      _focus_year_dropdown();
      if ((!_mouse_is_inside) && (!_year_dropdown_active)) {
        $('#focus_menu_container').hide();
      }
    });

    $('#focus_indicator').click(function() {
      $('#focus_menu_container').toggle();
    });
  };

  var set_focus_form_element = function(focusTarget) {
    var formmattedFocusTarget = _sentence_case(focusTarget.type);

    formmattedFocusTarget += ',' + focusTarget.id;
    $('#focus').val(formmattedFocusTarget);
  };

  var _sentence_case = function(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  };

  var update_focus = function(element) {
    function dismissDialog(dialog, disableBackgroundElm) {
      disableBackgroundElm.classList.add('u-dis-none');
      dialog.classList.add('u-hidden');
      return false;
    }

    function complete_update_focus() {
      var focusTarget = getFocusTargetFromElement(element);
      $('.js-loading-spinner').fadeIn();

      set_focus_form_element(focusTarget);
      // Submit focus form
      $('#update_focus').submit();
    }

    // Show a warning message if coming from the Standards-base assigning tool.
    if (this.fromStandardsSearch) {
      let dialog = document.querySelector('#focus-warning');
      let disableBackgroundElm = document.querySelector('.js-disable-background');

      dialog.classList.remove('u-hidden');
      disableBackgroundElm.classList.remove('u-dis-none');

      dialog.querySelector('#confirm-btn').addEventListener('click', () => {
        complete_update_focus();
        return false;
      });

      dialog.querySelector('#cancel-btn').addEventListener('click', () => {
        return dismissDialog(dialog, disableBackgroundElm);
      });

      dialog.querySelector('#close-btn').addEventListener('click', () => {
        return dismissDialog(dialog, disableBackgroundElm);
      });

      return false;
    }

    complete_update_focus();
    return false;
  };

  var update_focus_via_ajax = function(element, isSynchronous, beforeReq) {
    var focusTarget = getFocusTargetFromElement(element);
    set_focus_form_element(focusTarget);
    if (beforeReq === undefined) beforeReq = function(){};

    $.ajax({
      beforeSend: beforeReq,
      url: $('#update_focus').attr('action'),
      type: $('#update_focus').attr('method'),
      data: $('#update_focus').serialize(),
      dataType: 'json',
      async: !isSynchronous,
      success: update_focus_via_ajax_success
    });
  };

  var update_focus_via_ajax_success = function(response) {
    var _slicedToArray = function () {
      function sliceIterator(arr, i) {
        var _arr = [];
        var _n = true;
        var _d = false;
        var _e = undefined;

        try {
          for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {
            _arr.push(_s.value);

            if (i && _arr.length === i) break;
          }
        } catch (err) {
          _d = true;
          _e = err;
        } finally {
          try {
            if (!_n && _i["return"]) _i["return"]();
          } finally {
            if (_d) throw _e;
          }
        }

        return _arr;
      }

      return function (arr, i) {
        if (Array.isArray(arr)) {
          return arr;
        } else if (Symbol.iterator in Object(arr)) {
          return sliceIterator(arr, i);
        } else {
          throw new TypeError("Invalid attempt to destructure non-iterable instance");
        }
      };
    }();
    var _response$type_and_id = response.type_and_id.split(',');
    var _response$type_and_id2 = _slicedToArray(_response$type_and_id, 2);
    var focusTargetType = _response$type_and_id2[0];
    var focusTargetId = _response$type_and_id2[1];

    toggleFocusClasses($('.section_row, .course_header'), false);

    if (focusTargetType === 'Course') { // New focus is a course
      setFocusBoxText('All Sections');
      toggleFocusClasses($('#js_course_' + focusTargetId), true);
    } else { // New focus is a section
      setFocusBoxText(response.section_name);
      toggleFocusClasses($('#js_section_' + focusTargetId), true);
      setGradebookLinkToSection(focusTargetId);
    }
  };

  var setFocusBoxText = function(text) {
    var focusBox = $('.focus_indicator_names .focus_indicator_section, .focus_indicator_all_sections');
    focusBox.text(text);
  };

  var toggleFocusClasses = function($element, focus) {
    /**
     *  @param $element - a jQuery page element to apply focus / unfocus styles to
     *  @param focus - a boolean, true to focus the element, false to unfocus it
     */

    $element.toggleClass('is-active focused program-header-bar', focus)
      .toggleClass('neutral-header-bar bar-hover', !focus);
  };

  var get_first_year = function() {
    var setFirstYear = $('#old_years').val();
    display_closed_year();
  };

  var per_year_selecter = function() {
    $('#old_years').change(function() {
      display_closed_year();
    });
  };

  var display_closed_year = function() {
    var url = $('#old_years').val();
    $.get(url, function(data) {
      $('#focus_old_courses_list').html(data);
    });
  };

  var toggle_focus_show_current = function() {
    $('.focus_menu_old_courses').hide();
    $('.focus_menu_current_courses').show();
    $('.current_link').hide();
    $('.older_link').show();
  };

  var toggle_focus_show_older = function() {
    $('.focus_menu_old_courses').show();
    $('.focus_menu_current_courses').hide();
    $('.current_link').show();
    $('.older_link').hide();
  };

  var toggle_old_course_years_menu = function() {
    $('.old_courses_years').toggle();
  };

  var update_selected_old_course_year = function() {
    $('.selected_old_course_year').html($('.old_courses_years .selected').text().trim());
    // $('.old_courses_years').hide();
  };

  var setGradebookLinkToSection = function(sectionId) {
    /**
     * Takes a section ID and sets the gradebook link to the URL for that section
     * Assumes that the section is in the same course.
     * @param {string} sectionId - The id of the section we are focused on
     */

    var $gradebookLink = $('.js-gradebook-link');
    var courseId = $("[name='VHL.course_id']").attr('content');

    $gradebookLink.attr('href', gradebookSectionUrl(courseId, sectionId));
  };

  var gradebookCourseUrl = function(courseId) {
    /**
     * Takes the current URL and constructs a gradebook URL focused on a course
     * @param {string} courseId - The id of the course we should focus on
     * @returns {string} A URL in the following form:
     * https://m3a.vhlcentral.com/gradebook/{program ID}/courses/{course ID}
     */

    var baseUrl = window.location.href.split('.com')[0] + '.com/gradebook/';
    var programId = $("[name='VHL.program_id']").attr('content');
    return baseUrl + programId + '/courses/' + courseId;
  };

  var gradebookSectionUrl = function(courseId, sectionId) {
    /**
     * Takes the current URL and constructs a gradebook URL focused on a section
     * @param {string} sectionId - The id of the section we should focus on
     * @param {string} courseId - The id of the course for that section
     * @returns {string} A URL in the following form:
     * https://m3a.vhlcentral.com/gradebook/{program ID}/courses/{course ID}/sections/{section ID}
     */

    return gradebookCourseUrl(courseId) + '/sections/' + sectionId;
  };

  var getFocusTargetFromElement = function(element) {
    var parts = $(element).attr('id').split('_');
    var type = parts[1];
    var id = parts[2];
    return { id: id, type: type };
  };

  return {
    visited: visited,
    update_selected_old_course_year: update_selected_old_course_year,
    toggle_old_course_years_menu: toggle_old_course_years_menu,
    toggle_focus_show_older: toggle_focus_show_older,
    toggle_focus_show_current: toggle_focus_show_current,
    get_first_year: get_first_year,
    update_focus_via_ajax: update_focus_via_ajax,
    update_focus: update_focus,
    per_year_selecter: per_year_selecter,
    display_closed_year: display_closed_year,
    init: init
  };
}());

$(document).ready(function () {
  if (!VHL.focus.visited) {
    VHL.focus.init();
    VHL.focus.visited = true;
  }
});
