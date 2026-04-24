/* global VHL */

VHL.GradePages = (function() {
  var initialize_student_checkboxes = function() {
    $('.student_checkbox').on('click', function(){
      if ($('.student_checkbox_all').hasClass('show_check') && $(this).hasClass('show_check')) {
        $('.student_checkbox_all').toggleClass('show_check');
      }
      $(this).toggleClass('show_check');
      $(this).parents('tr').toggleClass('highlight_bg');
    });

    $('.student_checkbox_all').on('click', function() {
      check_all = !$(this).hasClass('show_check');
      $(this).toggleClass('show_check');
      $('.student_checkbox').each(function(index){
        if($(this).attr('aria-disabled') === undefined){
          $(this).toggleClass('show_check', check_all);
          $(this).parents('tr').toggleClass('highlight_bg', check_all);
        }
      });
    });
  }

  return {
    initialize_student_checkboxes: initialize_student_checkboxes
  }
})();

VHL.AddStudents = (function() {
  function toggleRowHighlight() {
    $('.js-student-row').removeClass('is-active');
    $('.js-student-checkbox:checked').parents('.js-student-row').addClass('is-active');
  }

  function bindHighlightToCheckbox() {
    $('.js-student-checkbox').on('click', function() {
      toggleRowHighlight();
    });
  }

  function bindEnrollmentSubmit() {
    $('form#students_enrollment_confirmation_form').submit(function() {
      var submitButton = $('input#confirm');
      submitButton.attr('disabled', true);
      submitButton.val('Please wait...');
    });
  }

  function bindReturnToUnenrolledLink() {
    $('.js-return-to-unenrolled').click(function() {
      $('.js-search-results').addClass('is-hidden');
      $('.js-unenrolled-students').removeClass('is-hidden');
    });
  }

  function bindSearchFormSubmit() {
    $('form#search_student').submit(function() {
      var $form = $('form#search_student');
      $.ajax({
        type: $form.attr('method'),
        url: $form.attr('action'),
        data: $form.serialize(),
        success: function(xhr) {
          var searchResults = $('.js-search-results')
          searchResults.html('').removeClass('is-hidden');
          searchResults.html(xhr);

          $('.js-unenrolled-students').addClass('is-hidden');
          bindReturnToUnenrolledLink();
          bindHighlightToCheckbox();
        },
        error: function() {}
      });

      return false;
    });
  }

  function setFlash(msg) {
    var htmlStr;
    if ($('.flash-error').length > 0 ) {
      htmlStr = '<p>' + msg + '</p>';
      $('.flash-error').html(htmlStr);
    } else {
      htmlStr = '<div class="flash-error" id="flash_error"> <p>' + msg + '</p> </div>';
      $('div#column_wrapper').prepend(htmlStr);
    }
  }

  function isSectionNotSelected() {
    var selectedSectionID = $('.js-section-select option:selected').attr('value');
    if (selectedSectionID === '') {
      return true;
    }
    return false;
  }

  function bindSectionSubmitButton() {
    $('.js-section-submit').click(function() {
      if (isSectionNotSelected()) {
        setFlash('A section must be selected.');
        return false;
      }
    });
  }

  function bindAddStudentsSubmitButton() {
    $('.js-add-student-submit').click(function() {
      /* If no students are selected, display an error. */
      if (!$('.js-student-checkbox:checked').size() > 0) {
        setFlash('At least one student must be selected.');
        return false;
      }
    });
  }

  function setSelectedSection() {
    $('#section_id').val($('#selected_section_id').val());
  }

  function init() {
    setSelectedSection();
    toggleRowHighlight();
    bindHighlightToCheckbox();
    bindEnrollmentSubmit();
    bindSectionSubmitButton();
    bindSearchFormSubmit();
    bindAddStudentsSubmitButton();
  }

  return {
    init: init
  };
})();

