var VHL = VHL || {}

VHL.InstructorSectionWizard = (function() {

  function init() {
    set_section_name();
    bind_class_days();
    bind_section_steps();
    prep_unobstrusive_javascript();
    toggle_section_details();
  }

  function bind_class_days() {
    $('.toggle_class_day').each(function() {
      update_class_days($(this));
    });

    $('.toggle_class_day').on("click", function() {
      update_class_days($(this));
    });
  }

  function bind_section_steps() {
    $('[data-js-step]').click(function() {
      var link = $(this);
      var step = $(this).attr('data-js-step');
      jump_to_section_step(link, step);
    });
  }

  function closePop(fn) {
    var arglength = arguments.length;
    if ($(".pop").length === 0) {
      return false;
    }
    $(".pop").slideFadeToggle(function() {
      if (arglength) {
        fn.call();
      }
      $(this).remove();
    });
    return true;
  }

  function hide_section_details() {
    $("div[type=popup]").each(function() {
      $(this).css("display", "none");
    });
  }

  function jump_to_section_step(element, step_name) {
    $('#jump_to_step').val(step_name);
    $('#new_section').submit();
  }

  function prep_unobstrusive_javascript() {
    $('a.jquery_modal').unbind('click').bind('click', function() {
      $('<div />').appendTo('body').dialog({
        title: $(this).attr('title'),
        modal: true
      }).load($(this).attr('href') + ' form', function() {
        var $form = $(this).find('form');
        var $btn = $form.find(':submit');
        var txt = $btn.val();
        $form.find(':text:first').focus();
        $btn.remove();
        var buttons = {};
        var dlg = $(this);
        buttons[txt] = function() {
          $.ajax({
            type: $form.attr('method'),
            url: $form.attr('action'),
            data: $form.serialize(),
            dataType: 'script',
            success: function(xhr, status) {
              dlg.dialog('close');
              window.location.reload();
            },
            error: function(data) {
              var errors = $.parseJSON(data.responseText);
              var error_div = $form.find('#jquery_modal_error_status');
              if (error_div.length === 0) {
                $form.prepend('<div id="jquery_modal_error_status" class="ui-state-error ui-corner-all">' + errors.errors_message_block + '</div>');
              } else {
                error_div.html(data.responseText);
              }
            }
          });
        };
        $(this).dialog('option', 'buttons', buttons );
        VHL.Common.initialize_datepicker();
      });
      return false;
    });

    $('a.jquery_remove').unbind('click').bind('click', function(event) {
      if (event.button !== 0) {
        return true;
      }

      var link = $(this);
      link.addClass("selected").parent().append("<div class='pop delpop'><p>Are you sure?</p><p><input type='button' value='Yes' /> or <a href='#' class='popclose'>Cancel</a></div>");
      $(".delpop").slideFadeToggle();

      $(".delpop input").click(function() {
        $(".pop").slideFadeToggle(function() {
          $.post(link.attr('href').substring(0, link.attr('href').indexOf('/confirm_delete')), { _method: "delete" },
          function(response) {
            link.prev("input[type=hidden]").val(1);
            link.parents(".new_record").remove();
            link.parents(".existing_record").hide();
          });
          $(this).remove();
        });
      });
      return false;
    });

    $(".popclose").live('click', function() {
      return !closePop();
    });
  }

  function set_section_name() {
    $('.add_section #section_name').focus(function() {
      if (this.value === 'New section') {
        this.value = '';
      }
    }).blur(function() {
      if (this.value === '') {
        $(this).val("New section");
      }
    });
  }

  function show_section_details(section_id) {
    hide_section_details();
    $("div[id=popUp_" + section_id + "]").each(function() {
      $(this).css('left', '120px');
      $(this).css('display', 'block');
    });
  }

  function toggle_section_details() {
    $('.moreInfo').mouseover(function() {
      var section_id = $(this).attr('data-js-section');
      show_section_details(section_id);
    }).mouseout(function() {
      hide_section_details();
    });
  }

  function update_class_days(day) {
    // Get the data-js of today's week day to match against the days in the calendar.
    // Then parse out the rest of the word, keeping just the first three letters.
    var today = day.data('js-day-name');
    today = today.substring(3, 0);

    // Match the clicked day to the calendar column.
    var class_day = $('[data-js-weekday=' + today + ']');

    // Check state of this day's checkbox.
    if (day.is(':checked')) {
      class_day.addClass("class_day");
    } else {
      class_day.removeClass("class_day");
    }
  }

  return {
    init: init,
    jump_to_section_step: jump_to_section_step,
    update_class_days: update_class_days
  };

})();

