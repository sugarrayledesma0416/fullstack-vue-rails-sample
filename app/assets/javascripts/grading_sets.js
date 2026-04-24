var VHL = VHL || {};

VHL.Grading = (function () {

  // Create custom event to init Froala's composition editor.
  const initCompositionEditorEvent = new CustomEvent('initCompositionEditorEvent');

  var editing_button_classes = [
    '.js-correction-tool-btn',
    '.js-record-tool-btn'
  ];

  function give_full_credit_for_question(obj) {
    var response_id = $(obj).attr('id').split("score_button_fullcred_");
    var full_credit = $('#points_possible_for_' + response_id[1]).val();
    $("#score_for_" + response_id[1]).val(full_credit);
  }

  function give_zero_credit_for_question(obj) {
    var response_id = $(obj).attr('id').split("score_button_zero_");
    $("#score_for_" + response_id[1]).val("0");
  }

  function bind_credit_buttons() {
    $('.full_credit').on('click', function () {
      give_full_credit_for_question(this);
      return false;
    });

    $('.zero_credit').on('click', function () {
      give_zero_credit_for_question(this);
      return false;
    });

    $('#instructor-grading-set-all-zero').click(function() {
      $('.zero_credit').each(function(){
        if ($(this).parents('.hidden_helper').length == 0) {
          $(this).click();
        }
      });
      return false;
    });

    $('#instructor-grading-set-all-hundred').click(function() {
      $('.full_credit').each(function(){
        if ($(this).parents('.hidden_helper').length == 0) {
          $(this).click();
        }
      });
      return false;
    });
  }

  function toggle_comment_boxes() {
    if ($('#show_hide_comments').is(':checked')) {
      $('.instructor_comment_area').show();
    } else {
      $('.instructor_comment_area').hide();
    }
  }

  function bind_comment_box_toggle() {
    toggle_comment_boxes();

    $('[data-dash-change="toggle_comments"]').change(function () {
      toggle_comment_boxes();
    });
  }


  /**
   * Replace all instances of name with number, or vice-versa.
   */
  function toggle_student_names() {
    if ($('#show_hide_student_names').is(':checked')) {
      switch_student_label('name');
      $('span.student_name').show();
      $('.partner_name').css('visibility', 'visible');
      $('.user_name').css('visibility', 'visible');
      $('span.student_number').hide();
    } else {
      switch_student_label('number');
      $('span.student_name').hide();
      $('.partner_name').css('visibility', 'hidden');
      $('.user_name').css('visibility', 'hidden');
      $('span.student_number').show();
    }
  }

  /**
   * Get reference to original <select>
   */
  function get_dropdown() {
    return $('#student_dropdown_menu');
  }

  /**
   * switch_student_label() switches between student name and student number,
   * depending on the state of the "Show Student Names" checkbox.
   *
   * @param {String} label - Contains 'name' or 'number', depending
   *     on what to display in the <option>
   */
  function switch_student_label(label) {
    function replace_name_or_number(option, label) {
      var student_name = $(option).attr('data-student-name');
      var student_number = $(option).attr('data-student-number');
      var option_text = $(option).text();
      if (label === 'name') {
        option_text = option_text.replace(student_number, student_name);
      } else {
        option_text = option_text.replace(student_name, student_number);
      }
      $(option).text(option_text);
    }

    // If this is Student by Student grading:
    if ($('body').hasClass('by_student')) {
      get_dropdown().children().each(function (index,option) {
        replace_name_or_number(option, label);
      });

    }
  }

  /**
   * Creates a selector string for the editing tools,
   * so they can be disabled, etc.
   */
  function editing_buttons() {
    return $(editing_button_classes.join(','));
  }

  function bind_student_names_toggle() {
    window.setTimeout(function () {
      toggle_student_names();
    }, 0);

    $('[data-dash-change="toggle_names"]').change(function () {
      toggle_student_names();
    });
  }

  function empty_rubric_scores() {
    /*
     * rubric score inputs are handled via the GradingControlsApp Vue app,
     *  but validation is handled here because the submit buttons are not
     *  within the scope of the vue app.
     */
    const rubricCriteriaInputs = document.querySelectorAll('.js-rubric-criteria-score');

    if(rubricCriteriaInputs.length === 0) {
      return false;
    }

    return Array.from(rubricCriteriaInputs).some((input) => {
        return input.value.trim() === ''
    });
  }

  function check_empty_scores(selector) {
    let fields_empty = 0;
    score_fields = $(selector);
    score_fields.each(function () {
      if ($.trim($(this).val()).length === 0) {
        fields_empty += 1;
      }
    });

    if(fields_empty !== score_fields.length || !empty_rubric_scores()) {
      return confirm(
        'If you exit without saving, all scores will be lost. Ok to exit?'
      );
    }

    return true;
  }

  function check_scores(selector, label) {
    var fields_empty = 0;
    var bad_values = 0;
    const gradingControlGroups = document.querySelectorAll('.js-grading-group');
    $(selector).each(function () {
      $(this).removeClass('fieldWithErrors');
      if ($.trim($(this).val()).length === 0) {
        fields_empty += 1;
        $(this).addClass('fieldWithErrors');
      } else if (parseFloat($(this).val()).toString() === 'NaN') {
        bad_values += 1;
        $(this).addClass('fieldWithErrors');
        alert('You have entered at least one invalid score. Please fix and re-submit.');
      }
    });

    if (bad_values > 0) {
      return false;
    }
    if(empty_rubric_scores()) {
      const action = confirm(
        'You did not enter all rubric critria scores, ' +
        'OK to proceed? You will lose all of the scores for the current group of students.'
      );
      if (action && gradingControlGroups) {
        gradingControlGroups.forEach((group) => {
          clearScores(group);
        });
      }
      return action;
    }
    if (fields_empty > 0) {
      if (fields_empty === 1) {
        label = label.substring(0, label.length - 1);
      }
      return confirm('You did not enter a grade for ' + fields_empty + ' ' + label + '. OK to proceed?');
    }
    return true;
  }

  function check_empty_scores_and_jump(score_selector, jump_to) {
    var ok = check_empty_scores(score_selector);
    if (ok) {
      window.location = grading_set_review_url(jump_to);
    }
    return ok;
  }

  function grading_set_review_url(jump_to) {
    const url = new URL(window.location.href);
    const key = jump_to.includes('question') ? 'question_label' : 'student_id';
    url.searchParams.set(key, jump_to);

    return url.toString();
  }

  function track_active_editor_instance() {
    var id;
    for (id in CKEDITOR.instances) {
      CKEDITOR.instances[id].on('focus', function (e) {
        CKEDITOR.active_instance = e.editor;
      });
    }
  }

  function disable_instructor_editing_tools() {
    var $editing_group = $('.js-question-tools');
    $editing_group.addClass('is-disabled');
    editing_buttons()
        .removeClass('is-on')
        .attr("onclick", null)
        .attr("title", 'Inline feedback tools are not available for recording activities.')
        .click(function () {
          editing_buttons().removeClass('is-on');
        });
  }

  function enable_comment_boxes_for_grading_recording_activities() {
    $('#show_hide_comments').prop('checked', true);
    toggle_comment_boxes();
  }

  function enable_editing_tools_toggle() {
    editing_buttons().click(function () {
      editing_buttons().removeClass('is-on');
      $(this).addClass('is-on');
      return false;
    });
  }

  function enable_on_change_events() {
    var id;

    function ckeditor_save_snapshot(ckeditor_instance) {
      ckeditor_instance.on('saveSnapshot', function () {
        var common_parent = $(ckeditor_instance.container.$).parents('[data-content-type="answer_container"]');
        var is_first_load = common_parent.data('js-first_load');
        var show_student_response_link = $(common_parent).find('[data-content-type="show_student_response_link"]');

        if (is_first_load) {
          common_parent.data('js-first_load', false);
        } else {
          $(show_student_response_link).show();
        }
      });
    }

    for (id in CKEDITOR.instances) {
      ckeditor_save_snapshot(CKEDITOR.instances[id]);
    }
  }

  function validate_score_field(field, max) {
    var msg = '';
    $(field).removeClass('fieldWithErrors');
    var field_val = $.trim($(field).val());
    $(field).val(field_val);
    if (field_val.length !== 0) {
      if (parseFloat(field_val).toString() === 'NaN') {
        msg = 'Score must be a number.';
      } else if (field_val.match(/ /)) {
        msg = 'Score cannot include spaces.';
      } else if (field_val.match(/,/)) {
        msg = 'Score cannot include commas.';
      } else if (parseFloat(field_val) < 0) {
        msg = 'Score must be greater than zero.';
      } else if (parseFloat(field_val) > max) {
        msg = 'Score cannot be greater than ' + max + '.';
      }
    }

    if (msg.length > 0) {
      //need to do some wacky unbinding of blur and rebinding of blur after a timeout because of safari
      $(field).off('blur');
      $(field).addClass('fieldWithErrors');
      alert(msg);
      window.setTimeout(function () {
        $(field).focus();
        $(field).on('blur', function () {
          validate_score_field('#' + $(field).attr('data-validate'), $(field).attr('data-points-possible'));
        });
      }, 1);
    }
  }


  function show_original_response(selector, label) {
    clonedFroalaEditor = $(`#${selector}_container`).find('.fr-box[role="application"]').clone();
    label = label || "Student's Original Answer";
    clonedFroalaEditor.dialog({
      title: label,
      minWidth: 400,
      modal: false,
      position: 'center',
      resizable: true,
      width: 720,
      closeOnEscape: true,
      close: function (event, ui) {
        clonedFroalaEditor.remove();
      }
    });
  }



  /**
   * initialize_grading_common() sets up event handlers and
   * enabling/disabling of Instructor tools.
   */
  function initialize_grading_common() {
    $('[data-validate]').on('blur', function () {
      validate_score_field('#' + $(this).attr('data-validate'), $(this).attr('data-points-possible'));
    });

    $('[data-original-response-selector]').on('click', function () {
      show_original_response($(this).attr('data-original-response-selector'), $(this).attr('data-original-response-label'));
      return false;
    });

    // User has changed selected student/question
    $('.js-jump-to').on('change', function (evt) {
      // Get index of selected option
      var option = this.options[this.selectedIndex];
      // See if it's ok to switch:
      var ok = check_empty_scores_and_jump('.js-score-field', $(option).attr('data-jump-to'));
      /**
       * If cancelled (via conmfirmation dialog),
       * stop the dropdown from updating its value:
       */
      if (!ok) {
        evt.stopImmediatePropagation();
      }
      // Otherwise, event proceeds to selectbox and updates the selection.
    });

    if ($('#disabled_controls').val() === 'disabled') {
      disable_instructor_editing_tools();
      enable_comment_boxes_for_grading_recording_activities();
    }
  }

  function initialize_grading_sets() {
    var comments_present = false;
    $('.instructor_comment_area').each(function () {
      if ($(this).find('textarea').text().length > 0) {
        comments_present = true;
      }
    });

    if (comments_present) {
      $('#show_hide_comments').prop('checked', true);
    }

    VHL.Common.prep_common_jquery_modal({min_height: 250, width: 400});
  }

  function initialize_static_header() {
    //on scoll events
    var top_offset = $('#grading_set_static_wrap').offset().top;
    var top_of_question = $('#grading_set_static_wrap').offset().top;
    var height_of_question_wrapper = $('#grading_set_static_wrap').outerHeight(true);
    var width_of_question_wrapper = $('#grading_set_static_wrap').outerWidth(true);
    var height_of_question = $('.toggle_question_wrap').outerHeight(true);
    var clicked = false;
    var bottom_of_question = 0;
    var scroll_bottom;

    $(window).scroll(function () {
      scroll_bottom = $(document).height() - $(window).height() - $(window).scrollTop();
      if (scroll_bottom === 0) {
        return;
      }

      // Disable the fixed header if the Flagging Dialog is open for virtual chat or
      // composition/open ended activities with AI Feedback enabled.
      // Prevents the header (#grading_set_static_wrap) from overlapping the modal
      // and resets styles to ensure the modal is fully visible.
      if ($('.flagging-dialog').hasClass('is-open') || $('.ns-ai-chat-flag-suggestion-dialog').hasClass('is-open')) {
        $('#grading_set_static_wrap')
          .toggleClass('fix_at_top', false)
          .css('width', '');
        $('#student_answers').css('padding-top', '0');
        return;
      }

      if ($(window).scrollTop() > top_offset) {
        if (!clicked) {
          bottom_of_question = top_of_question + height_of_question_wrapper - $(window).scrollTop();
        } else {
          bottom_of_question = top_of_question + height_of_question_wrapper - $(window).scrollTop();
        }
        $('#student_answers').css('padding-top', bottom_of_question.toString() + 'px');
        $('#grading_set_static_wrap')
          .toggleClass('fix_at_top', true)
          .css( 'width', width_of_question_wrapper );
      } else {
        $('#student_answers').css('padding-top', '0');
        $('#grading_set_static_wrap')
          .toggleClass('fix_at_top', false) //replace static portion into normal flow
          .css('width','');
      }
    });

    //save this jquery selection as var to avoid redundant dom traversing
    var $toggle_question_control = $('.toggle_question_control');

    //control hover color with js b/c of browser bug where css hover colors hang on animate
    $toggle_question_control.hover(function () {
      $(this).css('background-color', '#DFF09F');
    }, function () {
      $(this).css('background-color', '#f5f5f5');
    });

    //hide question on click
    $toggle_question_control.click(function () {
      clicked = true;
      if ($('.toggle_question_wrap').is(":visible")) {
        //hiding the question, return button bg color to normal
        $toggle_question_control.css('background-color', '#f5f5f5').html('<span class=\"arrow down\"></span>Show Question<span class=\"arrow down\"></span>');
        $('.toggle_question_wrap').animate({ height: 'toggle' }, { complete: function () {
          var current_padding = parseInt($('#student_answers').css('padding-top'));
          var new_padding = current_padding - height_of_question;
          if ($(window).scrollTop() > top_offset) {
            $('#student_answers').animate({'padding-top': new_padding}, "slow");
          }
          height_of_question_wrapper = $('#grading_set_static_wrap').outerHeight(true);
        }});
      } else {
        //showing the question, return button bg color to normal
        $toggle_question_control.css('background-color', '#f5f5f5').html('<span class=\"arrow up\"></span>Hide Question<span class=\"arrow up\"></span>');
        $('.toggle_question_wrap').animate({height: 'toggle'}, { complete: function () {
          var current_padding = parseInt($('#student_answers').css('padding-top'));
          var new_padding = current_padding + height_of_question;
          if ($(window).scrollTop() > top_offset) {
            $('#student_answers').animate({'padding-top': new_padding }, "slow");
          }
          height_of_question_wrapper = $('#grading_set_static_wrap').outerHeight(true);
        }});
      }
    });
  }

  /**
   * Set the default active instructor tool.
   */
  function initialize_tools() {
    $('#comment_tool').addClass('is-on');
  }

  function show_finish_spotchecking_modal() {
    if ($('#show_finish_spotchecking').val()) {
      $('#modal_box').dialog({
        title: $('#show_finish_spotchecking').attr('title'),
        modal: true,
        resizable: false,
        open: function (e, ui) {
          $('#modal_box').append("<div id='modal_spinner' style='position:absolute;top:15%;left:35%;'><img alt='page loading' src='/images/loading_32.gif'/></div>");
        }
      }).load($('#show_finish_spotchecking').attr('href'), function () {
        $('#modal_spinner').remove();
      });
    }
  }


  function toggle_original_response_hover() {
    $('.original_student_answer').each(function () {
      $(this).mouseover(function () {
        $(this).find('.hover_original_answer').removeClass('hidden_helper');
      }).mouseout(function () {
        $(this).find('.hover_original_answer').addClass('hidden_helper');
      });
    });
  }

  function bindCriteriaScoreListeners(group) {
    const rubricCriteriaScores = group.querySelectorAll('.js-rubric-criteria-score');
    const earnedVsTotalElm = group.querySelector('.js-earned-vs-total-points');
    const scoreFieldSelector = group.querySelector('.js-score-field');
    let earnedScore = 0.0;

    rubricCriteriaScores.forEach(scoreInput => {
      scoreInput.addEventListener('change', () => {
        earnedScore = sumCriteriaScores(group);
        earnedVsTotalElm.innerText = `${earnedScore}/${earnedVsTotalElm.dataset.pointsPossible}`;
        scoreFieldSelector.value = earnedScore;
      });
    });
  }

  function sumCriteriaScores(group) {
    let earnedScore = 0.0;
    group.querySelectorAll('.js-rubric-criteria-score').forEach(scoreInput => {
      if ((scoreInput.value ?? '').trim() !== '') {
        earnedScore += parseFloat(scoreInput.value);
      }
    });
    return earnedScore;
  }

  /**
   * Initialize the logic related to the selected grading method.
   * As a instructor change the grading method between rubric o manual,
   * that method persists to the next student.
   */
  function initGradingMethod() {

    /*
     * This is related to rubric quick grading controls where the
     * instructor grade the activity with a percentage of zero or one hundred
     * percent by listening to the event of two links to grade.
     */
    function quickGradingControlsPerRubric(group) {
      const rubricCriterias = group.querySelectorAll('.js-rubric-criteria');
      const earnedVsTotalElm = group.querySelector('.js-earned-vs-total-points');
      const noPointsLink = group.querySelector('.js-rubric-no-points');
      const fullPointsLink = group.querySelector('.js-rubric-full-points');
      const scoreFieldSelector = group.querySelector('.js-score-field');

      noPointsLink.addEventListener('click', () => {
        rubricCriterias.forEach((criteria) => {
          criteria.value = '0.0';
          criteria.classList.replace('u-txt-gray-a', 'u-txt-black');
        });
        noPointsLink.setAttribute('disabled', '');
        fullPointsLink.removeAttribute('disabled');
        scoreFieldSelector.value = 0;
        earnedVsTotalElm.innerText = `0/${earnedVsTotalElm.dataset.pointsPossible}`;
      });

      fullPointsLink.addEventListener('click', () => {
        rubricCriterias.forEach((criteria) => {
          criteria.value = criteria.dataset.maxScore;
          criteria.classList.replace('u-txt-gray-a', 'u-txt-black');
        });
        fullPointsLink.setAttribute('disabled', '');
        noPointsLink.removeAttribute('disabled');
        scoreFieldSelector.value = earnedVsTotalElm.dataset.pointsPossible;
        earnedVsTotalElm.innerText =
          `${earnedVsTotalElm.dataset.pointsPossible}/${earnedVsTotalElm.dataset.pointsPossible}`;
      });
    }
  }

  /**
   * Clear all scoring, both in rubric criteria scores and in manual grading.
   */
  function clearScores(group) {
    group.querySelectorAll('.js-score-field').forEach((score) => {
      score.value = null;
    });
  }

  function init() {
    initialize_grading_common();
    initialize_grading_sets();

    initialize_tools();

    toggle_original_response_hover();
    show_finish_spotchecking_modal();

    enable_editing_tools_toggle();
    enable_on_change_events();

    bind_credit_buttons();
    bind_comment_box_toggle();
    bind_student_names_toggle();

    initialize_static_header();

    if (document.querySelector('.rubric-graded')) {
      initGradingMethod();
    }


    /* Instructor created content does not limit length of the direction line. The grading view is broken
       in cases where the instructor has added a long direction line.

       Prompt user to view the activity direction line / instructions in the pop up activity view, when the
       height of instructions container exceeds 100px. */
    const prompt = document.querySelector('#activity_prompt');
    if (prompt && prompt.offsetHeight > 100) {
      prompt.textContent = 'Please click View Activity to view the instructions in a new window.'
    }

    // Dispatch event to init Froala's composition editor.
    document.dispatchEvent(initCompositionEditorEvent);
  }

  return {
    init: init,
    check_scores: check_scores
  };

})();

$(document).ready(function () {
  VHL.Grading.init();
});
