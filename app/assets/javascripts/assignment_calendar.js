var VHL = VHL || {}
VHL.AssignmentCalendar = (function() {

  function init() {
    initialize_selectboxes();
    bind_edit_filter_links();
    disable_strand_menu_and_component_menu_huh();
    enable_category_menu_and_week_menu();
    $('.focus_on_me').focus();
    set_correct_previous_section_filter_dropdown();
    VHL.AssignmentCalendar.set_activity_links();
    VHL.AssignmentCalendar.assign_activity_hover();
    bind_quick_selects();
  }

  function assign_activity_hover() {
    // Controls activity hover elements on Calendar Assigning page.
    var last_li;
    var hide_all_hovers = function() {
      if(last_li) {
        var hover = $('#hover_holder').find('.results_table_hover').appendTo(last_li);
        hover.addClass('hidden_helper');
        last_li = false;
      }
    };

    $('li.activity_item').
      mouseenter(function() {
        hide_all_hovers();
        last_li = $(this);
        var placement_left = last_li.position().left;
        var placement_top = last_li.position().top;
        var hover_container = last_li.find('.results_table_hover');

        hover_container.removeClass('hidden_helper');

        $('#hover_holder').append(hover_container);

        hover_container.css({
          'margin-left': placement_left + 180,
          'top': placement_top - 65
        });

      });

    $('#hover_group').
      mouseleave(function() {
        hide_all_hovers();
      });
  }

  function bind_edit_filter_links() {
    $('[data-js-link="toggle_filters_previous"]').click(function(e) {
      e.preventDefault();
      toggle_previously_assigned_filters();
    });

    $('[data-js-link="toggle_filters_location"]').click(function(e) {
      e.preventDefault();
      toggle_location_filters();
    });

    $('[data-js-link="toggle_filters_properties"]').click(function(e) {
      e.preventDefault();
      toggle_properties_filters();
    });

    $('[data-js-change="copy_previous"]').change(function() {
      disable_category_menu_and_week_menu_huh();
    });

    $('[data-js-change="filter_lesson"]').change(function() {
      var lesson = $(this).attr('data-js-lesson');

      update_strands_dropdown(lesson, 'assignment_filter_week');
      disable_strand_menu_and_component_menu_huh();
    });
  }

  function bind_quick_selects() {
    $('[data-js-link="quick_change"]').click(function() {
      var setting = $(this).attr('data-js-setting');
      var value = $(this).attr('data-js-value');
      select_value_and_submit(setting, value);
    });
  }

  function enable_category_menu_and_week_menu() {
    disable_sub_menus =  !$('#assignment_filter_previous_section_id option').filter(':selected').attr('value');
    $('#assignment_filter_category_id').attr('disabled', disable_sub_menus);
    $('#assignment_filter_week').attr('disabled',  disable_sub_menus);

    var category_filter = $('#assignment_filter_category_id');
    var week_filter = $('#assignment_filter_week');

    if ( !disable_sub_menus ) {
      category_filter.attr("disabled", false);
      week_filter.attr("disabled", false);
      
      var unwrap_category_and_week = ($('.disabled_element_wrapper #assignment_filter_category_id').length !== 0) &&
            ($('.disabled_element_wrapper #assignment_filter_week').length !== 0);
      if (unwrap_category_and_week) {
        $('#assignment_filter_category_id').unwrap();
        $('#assignment_filter_week').unwrap();
      }
    }
  }

  function disable_category_menu_and_week_menu_huh() {
    $('#assignment_filter_category_id').attr('disabled', true);
    $('#assignment_filter_week').attr('disabled', true);

    var category_filter = $('#assignment_filter_category_id');
    var week_filter = $('#assignment_filter_week');

    category_filter.attr("disabled", true);
    week_filter.attr("disabled", true);
    
    $('#assignment_filter_category_id').wrap('<div class="disabled_element_wrapper" rel="#section_disabled_explanation" />');
    $('#assignment_filter_week').wrap('<div class="disabled_element_wrapper" rel="#section_disabled_explanation" />');
    $('.disabled_element_wrapper').each(function() {
      make_cluetip(this);
    });
  }

  function disable_strand_menu_and_component_menu_huh() {
    var disable_sub_menus = !$('#assignment_filter_lesson_id option').filter(':selected').attr('value');
    $('#assignment_filter_toc_entry_location').attr('disabled', disable_sub_menus);
    $('#assignment_filter_component').attr('disabled', disable_sub_menus);

    var section_filter = $('#assignment_filter_toc_entry_location');
    var component_filter = $('#assignment_filter_component');

    if (disable_sub_menus) {
      section_filter.attr("disabled", true);
      component_filter.attr("disabled", true);

      $('#assignment_filter_component').wrap('<div class="disabled_element_wrapper" rel="#disabled_explanation" />');
      $('#assignment_filter_toc_entry_location').wrap('<div class="disabled_element_wrapper" rel="#disabled_explanation" />');
      $('.disabled_element_wrapper').each(function() {
        make_cluetip(this);
      });
    } else {
      section_filter.attr("disabled", false);
      component_filter.attr("disabled", false);

      var unwrap_strand_and_component = ($('.disabled_element_wrapper #assignment_filter_component').length !== 0) &&
            ($('.disabled_element_wrapper #assignment_filter_toc_entry_location').length !== 0);
      if (unwrap_strand_and_component) {
        $('#assignment_filter_component').unwrap();
        $('#assignment_filter_toc_entry_location').unwrap();
      }
    }
  }

  function get_selected_activities() {
    var checked = new Array();
    $('.activity_selector').each(function() {
      if ($(this).is(':checked')) {
        checked.push($(this).val());
        $(this).prop('checked', '');
      }
    });
    return checked.join(',');
  }

  function initialize_selectboxes() {
    $('#assignment_filter_category_id').removeClass('hidden_helper');
    $('#assignment_filter_week').removeClass('hidden_helper');

    $('#assignment_filter_toc_entry_location').removeClass('hidden_helper');
    $('#assignment_filter_component').removeClass('hidden_helper');
  }

  function make_cluetip(item) {
    $(item).cluetip({
      local: true,
      showTitle: false,
      cursor: 'pointer',
      topOffset: 0,
      delayedClose: 5000
    });
  }

  function prev_section_select_value_and_submit(select_id, value) {
    $('#spinner').show();
    $('#' + select_id).val(value);
    $('#assignment_filter_week').val('');
    $('form.edit_assignment_filter').submit();
  }

  function reset_week_selector() {
    $('#assignment_filter_week').val("");
  }

  function selected_activities_update(link) {
    var sa = get_selected_activities();
    if (sa.length === 0) {
      alert('No activities selected!');
      return false;
    } else {
      var new_href = $(link).attr('href').split('&selected_activities=');
      $(link).attr('href', new_href[0] + '&selected_activities=' + sa)
    }
    return true;
  }

  function select_value_and_submit(select_id, value) {
    $('#spinner').show();
    $('#' + select_id).val(value);
    $('form.edit_assignment_filter').submit();
  }

  function set_activity_links() {
    // Makes activity links on Calendar Assigning page have popups to preview the activity.
    $('a.activity_link').click(function(event) {
      event.preventDefault();
      var linkref = $(this).attr('href');
      var w = window.open(linkref, '', 'directories=no, height=600, location=no, menubar=no, resiable=yes, scrollbars=yes, status=yes, toolbar=no, width=1000');
      w.focus();
      return false;
    });
  }

  function set_correct_previous_section_filter_dropdown() {
    var current_section = $('#current_section_filter_section_id').html();
    if (current_section.length > 0) {
      $('#assignment_filter_previous_section_id option').each(function() {
        if ($(this).val() === current_section) {
          $(this).attr('selected', 'selected');
        }
      });
    } else {
      $('#assignment_filter_previous_section_id option:first').attr('selected', 'selected');
    }
  }

  function toggle_location_filters() {
    $('#location .filter_options').toggleClass('hidden_helper');
    $('#location .filter_links').toggleClass('hidden_helper');

    $('#location div.edit_summary_sentence').toggle();
    $('#location span.summary_sentence').toggle();

    $('#location').toggleClass('focused');

    $('#previously_assigned').toggleClass('faded');
    $('#previously_assigned').find('.disabled').toggleClass('hidden_helper');

    $('#properties').toggleClass('faded');
    $('#properties').find('.disabled').toggleClass('hidden_helper');
  }

  function toggle_previously_assigned_filters() {
    $('#previously_assigned .filter_options').toggleClass('hidden_helper');
    $('#previously_assigned .filter_links').toggleClass('hidden_helper');

    $('#previously_assigned div.edit_summary_sentence').toggle();
    $('#previously_assigned span.summary_sentence').toggle();

    $('#previously_assigned').toggleClass('focused');

    $('#properties').toggleClass('faded');
    $('#properties').find('.disabled').toggleClass('hidden_helper');

    $('#location').toggleClass('faded');
    $('#location').find('.disabled').toggleClass('hidden_helper');
  }

  function toggle_properties_filters() {
    $('#properties .filter_options').toggleClass('hidden_helper');
    $('#properties .filter_links').toggleClass('hidden_helper');

    $('#properties div.edit_summary_sentence').toggle();
    $('#properties span.summary_sentence').toggle();

    $('#properties').toggleClass('focused');

    $('#location').toggleClass('faded');
    $('#location').find('.disabled').toggleClass('hidden_helper');

    $('#previously_assigned').toggleClass('faded');
    $('#previously_assigned').find('.disabled').toggleClass('hidden_helper');

    var assignment_type = $('#assignment_filter_activity_type');

    if ($('#assignment_filter_content_type').val() === "Assessment") {
      assignment_type.attr("disabled", true);
    }

    $('#assignment_filter_content_type').change(function() {
      if ($('#assignment_filter_content_type').val() === "Assessment") {
        assignment_type.attr("disabled", true);
      } else {
        assignment_type.attr("disabled", false);
      }
    });
  }

  function update_strands_dropdown(lesson_id, update_ele_id) {
    override_lesson_id = $('#assignment_filter_lesson_id option').filter(':selected').attr('value');
    if(override_lesson_id !== ""){
      $.ajax({
        url: '/lessons/' + lesson_id + '/strands',
        method: 'get',
        data: 'override_lesson_id=' + override_lesson_id,
        success: function(data) {
          $('#' + update_ele_id).html(data);
        }
      });
    }
  }

  function update_weeks_dropdown(update_ele_id) {
    var section_id = $('#assignment_filter_previous_section_id option').filter(':selected').attr('value');
    if(section_id !== ""){
      $.ajax({
        url: '/sections/' + section_id + '/weeks_covered',
        method: 'get',
        success: function(data) {
          $('#' + week_update_ele_id).html(data);
        }
      });
    }
  }

  function warn_on_focus_change() {
    var section_id = $('#current_section_filter_section_id').html();
    var section_pattern = /Section,\d+/;
    var focus_section = $('#focus').val().match(section_pattern);
    var focus_id;
    if (focus_section) {
      focus_id = focus_section.toString().match(/\d+/);
      if (focus_id === section_id) {
        var ok = confirm('Your filter "previously assigned" will be reset if you change to this section.');
        $('#assignment_filter_previous_section_id').val('');
        $('#assignment_filter_week').val('');
        $('form.edit_assignment_filter').submit();
        return ok;
      } else {
        return true;
      }
    } else {
      return true;
    }
  }

  return {
    init: init,
    set_activity_links: set_activity_links,
    assign_activity_hover: assign_activity_hover,
    prev_section_select_value_and_submit: prev_section_select_value_and_submit,
    select_value_and_submit: select_value_and_submit
  }
})();

$(document).ready(function() {
  VHL.AssignmentCalendar.init();
});

$(window).load(function(){
  $('a.menu_icon').each(function(){
    $(this).cluetip({  activation: 'click',
                       cursor: 'pointer',
                       sticky: true,
                       closeText: '',
                       local: true,
                       mouseOutClose: true,
                       showTitle: false,
                       arrows: false,
                       width: 190,
                       leftOffset: -80,
                       dropShadow: false
                    });
  });
});