VHL.SectionCopy = (function() {
  function init() {
    bind_update_changes();
    initialize_dropdowns();
    initialize_defaults();
  }

  function bind_update_changes() {
    update_instructor_change();

    $('.instructor_role select').change(function() {
      update_instructor_change();
    });

    $('#section_name').keyup(function() {
      update_change('section_name');
    });

    $('#section_additional_info').keyup(function() {
      update_change('section_additional_info');
    });

    $('#section_name').change(function() {
      update_change('section_name');
    });

    if ($('div.c-message--error li').length !== 0) {
      update_change('section_name');
      update_change('section_additional_info');
    }
  }

  function build_instructor_list(instructor_list) {
    if (instructor_list.length === 1) {
      return "<span class='single'>" +  instructor_list[0] + "</span>";
    } else {
      return $.map(instructor_list, function(name) { return ("<span class='multiple'>" +  name + "</span>"); }).join("");
    }
  }

  function class_days_step(selected_section_id, selected_section_xpath) {
    var updated_class_days = $(selected_section_xpath + " .class_days").text();
    var selected_days = updated_class_days.split(',')
    $('span.day_selector>input').removeAttr('checked');
    $.each(selected_days, function(index, day) {
      $('input#class_days_' + day).prop('checked', true);
    });

    $('.toggle_class_day').each(function() {
      VHL.InstructorSectionWizard.update_class_days($(this));
    });

  }

  function holidays_step(selected_section_id, selected_section_xpath) {
    var program_id = $('#program_id').val();
    var course_id = $('#course_id').val();
    var replace_path = '/instructor/' + program_id + '/courses/' + course_id + '/events/' + selected_section_id;
    $.post(replace_path);
  }

  function initialize_defaults() {
    if ($('#section_completed').val() === 'section_not_completed') {
      set_section_defaults();
    }

    $('#previous_section_id').change(function() {
      set_section_defaults();
    });
  }

  function initialize_dropdowns() {
    $('#previous_section_id').change(function() {
      $("label[for='previous_section_id']").text('Settings modified from');
    });

    $('#due_time_hour').addClass('time');
    $('#due_time_min').addClass('time');
    $('#due_time_ampm').addClass('time');
  }

  function section_information_step(selected_section_id, selected_section_xpath) {
    var section_name = $("#section_name").val();
    if (section_name === "") {
      section_name = 'New section';
    }

    $("#section_name").attr('value', section_name);

    var updated_additional_info = $(selected_section_xpath + " .additional_info").text();
    $("#section_additional_info").attr('value', updated_additional_info);

    var updated_time_zone = $(selected_section_xpath + " .time_zone").text();
    // Don't update time zone selection if the previous section's time zone is nil
    if (updated_time_zone !== '') {
      var section_time_zone = $("select#section_time_zone");
      section_time_zone.val(updated_time_zone);
    }

    updated_due_time = new Date($(selected_section_xpath + " .due_time").text());

    // Retrieve the current hours and minutes from the Previous Section
    var current_hour = twentyfourhours_to_ampm(updated_due_time.getUTCHours());
    var current_minutes = updated_due_time.getUTCMinutes() == 0 ? '00' : '' + updated_due_time.getUTCMinutes();
    var current_time = updated_due_time.getUTCHours() < 12 ? 'AM' : 'PM';

    // Set each Time select to use the Previous Section's Time.
    var date_hour_select = $("select#due_time_hour");
    date_hour_select.val(current_hour);

    var date_min_select = $("select#due_time_min");
    date_min_select.val(current_minutes);

    var date_time_select = $("select#due_time_ampm");
    date_time_select.val(current_time);

    update_change('section_name');
    update_change('section_additional_info');
    update_instructor_change();
  }

  function set_section_defaults() {
    var selected_section_id = $("select#previous_section_id option:selected").attr('value');

    if (selected_section_id === '') {
      switch ($('.section_wizard_progress_steps .current')[0].id) {
        case 'section_information':
          $("#section_name").attr('value', 'New section');
          $("#section_additional_info").attr('value', '');

          var date_hour_select = $("select#due_time_hour");
          date_hour_select.val('11');

          var date_min_select = $("select#due_time_min");
          date_min_select.val('59');

          var date_time_select = $("select#due_time_ampm");
          date_time_select.val('PM');

          var section_timezone = $("select#section_time_zone");
          var current_timezone = $('select#section_time_zone').find('option[selected]').val();
          section_timezone.val(current_timezone);
          break;
        case 'class_days':
          $('span.day_selector>input').removeAttr('checked');
          break;
        case 'holidays': break;
      }
    } else {
      selected_section_xpath = "div[class='previous_section[" + selected_section_id + "]']";
      switch ($('.section_wizard_progress_steps .current')[0].id) {
        case 'section_information': section_information_step(selected_section_id, selected_section_xpath); break;
        case 'class_days': class_days_step(selected_section_id, selected_section_xpath); break;
        case 'holidays': holidays_step(selected_section_id, selected_section_xpath); break;
      }
    }
  }

  function twentyfourhours_to_ampm(hour) {
    if (hour == 0 || hour == 12) {
      return 12;
    }
    if (hour > 0 && hour < 12) {
      return hour;
    }
    if (hour > 13) {
      return (hour - 12);
    }
  }

  function update_change(section_info_type){
    var section_id = $('#section_id').val();
    $("span#" + section_info_type + "_" + section_id).each(function() {
      var new_value = $('#' + section_info_type).val();
      new_value = (section_info_type === 'section_name' && new_value.length > 10 ? new_value.substring(0, 10) + '&hellip;' : new_value);
      $(this).html(new_value);
    });
    $("span#" + section_info_type + "_" + section_id + '_detailed').each(function() {
      $(this).html($('#' + section_info_type).val());
    });
    $("label#" + section_info_type + "_" + section_id).each(function() {
      var new_value = $('#' + section_info_type).val();
      new_value = (section_info_type === 'section_name' && new_value.length > 10 ? new_value.substring(0, 10) + '&hellip;' : new_value);
      $(this).html(new_value);
    });
  }

  function update_instructor_change(){
    var section_id = $('#section_id').val();
    var instructor_list = [$('#section_instructors_'+ section_id).attr('data-owner-name')];
    $('.additional_instructor').each(function(){
      var selected_role = $(this).children('.instructor_role').children('select').val();
      if (selected_role !== '' && selected_role !== 'Assistant') {
        var last_name = $(this).children('.instructor_name').text().replace(/^[a-zA-Z]+/,'');
        instructor_list.push(last_name);
      }
    });
    $('label#section_instructors_' + section_id).each(function() {
      $(this).html(build_instructor_list(instructor_list));
    });
  }

  return {
    init: init
  };

})();

$.fn.slideFadeToggle = function(easing, callback) {
  return this.animate({opacity: 'toggle', height: 'toggle'}, "fast", easing, callback);
};

$(document).ready(function() {
  VHL.InstructorSectionWizard.init();
  VHL.SectionCopy.init();
});