VHL.DropStudents = (function() {

  function bindConfirmDialog() {
    var form = $('.js-drop-form');
    var overlay = $('.js-confirm-drop-overlay');

    /**
     *  Update the dialog UI when any checkbox is clicked:
     *  
     *  Revise the count of selected students displayed in the dialog.
     *  Disable the button to open the dialog when none selected.
     */
    $('.js-checkbox').on('click', function(){
      var numberSelected = VHL.Music.Checkboxes.checkedCount();
      /* Use correct grammar based on count: */
      var isSingular = (numberSelected === 1);
      $('.js-student-count').text(
        isSingular ? 'this student' : ('these ' + numberSelected + ' students')
      );
      /* Disable "Drop" button if no students selected: */
      setDisabled($('.js-open-confirm'), numberSelected < 1, 'You must select students to drop.');
    });

    /**
     * Open confirmation dialog when "Drop" button is clicked.
     */
    $('.js-open-confirm').on('click', function(event) {
      overlay.show();
    });

    /**
     * Hide the dialog when "Drop Students" is clicked.
     */
    $('.js-confirm-drop').on('click', function() {
      $('.js-confirm-drop-overlay').hide();
    });

    /**
     * Hide the dialog when "cancel" is clicked.
     */
    $('.js-cancel-drop').on('click', function(event) {
      event.preventDefault();
      $('.js-confirm-drop-overlay').hide();
    });
  };

  /**
   * Enables or disabled a given link or button.
   *
   * @param  {string, DOMElement, or jQuery} selector
   * @param  {boolean} newState - true=disabled, false=enabled
   * @param  {string} message - Tooltip for disabled state.
   */
  function setDisabled(element, newState, msg) {
    var el = $(element);
    var message = msg || 'Disabled.';
    el.attr('disabled', newState)
      .attr('title', newState ? message : '')
      .css('pointer-events', newState ? 'none' : '');
  }

  function init() {
    VHL.GradePages.initialize_student_checkboxes();
    bindConfirmDialog();
    
  }

  return {
    init: init
  };
})();

VHL.SelectStudents = (function() {
  var init = function() {
    VHL.GradePages.initialize_student_checkboxes();
    bind_submit_button();
  }

  var bind_submit_button = function() {
    $('#selected_students_submit').click(function(){
      actions_form = $('form');
      id_list = "";
      if ($('.student_checkbox.show_check').length > 0) {
        $('.student_checkbox.show_check').each(function(index) {
          actions_form.append('<input type="hidden" name="selected_students[]" value="' + $(this).attr('id').replace('student_','') + '" />');
        });
        actions_form.submit();
      } else {
        alert('Please make a selection.');
        return false;
      }
   });
  }

  return {
    init: init
  }
})();

VHL.SearchStudents = (function() {
  var init = function() {
    bind_search();
  }

  var bind_search = function() {
    $('#student_search_string').focus(function() {
      if (this.value === 'Search Students') {
        this.value = '';
      }
    }).blur(function() {
      if (this.value === '') {
        $(this).val("Search Students").removeClass('student_search_string_focus');
      } else if (this.value != '') {
        $(this).addClass('student_search_string_focus');
      }
    });
  }

  return {
    init: init
  }
})();

VHL.EmailStudents = (function() {
  var init = function() {
    set_separator(',');
    bind_separator();
    bind_checkboxes();
  }

  var bind_checkboxes = function() {
    $('.student_checkbox').each(function() {
      if ($(this).hasClass('show_check')) {
        $(this).parents('tr').toggleClass('highlight_bg');
      }
    });

    $('.student_checkbox').live('click', function(){
      if ($('.student_checkbox_all').hasClass('show_check') && $(this).hasClass('show_check')) {
        $('.student_checkbox_all').toggleClass('show_check');
      }
      $(this).toggleClass('show_check');
      $(this).parents('tr').toggleClass('highlight_bg');
      update_recipients();
    });

    $('.student_checkbox_all').live('click', function(){
      check_all = !$(this).hasClass('show_check');
      $(this).toggleClass('show_check');
      $('.student_checkbox').each(function(index){
        $(this).toggleClass('show_check', check_all);
        $(this).parents('tr').toggleClass('highlight_bg', check_all);
      });
      update_recipients();
    });
  }

  var bind_separator = function() {
    $('[data-js-separator]').click(function() {
      var separator = $(this).attr('data-js-separator');

      if (separator === 'comma') {
        set_separator(',');
      } else if (separator === 'semicolon') {
        set_separator(';');
      }
    })
  }

  var set_separator = function(separator) {
    $('#current_list_separator').attr("value", separator);
    update_recipients();
  }

  var update_recipients = function() {
    var tr, email_list, link_href;
    var selected_students = new Array();
    var separator = $('#current_list_separator').val();
    $('[class="student_checkbox checkbox show_check"]').each(function(index){
      tr = $(this).parents('tr');
      selected_students.push(tr.find('[data-type-container=student_email]').html());
    });
    email_list = selected_students.join(separator + " ");
    $('#email_recipients_preview').val(email_list);
    if (email_list == '') {
      link_href ="#";
    } else {
      link_href = "mailto:" + email_list;
    }
    $('#email_link').attr('href', link_href);
  }

  return {
    init: init
  }
})();

