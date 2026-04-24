var VHL = VHL || {}
VHL.EventCalendar = (function() {

  function init() {
    calendar_spacing();
    bind_month_change();
    prep_common_event_jquery_modal_local(175, 550);
    $('ul.calendar li.week:nth-child(2)').addClass('first_week');
    window.addEventListener("resize", calendar_spacing);
    init_show_more_activities();
  }

  function bind_month_change() {
    $('[data-js-link="show_calendar"]').click(function(event) {
      event.preventDefault();
      var month = $(this).attr('data-js-month');
      show_calendar(month, this);
    });
  }

  function calendar_spacing() {
    if ($('body').hasClass('ns-calendar')) {
      var $all_weeks = $('.week'); /* grab each week li*/
      var day_height = 0; /*set var to use for the day height*/
      var items_height = 0;
      var tallest_day;

      $all_weeks.each(function() {
        $days = $(this).find('li.day');  /* save all li.day into a jquery selection */
        $days.each(function() {
          if (day_height < parseInt($(this).css('height'))) {
            day_height = parseInt($(this).css('height')); /* go through each day in the week and find tallest height */
            tallest_day = $(this);
          }
          if (items_height < parseInt($(this).find('.items_daily').css('height'))) {
            items_height = parseInt($(this).find('.items_daily').css('height'));
          }
        });
        $days.each(function() {
          $(this).css('height', day_height);

          if ($('body').hasClass('calendar')) {
            $(this).find('.items_daily').css('height', items_height);
            /* Reset size of tallest cell so it recalculates on window resize */
            tallest_day.css('height', '');
            tallest_day.find('.items_daily').css('height', '');
          } else if ($('body').hasClass('assignment_page')) {
            $(this).find('.daily').css('height', 70);
          }
        });
        day_height = 0;
        items_height = 0;
      });
      /* Sets the days in the week containing today to have the proper height */
      $days.each(function() {
        $(this).find('.today');
        $('.today').siblings('.day').addClass('this_week');
      });
    }
  }

  function prep_common_event_jquery_modal_local(min_height, width, grab_params) {
    $('a.event_jquery_modal').unbind('click').bind('click', function() {
      $('#calendar_modal_box').dialog({
        title: $(this).attr('title'),
        minHeight: min_height,
        modal: true,
        position: 'top',
        resizable: false,
        width: width,
        open: function (e, ui) {
          $('#calendar_modal_box').append("<div id='modal_spinner' style='position:absolute;top:15%;left:40%;'><img alt='page loading' src='/loading_32.gif'/></div>");
        },
        close: function (e, ui) {
          $('#calendar_modal_box form').remove();
          $('#js_read_only_dialog_body').remove();
          $('div.ui-dialog-buttonpane').remove();
        }
      }).load($(this).attr('href'), '', function() {
          var dlg = $(this);
          $('#modal_spinner').remove();
          $(this).find('form').each(function() {
            $(this).find(':text:first').not('.has_datepicker').focus();
            var $btn = $(this).find(':submit');
            var $form = $(this);
            var txt = $btn.val();
            $btn.remove();

            var buttons = {};
            buttons[txt] = function() {
              if (typeof confirmation !== 'undefined') {
                if (!confirm(confirmation)) {
                  dlg.dialog('close');
                  return false;
                }
              }
              $.ajax({
                type: $form.attr('method'),
                url: $form.attr('action'),
                data: $form.serialize(),
                dataType: 'script',
                beforeSend: function(xhr, status) {
                  $('#modal_spinner').remove();
                  $('#calendar_modal_box').append("<div id='modal_spinner' style='display:none;position:absolute;top:15%;left:35%;'><img alt='page loading' src='/images/loading_32.gif'/></div>");
                  $('#modal_spinner').show();
                },
                success: function(xhr, status) {
                  $('#modal_spinner').hide();
                  $('input:checkbox[name="selected_activities[]"]:checked').each(function(index) {
                    $(this).removeAttr("checked");
                  });
                  dlg.dialog('close');
                  var top = $(window).scrollTop();
                  $('#spinner').css('top', top + 'px');
                  $('#spinner').show();
                  window.location.reload();
                },
                error: function(data) {
                  $('#modal_spinner').hide();
                  var errors = $.parseJSON(data.responseText);
                  if (errors) {
                    VHL.Common.set_error_class_for_fields(errors.fields_with_errors);
                    var error_div = $form.find('#jquery_modal_error_status');
                    if (error_div.length === 0) {
                      $form.prepend('<div id="jquery_modal_error_status" class="ui-state-error ui-corner-all">' + errors.errors_message_block + '</div>');
                    } else {
                      error_div.html(errors.errors_message_block);
                    }
                  }
                }
              });
            };

            function toggle_checkbox(element, check_all) {
              element.toggleClass('show_check', check_all);
              element.parents('tr').toggleClass('highlight_bg', check_all);

              if ($('.student_checkbox.show_check').length === 0) {
                $('#set_due_date_link').hide();
              } else {
                $('#set_due_date_link').show();
              }

              var selected_assignment_ids = new Array();
              $('.student_checkbox.show_check').each(function() {
                var assignment_id = this.id.replace("assignment_id_", "").replace("_checkbox", "");
                selected_assignment_ids.push(assignment_id);
              });

              $('input#selected_assignments').attr('value', selected_assignment_ids.join(','));
            }

            $('.checkbox_all').bind('click', function() {
             var check_all = !$(this).hasClass('show_check');
             var component_class = $(this).attr('rel');
             $(this).toggleClass('show_check');
             $('.student_checkbox.' + component_class).each(function() {
               toggle_checkbox($(this), check_all);
             });
            });

            $('.student_checkbox').bind('click', function() {
              toggle_checkbox($(this));
            });

            $(dlg).dialog('option', 'buttons', buttons);
            VHL.Common.move_jquery_modal_delete_link_into_button_pane();
            VHL.Common.initialize_datepicker();
          });
      });
      return false;
    });
  }

  function show_calendar(year_month, buttonClicked) {
    if (year_month.length > 0) {
      var container_id = $('.js-calendar_page').parent().attr('id');
      var ajax_url = VHL.Common.build_ajax_url('/event_calendar/' + year_month);
      //this if is needed to defferentiate the section edit wizard from the section new wizard
      //we want to match for a special case on the holiday step on the section edit wizard
      if (ajax_url.match(/sections\/\d+/) !== null && ajax_url.match(/sections\/\d+\/edit/) === null && ajax_url.match(/study_schedule/) === null ){
        ajax_url = ajax_url.replace('event_calendar', 'edit/event_calendar');
      }
      $.ajax({
        type: "get",
        url: ajax_url,
        beforeSend: function(xhr, status) {
          $('#calendar_spinner').remove();
          $('#month_controls').append(`<div id='calendar_spinner'
                                            style='display:none;position:absolute;top:15%;left:35%;'>
                                          <img alt='loading...' src='/images/loading_32.gif' />
                                        </div>`);
          $('#calendar_spinner').show();
        },
        success: function(response) {
          $('#calendar_spinner').remove();
          $("#" + container_id).html(response);
          prep_common_event_jquery_modal_local(175, 550);
          calendar_spacing();
          bind_month_change();

          var linkToFocus = $("#" + container_id + " a.disabled_cal_nav")
          
          // Search and focus the <a> element with class 'disabled_cal_nav' if exists
          if (linkToFocus.length > 0) {
            linkToFocus.focus();
          } else {
            // Focus the clicked button if no link is found
            var clickedButtonId = $(buttonClicked).attr('id')
            $(`#${clickedButtonId}`).focus()
          }

          if ($('body').hasClass("add_section") || $('body').hasClass("edit_section")) {
            $('.toggle_class_day').each(function() {
              VHL.section_wizard.update_class_days($(this));
            });
          } else {
            VHL.AddAssignments.activityHoverInformation();
          }
        }
      });
    }
    $('ul.calendar li.week:nth-child(2)').addClass('first_week');
  }

  function init_show_more_activities() {
    $('#show_more_activities').on('click', function(e) {
      e.preventDefault();
      show_more_activities();
    });
  }

  function show_more_activities() {
    var ajax_url = VHL.Common.build_ajax_url('show_more').replace(/new\//, '');
    var current_activities_count = $('#service_current_activities_count').attr('current_activities_count');

    var already_checked_boxes = new Array();

    // Display "Loading" Message
    $('#unassigned_activities_list').append("<div id='show_more_spinner'><img alt='page loading' src='/images/loading_32.gif'/><span class='showing_more'>Loading more activities...</span></div>");

    // Scroll to Bottom of Div
    var objDiv = document.getElementById("unassigned_activities_list");
    objDiv.scrollTop = objDiv.scrollHeight;

    // Persist Position for after Load
    var scroll_placement = $('.unassigned_activities_list').scrollTop();

    $('.show_check').each(function() {
      already_checked_boxes.push($(this).attr('id'));
    });

    $("#unassigned_activities").load(
      ajax_url,
      'current_activities_count=' + current_activities_count,
      function(response, status, req) {
        $.each(already_checked_boxes, function(index, value) {
          $('[data-hover-container=' + value + ']').find('.results_table_hover_assign').removeClass('hidden_helper');

          var cant_check_this = $('#' + value);
          VHL.Checkboxes._toggle_checkbox(cant_check_this);
        });

        // Persist checked Lessons across ajax.
        var grouping = $('.lesson');

        var group_check = grouping.each(function() {
          var some_unchecked = false;

          var group_lessons = $(this).find('li.activity_item');
          group_lessons.each(function() {
            if (!$(this).hasClass('highlight_bg')) {
              some_unchecked = true;
            }
          });

          if (some_unchecked === false) {
            $(this).find('.checkbox_all').addClass('show_check');
          }
        });

        $('.unassigned_activities_list').scrollTop(scroll_placement);

        // Null out and replace the assignment wizard call so that it works after ajax
        $('.set_date_link').attr('onclick', null);
        var assignment_wizard_call = '$(this).assignment_wizard(); return false';
        $('.set_date_link').attr('onclick', assignment_wizard_call);


        if ($('.toc_checkbox').hasClass('show_check')) {
          $('.set_date_link').disable_link_toggle({
            meth: 'enable'
          });
        } else {
          $('.set_date_link').disable_link_toggle({
            meth: 'disable',
            disable: 'You must first select an activity.'
          });
        }

        VHL.Checkboxes._set_ids();
        VHL.AssignmentCalendar.set_activity_links();
        VHL.Checkboxes._total_checked();
        VHL.Checkboxes.vhl_group_checkboxes({page: 'assignments'});
        VHL.AssignmentCalendar.assign_activity_hover();
        init_show_more_activities();
      }
    );
  }

  return {
    init: init
  }
})();

$(document).ready(function() {
  VHL.EventCalendar.init();
});
