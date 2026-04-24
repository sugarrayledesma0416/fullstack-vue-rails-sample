
(function( $ ) {
  var _dialog;
  var _dialog_options;
  var _assignment_wizard_path;
  var _form;

  var spinner_html = '<div id="modal_spinner" style="position:absolute;top:15%;left:40%;"><img alt="page loading" src="/images/loading_32.gif"/></div>';

  /**
   * Shows or hides element or element collection (default is to show).
   * @param {Object} paramObject - parameter object to be destructured
   * @param {HTMLElement|HTMLElement[]} paramObject.elm - an element, or an array of elements
   * @param {boolean} [paramObject.show=true] - true if elm(s) should be shown, otherwise false
   */
  function showElm({ elm, show=true } = {}) {
    const elmCollection = Array.isArray(elm) ? elm : [elm];

    elmCollection.forEach((item) => {
      item.classList.toggle('u-hidden', !show);
    });
  }

  var dialog_complete_callback = function() {
    // add checkbox events to update selected assignables count
    $('[data-container=assignables] [data-input-type=checkbox]').change(updateSelectedAssignablesCount);

    _review_twostep();

    VHL.Common.initialize_datepicker();
    $('.date_timepicker').datetimepicker();

    disable_number_of_attempts_if_time_limit_set($('#activity_assignment_assigned_assessment_detail_attributes_time_limit').val());
    disable_time_limit_if_number_of_attempts_set($('#activity_assignment_assigned_assessment_detail_attributes_number_of_attempts').val());

    $('a.prevent-default').click(function(event) {
      event.preventDefault();
    });

    $('.js-cancel-button').click(function() {
      return $(this).assignment_wizard('close');
    });

    $('.js-reassign-button').click(function() {
      return $(this).assignment_wizard('reassign');
    });

    $('.js-unassign-button').click(function() {
      return $(this).assignment_wizard('unassign');
    });

    $('.js-save-button').click(function() {
      return $(this).assignment_wizard('submit');
    });

    $('.js-save-and-assign-button').click(function(event) {
      event.preventDefault();
      $(this).assignment_wizard('submit', event.target.dataset.href);
    });

    // Hidden rnd shown date/time boxes for Availability Options
    $('#activity_assignment_show_assessment').change( function () {
      var assessValue = $(this).find(":selected").val();
      if (assessValue === "a specific date and time") {
        $(this).parent().siblings('.avail_date').find('#activity_assignment_show_at').show();
      }
      else {
        $(this).parent().siblings('.avail_date').find('#activity_assignment_show_at').hide();
      }
    });

    $('#activity_assignment_grade_availability').change( function () {
      var gradeValue = $(this).find(":selected").val();

      if (gradeValue === "on_specific_date") {
        $(this).parent().siblings('.grades_date').find('#activity_assignment_grades_available_at').show();
      }
      else {
        $(this).parent().siblings('.grades_date').find('#activity_assignment_grades_available_at').hide();
      }
    });

    if ($('.js-individual-assign-dropdown').val() === 'true') {
      $('.js-save-and-assign-button').removeClass('u-hidden');
    }

    $('.js-individual-assign-dropdown').change(
      function(event) {
        if (event.target.value === 'true') {
          console.log(event.target.value);
          $('.js-save-and-assign-button').removeClass('u-hidden');
        } else {
          $('.js-save-and-assign-button').addClass('u-hidden');
        }
      }
    );

    const defaultDate = $('#activity_assignment_due_date');
    const manuallyOrderedDates = $('#section_due_dates').val() ? $('#section_due_dates').val().split(' ') : [];
    const datePickerContainer = $('[data-container=assignment_wizard] [data-container=reassign]');
    if(defaultDate && datePickerContainer.is(':visible')) {
      _toggleManuallyOrderedWarningVisibility(defaultDate.val());
    }

    datePickerContainer.on('showReassign',
      function () {
        _toggleManuallyOrderedWarningVisibility(defaultDate.val());
        _toggleMultipleDueDatesWarningVisibility();
      }
    );

    $('#activity_assignment_due_date').change(
      function(event) {
        _toggleManuallyOrderedWarningVisibility(event.target.value);
      }
    );

    function _toggleManuallyOrderedWarningVisibility(targetDate) {
      const manualOrderedDueDateWarningElm = document.querySelector(
        '.js-manual-ordered-due-date-warning'
      );

      showElm({
        elm: manualOrderedDueDateWarningElm,
        show: targetDate && manuallyOrderedDates.includes(targetDate),
      })
    }

    function _toggleMultipleDueDatesWarningVisibility() {
      const multipleDueDatesWarningElm = document.querySelector('.js-multiple-due-dates-warning');

      const selectedAssignables = document.querySelectorAll(
        '[data-container=assignment_wizard] [data-container=review] [data-container=assignables] input.js-selected'
      );

      const showWarning = [...selectedAssignables].some(
        item => item.dataset.assignableHasMultipleDueDates === 'true'
      )

      showElm({
        elm: multipleDueDatesWarningElm,
        show: showWarning,
      });
    }

    $('#activity_assignment_assigned_assessment_detail_attributes_time_limit').change(function () {
      disable_number_of_attempts_if_time_limit_set($(this).val());
    });

    $('#activity_assignment_assigned_assessment_detail_attributes_number_of_attempts').change(function () {
      disable_time_limit_if_number_of_attempts_set($(this).val());
    });
  };

  var disable_number_of_attempts_if_time_limit_set = function (time_limit) {
    time_limit = parseInt(time_limit);
    var attempts_dropdown = $('#activity_assignment_assigned_assessment_detail_attributes_number_of_attempts');
    var disable_dropdown = !_.isNaN(time_limit) && _.isNumber(time_limit) && time_limit > 0;
    attempts_dropdown.prop('disabled', disable_dropdown);
    $('[data-element-type="disabled_attempts_msg"]').toggleClass('hidden_helper', !disable_dropdown);
  };

  var disable_time_limit_if_number_of_attempts_set = function (number_of_attempts) {
    var disable_time_limit = number_of_attempts !== "1";
    var time_limit_field = $('#activity_assignment_assigned_assessment_detail_attributes_time_limit');
    time_limit_field.prop('disabled', disable_time_limit);
    $('[data-element-type="disabled_timer_msg"]').toggleClass('hidden_helper', !disable_time_limit);
    if (disable_time_limit) {
      $('#activity_assignment_assigned_assessment_detail_attributes_time_limit').val('');
    }

  };

  function updateSelectedAssignablesCount() {
    const selectedCount = document.querySelectorAll(
      '[data-container=assignables] [data-input-type=checkbox]:checked'
    ).length;

    document.querySelectorAll('[data-assignable-count]').forEach((elm) => {
      elm.replaceChild(new Text(selectedCount), elm.firstChild);

      if (selectedCount === 0) {
        setModalErrors('Please select at least one activity.');
      } else {
        resetModalErrors();
      }
    });

    const singularLabels = document.querySelectorAll('.singular_assignable_type');
    const pluralLabels = document.querySelectorAll('.plural_assignable_type');

    showElm({
      elm: [...singularLabels],
      show: selectedCount === 1,
    });

    showElm({
      elm: [...pluralLabels],
      show: selectedCount !== 1,
    });
  }

  function getErrorDiv() {
    return document.querySelector(
      '[data-container=assignment_wizard] form [data-container=jquery_modal_error_status]'
    );
  }

  function resetModalErrors() {
    const errorDiv = getErrorDiv();
    errorDiv.innerHTML = '';
    showElm({ elm: errorDiv, show: false });
  }

  function setModalErrors(msg) {
    const errorDiv = getErrorDiv();
    errorDiv.innerHTML = `<div class="modal_errors"><p class="error_for_modal">${msg}</p></div>`;
    showElm({ elm: errorDiv });
  }

  function _review_twostep() {
    // Add event listener for select-all checkbox
    $('.js-select-all').on('click', function() {
      const isChecked = $(this).prop('checked');
      const checkboxes = $('.review_selected');

      checkboxes.each(function() {
        if (isChecked) {
          $(this).addClass("show_check");
          $(this).addClass("js-selected");
          this.checked = true;
        } else {
          $(this).removeClass("show_check");
          $(this).removeClass("js-selected");
          this.checked = false;
        }
        updateAssignLink('.review_selected');
      });

      updateSelectedAssignablesCount();
    });

    $('.review_selected').on("click", function() {
      $(this).toggleClass("show_check");
      $(this).toggleClass("js-selected");
      updateAssignLink('.review_selected');
    });
  }

  function clearErrors(){
    document.querySelectorAll('.error_for_modal').forEach(node => node.remove())
  }

  function appendErrorsToFields(errors) {
    $("#jquery_modal_error_status").addClass('u-hidden');
    clearErrors();
    
    const errorsBlock = document.createElement("div");
    errorsBlock.innerHTML = errors.errors_message_block;

    errors.fields_with_errors.forEach(field => {
      const containerSelector = `div[data-container='${field}']`;
      const errorClass = `js-error-${field}`;
      const errorMessages = Array.from(errorsBlock.firstChild.childNodes)

      errorMessages.forEach(node => {
        if (node.classList.contains(errorClass)){
          $(containerSelector).append(node).addClass('u-txt-error');

          if (node.classList.contains('js-error-due_date')) {
            node.prepend('Due date ');
          }
        }
      })
    });
  }

  
  function updateAssignLink(checkboxSelector) {
    const checkboxes = document.querySelectorAll(checkboxSelector);
    const atLeastOneCheckboxIsChecked = [...checkboxes].some(
      item => item.classList.contains('show_check')
    );

    const reassignButton = document.querySelector('.js-reassign-button');
    reassignButton.disabled = !atLeastOneCheckboxIsChecked;

    // Checked/uncheck whether all checkboxes are checked or not
    const checkboxAll = $('.js-select-all')[0];
    const allCheckboxesHaveShowCheck = [...checkboxes].every(
        item => item.classList.contains('show_check')
    );
    checkboxAll.checked = allCheckboxesHaveShowCheck;
  }

  var selected_assignables = function(assignable_class) {
    var assignable_ids = [];
    $.merge(
      $('[data-container=assignables] [data-input-type=checkbox][data-assignable-class=' + assignable_class + ']:checked'),
      $('[data-container=assignables] [data-input-type=hidden][data-assignable-class=' + assignable_class + ']') ).each(function(i, e) {
        assignable_ids.push($(e).attr('data-assignable-id') );
      } );
    return assignable_ids;
  };

  var methods = {
    init: function() {
      if(_dialog === undefined) {
        _dialog = $('[data-modal=assignment_wizard]');

        // This is mainly for the assignment calendar.
        if(_dialog.length === 0) {
          _dialog = $('<div data-modal="assignment_wizard" class="assignables_dialog"></div>');
          _dialog.prependTo('body');
        }
      }

      _dialog_options = {
        title: $(this).attr('title'),
        minHeight: 150,
        minWidth: 600,
        modal: true,
        dialogClass: 'assignables_wizard',
        position: 'center',
        resizable: false,
        open: function() {
          _dialog.append(spinner_html);
        },
        close: function() {
          _dialog.find('form').remove();
          $('div.ui-dialog-buttonpane').remove();
        }
      };

      // set ajax remote url
      var url_parts = this.attr('href').split('?');
      _assignment_wizard_path = url_parts[0];
      var url_params_string = url_parts[1];
      var params = dialog_complete_callback; // if no params are found this will make sure a GET request is made.
      if (url_params_string) {
        params = url_params_string.split("&").reduce(function(memo, current) {
          var param = current.split("=");
          memo[decodeURIComponent(param[0])] = decodeURIComponent(param[1]);
          return memo;
        }, {});
      }
      _dialog.dialog(_dialog_options).load(_assignment_wizard_path, params, dialog_complete_callback);

      return this;
    },

    toggleDetails: function() {
      if ($(this).hasClass('varies_arrow_open')) {
        $('.varies_arrow').removeClass('varies_arrow_open');
        $('.assignments_details').hide();
      } else {
        $('.varies_arrow').removeClass('varies_arrow_open');
        $(this).addClass('varies_arrow_open');

        $('.assignments_details').hide();
        $(this).siblings('.assignments_details').show();
      }
    },

    toggleAvailability: function () {
      $(this).parent().toggle();
      $(this).parent().siblings('.avail_options').toggle();
      var assessValue = $(this).parent().siblings('.avail_options').find(':selected').val();
      if (assessValue == "a specific date and time") {
        $(this).parent().siblings('.avail_date').find(
          '#activity_assignment_show_at'
        ).show();
      }
    },

    toggleGrades: function () {
      $(this).parent().toggle();
      $(this).parent().siblings('.grades_options').toggle();
      var assessValue = $(this).parent().siblings('.grades_options').find(':selected').val();
      if (assessValue == "on_specific_date") {
        $(this).parent().siblings('.grades_date').find(
          '#activity_assignment_grades_available_at'
        ).show();
      }
    },

    toggleAnswers: function () {
      $(this).parent().toggle();
      $(this).parent().siblings('.answers_options').toggle();
      var assessValue = $(this).parent().siblings('.answers_options').find(':selected').val();
      if (assessValue == "on_specific_date") {
        $(this).parent().siblings('.answers_date').find(
          '#activity_assignment_answers_available_at'
        ).show();
      }
    },

    toggleDueTime: function () {
      $(this).parent().toggle();
      $(this).parent().siblings('.custom_due_time').toggle();
    },

    toggleTimeLimit: function() {
      $(this).parent().toggle();
      $(this).parent().siblings('.custom_time_limit').toggle();
    },

    togglePassword: function() {
      $(this).parent().toggle();
      $(this).parent().siblings('.custom_password').toggle();
    },

    displayVals: function() {
      var singleValues = $("#activity_assignment_show_assessment").val();
      $('.display_values').html(singleValues);
    },

    unassign: function() {
      // set the form to 'unassign' which will be detected by the target controller
      $('[data-container=assignment_wizard] #update_type').val('unassign');

      var items_selected = selected_assignables('activity').length +
                           selected_assignables('resource').length;
      if (items_selected > 0) {
        var message = 'You are about to unassign ' + items_selected +
                      ' item' + (items_selected == 1 ? '.' : 's.');

        if (confirm(message) ) {
          return methods.submit();
        }
      } else {
        alert('Please select at least one activity.');
      }
      return false;
    },

    reassign: function() {
      $('[data-container=assignment_wizard] #update_type').val('assign');
      $('[data-container=assignment_wizard] [data-container=review]').hide();
      $('[data-container=assignment_wizard] [data-container=reassign]').show()
        .trigger('showReassign');
    },

    set_assignment_date: function() {
      var assignment_date = $('[data-container=default_assignment_date]').val();
      $('.has_datepicker').datepicker('setDate', assignment_date);
    },

    review: function() {
      // hide any error messages from the reassign page when returning to the review page
      const errorDiv = getErrorDiv();
      showElm({ elm: errorDiv, show: false });
      showElm({ elm: document.querySelector('.js-manual-ordered-due-date-warning'), show: false });
      showElm({ elm: document.querySelector('.js-multiple-due-dates-warning'), show: false });

      $('[data-container=assignment_wizard] [data-container=review]').show();
      $('[data-container=assignment_wizard] [data-container=reassign]').hide();
      /**
       * I'm not sure why this is shown again - if it's empty, it appears as an empty div with a border.
       * As a precaution, I'm showing it only if it has content.
       */
      if (errorDiv.firstChild) {
        showElm({ elm: errorDiv });
      }
    },

    close: function() {
      _dialog = $('[data-modal=assignment_wizard]');
      _dialog.dialog('close');
      return false;
    },

    submit: function(href) {
      $('.js-save-button').prop('disabled', true);
      $('#selected_activities').val( selected_assignables('activity').join(',') );
      $('#selected_resources').val( selected_assignables('resource').join(',') );

      _dialog = $('[data-modal=assignment_wizard]');
      _form = $('[data-container=assignment_wizard] form');

      $.ajax({
        type: _form.attr('method'),
        url: _form.attr('action'),
        data: _form.serialize(),
        dataType: 'json',
        loading: _dialog.append(spinner_html),
        success: function(data, status, xhr) {
          $("#modal_set_due_date_error_div").addClass('u-hidden');

          // Render assignment_rank_lists/edit view in case there are activities
          // and instructor created activities within the same due date.
          if (data.load_rank_list) {
            _dialog.dialog().load('/assignment_rank_lists/edit/' + data.section_id + '?due_date=' + data.due_date + '&toc_location=' + data.toc_location);
            _dialog.dialog('option', 'title', 'Reorder Instructor Content');
          } else {
            _dialog.dialog('close');
            if (href) {
              window.location.href = href;
            } else {
              // to avoid reloading the page if it is coming from the standards assigning page
              if(data.is_standards_assigning) {
                // As we are not reloading the page for standards-based assigning because that would mess with the filters we need to show the flash message this way.
                document.querySelector('.js-flash-banner-group').innerHTML += `<div class="c-flash-banner  c-flash-banner--notice  js-flash-banner  js-flash-assignment-successful  test-flash-notice">
                    <a class="c-flash-banner__close-link" href="javascript://" onclick="$(this).parents('.js-flash-banner').setState('hidden');">
                      <span class="u-screen-reader-only">Close</span>
                      <span aria-hidden="true">×</span>
                    </a>
                    <div class="l-media">
                      <div class="l-media__img">
                        <span class="c-flash-banner__icon  c-flash-banner__icon--notice"></span>
                        <span class="u-screen-reader-only">notice</span>
                      </div>
                    <div class="l-media__body">
                      Activity assigned successfully.
                    </div>
                  </div>`
                _dialog.dialog('close');

                setTimeout(() => {
                  document.querySelector('.js-flash-assignment-successful').remove();
                }, 5000);

                // Create and dispatch custom event to update results from standards-based assigning.
                const assignmentUpdateEvent = new CustomEvent('assignmentUpdate');
                document.dispatchEvent(assignmentUpdateEvent);
              } else {
                const form_data = new FormData(_form[0]);
                const selected_date = new Date(form_data.get('activity_assignment[due_date]'));
                // In JS the months starts at index 0, so we need to add 1 to get the correct month.
                const month_to_move = (selected_date.getMonth() + 1).toString().padStart(2, '0');
                const move_calendar_to = `${selected_date.getFullYear()}-${month_to_move}`;
                window.location.href = `${window.location.pathname}?month=${move_calendar_to}`;
              }
              return false;
            }
          }
        },
        error: function(data, status) {
          $('#modal_spinner').remove();
          $("#modal_set_due_date_error_div").removeClass('u-hidden');
          var errors = $.parseJSON(data.responseText);

          if (errors) {
            VHL.Common.set_error_class_for_fields(errors.fields_with_errors);
            const errorDiv = getErrorDiv();
            showElm({ elm: errorDiv });
            appendErrorsToFields(errors);
          }
        }

      }).always(function(){
        $('.js-save-button').prop('disabled', false);
      });

      return false;
    }
  };


  // attach the assignment wizard plugin to all jQuery objects
  $.fn.assignment_wizard = function( method ) {

    // Method calling logic
    if ( methods[method] ) {
      return methods[ method ].apply( this, Array.prototype.slice.call( arguments, 1 ));
    } else if ( typeof method === 'object' || ! method ) {
      return methods.init.apply( this, arguments );
    } else {
      $.error( 'Method ' +  method + ' does not exist on jQuery.tooltip' );
    }

  };

})( jQuery );