VHL.BulkGradeStudents = (function() {
  var init = function() {
    initialize_disabled_comments();
    bind_update_points();
    bind_highlighting();
    bind_checkbox();
  }

  var bind_checkbox = function() {
    $('[data-js-change="checkbox"]').click(function() {
      toggle_bulk_penalty_columns(this);
    });
  }

  var bind_highlighting = function() {
    $('[data-js-change="focus_blur"]').focus(function(){
      highlight_onfocus(this);
    }).blur(function(){
      de_highlight_onblur(this);
    }).keypress(function(e) {
      navigate_tabs(event);
    });
  }

  var bind_update_points = function() {
    $('[data-js-key="update_points"]').keyup(function() {
      var point_type = $(this).attr('data-js-point-type');
      var points = $(this).attr('data-js-points');

      update_total_points(this, point_type, points);
      if (point_type === "penalty_percent") {
        toggle_comment_field_access(this);
      }
    });
  }

  var initialize_disabled_comments = function() {
    $('input.penalty_percent').each(function() {
      disable_comment_field(this);
    });
  }

  var navigate_tabs = function(event) {
    if (event.keyCode == $.ui.keyCode.ENTER ) {
      event.preventDefault();
      var ele = event.target;
      var next_row_id = get_next_row_index(ele,1);

      if (next_row_id != null ) {
         $('#'+ next_row_id + ' td input.points_earned').first().focus();
       }
    }
  }

  var update_total_points = function(ele, ele_type, points_possible) {
    var ele_id = $(ele).attr('id');
    var new_points_earned;
    var curr_penalty;
    var ele_index;
    var penalty_ele;
    var points_ele;

    if (ele_type == 'points_earned') {
       var ele_index = ele_id.replace(/points_earned/,'');
       var penalty_ele = $('#' + ele_index + 'penalty_percent');
       var points_ele = ele;
    } else if (ele_type == 'penalty_percent') {
       var ele_index = ele_id.replace(/penalty_percent/,'');
       var penalty_ele = ele;
       var points_ele = $('#' + ele_index + 'points_earned');
    }

    new_points_earned = parse_points(points_ele);
    curr_penalty      = parse_penalty(penalty_ele, points_possible);

    var total_pt_ele = $('#' + ele_index + 'total_points');

    if ((!($(points_ele).val() == '') && isNaN(new_points_earned)) || (!($(penalty_ele).val() == '') && isNaN(curr_penalty))){
        total_pt_ele.html(' ? ');
        total_pt_ele.css("background","#FFCDCC");
        return;
    }

    new_total_pt = new_points_earned - Math.abs(curr_penalty);
    if (new_total_pt < 0.0) {
      new_total_pt = 0.0;
    }

    total_pt_ele.html(' ' + new_total_pt.toFixed(1) + ' ');

    // If there is no penalty, don't change the background color.
    var penalty_amount = $('#' + ele_index + 'penalty_percent').val();

    if (penalty_amount == "" || penalty_amount == "0") {
      total_pt_ele.css('background', '#F5F5F5');
    } else {
      total_pt_ele.css("background","#FFFFFF");
    }
  }

  var highlight_onfocus = function(ele) {
    $(ele).css("background","#FFCDCC");
    $(ele).select();
  }

  var de_highlight_onblur = function(ele) {
    $(ele).css("background","#FFFFFF");
  }

  var toggle_bulk_penalty_columns = function(checkbox) {
    var ret_val = true;
    if( $(checkbox).is(':checked') ) {
      $('.penalty_column').show();
      $('.penalty_percent').removeAttr('disabled');
      $('.penalty_percent').each(function() {
        if($(this).val().length > 0){
          enable_comment_field(this);
        }
      });
    } else {
      var penalties = 0;
      var amount = 0;
      $('.penalty_percent').each(function(){
        if(parseFloat($(this).val())) {
          amount = $(this).val();
        } else if($(this).val().length > 0) {
          amount = 1;  // allows non-numeric values to trigger confirm
        }
        penalties += amount;
      });
      if(penalties > 0) {
        ret_val = confirm('If you continue, the penalties you entered will not be submitted.')
      }
      if(ret_val) {
        $('.penalty_column').hide();
        $('.penalty_percent').attr('disabled', 'disabled');
        $('.penalty_percent').each(function() {
          if($(this).val().length > 0){
            disable_comment_field(this);
          }
        });
      } else {
        checkbox.checked = true;
      }
    }

    return ret_val;
  }

  var toggle_comment_field_access = function(ele) {
    if ($(ele).val() == '') {
       disable_comment_field(ele);
    } else {
       enable_comment_field(ele);
    }
  }

  var disable_comment_field = function(ele) {
    if ($(ele).val() == '') {
      var ele_id = $(ele).attr('id').replace(/penalty_percent/,'') + 'comment';
      $('#'+ ele_id).attr('disabled','disabled');
      $('#'+ ele_id).addClass('input_disabled');
      $('#'+ ele_id).first().css("background","#eee");
    }
  }

  var enable_comment_field = function(ele) {
    if ($(ele).val() != '' && !isNaN(parseFloat($(ele).val()))) {
      var ele_id = $(ele).attr('id').replace(/penalty_percent/,'') + 'comment';
      $('#'+ ele_id).removeAttr('disabled');
      $('#'+ ele_id).removeClass('input_disabled');
      $('#'+ ele_id).first().css("background","#fff");
    }
  }

  var get_next_row_index = function(ele, delta) {
    var row_id = get_row_id(ele);
    var row_index = parseInt(row_id.replace(/row_/,''));
    return 'row_' + (row_index + delta );
  }

  var get_row_id = function(ele) {
    var col = $(ele).parents().first();
    var row = $(col).parents().first();
    var row_id = row.attr('id');
    return row_id
  }

  var get_value = function(ele) {
    if ($.trim($(ele).val()).length == 0){
      return 0.0;
    }
    return $(ele).val();
  }

  var parse_points = function(ele) {
    return parseFloat(get_value(ele));
  }

  var parse_penalty = function(ele, points_possible) {
    penalty_val = get_value(ele);
    return ((parseFloat(penalty_val)/100) * points_possible);
  }

  return {
    init: init
  }
})();

