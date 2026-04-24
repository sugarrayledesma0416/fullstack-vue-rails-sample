var VHL = VHL || {};

VHL.LateWork = function () {
  function selectedAssignmentCount() {
    var assignmentCount = 0;
    $('[name="score_ids[]"]').each(function () {
      if ($(this).val() !== '') {
        assignmentCount ++;
      }
    });
    return assignmentCount;
  }

  function updateStudentRow(checkbox) {
    var globalCheckbox = $('.js-checkbox-all');
    var globalAssignmentCount = $('[name="score_ids[]"]').length;
    var globalSelectedAssignmentCount = selectedAssignmentCount();
    var studentId = $(checkbox).data('student-id');
    var selectorSuffix = 'student-' + studentId;
    var assignmentCountSpan = $('[data-' + selectorSuffix + '-assignment-count]');
    var assignmentCount = $(assignmentCountSpan).data(selectorSuffix + '-assignment-count');
    var studentCheckbox = $('.js-student-checkbox[data-student-id="' + studentId + '"]');
    var studentAssignmentCount = 0;
    $('[data-' + selectorSuffix + '-score-id-hidden]').each(function () {
      if ($(this).val() !== '') {
        studentAssignmentCount ++;
      }
    });
    toggleCheckBox(globalCheckbox, (globalAssignmentCount === globalSelectedAssignmentCount));
    toggleCheckBox(studentCheckbox, (studentAssignmentCount !== 0))
    toggleCheckboxRowHighlight(studentCheckbox, studentAssignmentCount !== 0);
    $(assignmentCountSpan).text('(' + studentAssignmentCount + ' selected)');
    $(assignmentCountSpan).toggleClass('is-invisible', (studentAssignmentCount === assignmentCount));
  }

  /**
   * toggleCheckBox(checkbox, check)
   * - Adds/removes show_check css class to the given checkbox div, depending
   *   on the value of check
   * - Adds/removes highlight_bg css class to the parent tr element
   *   of checkbox, depending on the value of check
   * @checkbox {Element} any checkbox div element
   * @check {Boolean}
   */
  function toggleCheckBox(checkbox, check) {
    if (check) {
      $(checkbox).attr('aria-checked', '');
    } else {
      $(checkbox).removeAttr('aria-checked');
    }
    $(checkbox).toggleClass('show_check', check);
  }

  function toggleCheckBoxRow(checkbox, check) {
    toggleCheckBox(checkbox, check);
    toggleCheckboxRowHighlight(checkbox, check);
  }

  function toggleCheckboxRowHighlight(checkbox, check) {
    $(checkbox).parents('tr').toggleClass('highlight_bg', check);
  }

  /**
   * toggleStudentRow(studentCheckbox, check)
   * - Calls toggleCheckBox passing studentCheckbox and check in
   * - Finds all score cehboxes for the student and calls toggleScoreRow on them.
   * @studentCheckbox {Element} student row checkbox div element
   */
  function toggleStudentRow(studentCheckbox, check) {
    var studentId = $(studentCheckbox).data('student-id');
    var selectorSuffix = 'student-' + studentId + '-score-id';
    toggleCheckBox(studentCheckbox, check);
    $('[data-' + selectorSuffix + ']').each(function () {
      toggleScoreRow(this, check);
    });
    updateStudentRow(studentCheckbox);
  }

  /**
   * toggleScoreRow(scoreCheckbox, check)
   * - Calls toggleCheckBox passing scoreCheckbox and check in
   * - Calls toggleHiddenFields passing in the scoreId value
   *   set in its data-student-<id>-score-id attribute
   * @scoreCheckbox {Element} score (assignment) row checkbox div element
   * @check {Boolean}
   */
  function toggleScoreRow(scoreCheckbox, check) {
    var studentId = $(scoreCheckbox).data('student-id');
    var scoreId = $(scoreCheckbox).data('student-' + studentId + '-score-id');
    toggleCheckBoxRow(scoreCheckbox, check);
    toggleHiddenFields(scoreId, check);
  }

  /**
   * toggleHiddenFields(scoreId, check)
   * - Sets/removes the passed in scoreId as value for the score hidden field,
   *   depending on the value of check
   * @scoreId {Integer} score id
   * @check {Boolean}
   */
  function toggleHiddenFields(scoreId, check) {
    $('.js-score-ids-' + scoreId).each(function () {
      if (check) {
        $(this).val(scoreId);
      } else {
        $(this).val('');
      }
    });
  }

  function pluralize(word, count) {
    if (count > 1) {
      return word + 's';
    } else {
      return word;
    }
  }

  function checkValue(checkbox) {
    return !($(checkbox).attr('aria-checked') !== undefined)
  }

  $('.js-collapse-click').on('click', function () {
    var studentId = $(this).data('student-id');
    $('[data-score-student-row="' + studentId + '"]').each(function () {
      $(this).toggleClass('u-hidden');
    });
    $(this).parents('tr').find('.js-disclosure').toggleClass('is-closed');
  });

  $('.js-checkbox-all').on('click', function () {
    var check = checkValue(this);
    toggleCheckBox(this, check)
    $('.js-student-checkbox').each(function () {
      toggleStudentRow(this, check);
    });
  });

  $('.js-student-checkbox').on('click', function () {
    toggleStudentRow(this, checkValue(this));
  });

  $('.js-score-checkbox').on('click', function () {
    toggleScoreRow(this, checkValue(this));
    updateStudentRow(this);
  });

  $('[data-score-student-row]').each(function () {
    $(this).addClass('u-hidden');
  });

  $('.js-accept-late-work').on('click', function() {
    var assignmentCount = selectedAssignmentCount();
    var studentCount = 0;
    var studentId = 0;
    var studentIds = [];
    var message, assignmentText, studentText = '';
    var dialogContainer = $('.js-accept-late-work-dialog');
    var lateWorkForm = $('.js-late-work-form');

    $('[name="score_ids[]"]').each(function () {
      if ($(this).val() !== '') {
        studentId = $(this).parent().find('.js-score-checkbox').data('student-id')
        if (!_.contains(studentIds, studentId)) {
          studentIds.push(studentId);
          studentCount ++;
        }
      }
    });

    assignmentText = 'Accept ' + assignmentCount + ' ' + pluralize('assignment', assignmentCount);
    studentText = ' from ' + studentCount + ' ' + pluralize('student', studentCount) + '?';
    message = assignmentText + studentText;

    $('.js-accept-button').click(function() {
      dialogContainer.addClass('u-hidden');
      lateWorkForm.submit();
    });

    $('.js-cancel-button').click(function() {
      dialogContainer.addClass('u-hidden');
      return false;
    });

    if (assignmentCount === 0) {
      lateWorkForm.submit();
    } else {
      dialogContainer.removeClass('u-hidden');
      dialogContainer.find('.js-message').html(message);
      return false;
    }
  });
};

$(document).ready(function () {
  VHL.LateWork();
});