VHL.StudentShow = (function() {
  var init = function() {
    hoverize_data_dash_with_ajax();
    bind_unassigned_hover();
    bind_gradechange_hover();
    VHL.Common.initialize_datepicker();
    setHeight('.student_summary_section');
  }

  var bind_unassigned_hover = function() {
    $('.activity_unassigned').mouseover(function(){
      $(this).find('.unassigned_hover').removeClass('hidden_helper');
    }).mouseout(function(){
      $(this).find('.unassigned_hover').addClass('hidden_helper');
    });
  }

  function hoverize_data_dash_with_ajax() {
    $('[data-hover-url]').each(function(){
      var current_element = this;
      var element_id = $(current_element).attr('id');
      add_hover_intent_to_element(current_element,
                                  function(){ ajax_call_for_hover(current_element); },
                                  function(){ $("[data-hover-container='"+element_id+"']" ).hide(); }
      );
    });
  }

  function add_hover_intent_to_element(element, mouse_in, mouse_out){
    var config = {
         over: mouse_in,
         timeout: 500,
         out: mouse_out,
         sensitivity: 1
    };

    $(element).hoverIntent( config )
  }

  function ajax_call_for_hover(element) {
    var element_id = $(element).attr('id');
    $.ajax({
      url: $(element).attr('data-hover-url'),
      beforeSend: function(xhr) {xhr.setRequestHeader("Accept", "text/javascript");},
      dataType:'html',
      success: function(data){
        $("[data-hover-container='"+element_id+"']").html(data);
        $("[data-hover-container='"+element_id+"']" ).show();
      }
    });
  }

  var setHeight = function(column) {
    var maxHeight = 0;
    column = $(column);
    column.each(function() {
      if($(this).height() > maxHeight) {
        maxHeight = $(this).height();;
      }
    });
    column.height(maxHeight);
  }

  return {
    init: init
  }
})();

$(document).ready(function() {
  var body = $('body');

  if (body.hasClass('contact_students')) {
    VHL.EmailStudents.init();
  } else if (body.hasClass('drop_students')) {
    VHL.DropStudents.init();
  } else if (body.hasClass('enter_scores')) {
    VHL.BulkGradeStudents.init();
  } else if (body.hasClass('popup')) {
    // The Popup does not allow body classes. Luckily, it is used so infrequently
    // that it won't cause any problems.
    VHL.StudentShow.init();
  } else if (body.hasClass('student_grades')) {
    VHL.StudentShow.init();
  } else if (body.hasClass('gradebook')) {
    VHL.SearchStudents.init();
  } else if (body.hasClass('search_students')) {
    VHL.SearchStudents.init();
  } else if (body.hasClass('add_students')) {
    VHL.AddStudents.init();
  }

});
