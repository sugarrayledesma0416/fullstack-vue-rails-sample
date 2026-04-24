$(document).ready(function(){
  VHL.Assessments.init();
});

VHL.Assessments = (function(){
  var init = function(){
    $(':not([disabled])[data-js-assess-link]').click(function(e) {
      var activity_id = $(this).attr('data-js-assignable-id');
      var update_type = $(this).attr('data-js-assess-link');
      update_assessment(activity_id, update_type);
      e.preventDefault();
    });
    let element = document.querySelector('.js-print-button');
    element && element.addEventListener('click', function() {
      printAssessment();
    });
  };

  var update_assessment = function(activity_id, update_type){
    var url = $('#show_assessments_url').val();
    var params = "assignments=" + $('#assessments_ids_for_activity_' + activity_id).val() + "&activity=" + activity_id + "&update_type=" + update_type;
    $.get( url, params,
      function( data ){
        VHL.Assessments.update_release_status(activity_id, update_type);
      }
    );
  };

  var update_release_status = function(activity_id, update_type){
    var link_container, status_container, assessment_label, format_assessment_label = "";
    switch(update_type){
      case 'assessment_release':
        link_container = "#release_date_time_for_assessment_";
        status_container = "#available_specifics_";
        assessment_label = "#format_assessment_label_activity_";
        format_assessment_label =  $(assessment_label + activity_id).val();
        break;
      case 'grade_release':
        link_container = "#grade_availability_time_for_assessment_";
        status_container = "#grade_available_specifics_";
        format_assessment_label = "Grades";
        break;
    }
    var released_status_link = $(link_container + activity_id);
    var assessment_show_status = $(status_container + activity_id);

    if ( released_status_link.children('a').text()== 'Release')
    {
      released_status_link.children('a').text('Hide');
      assessment_show_status.html('Yes');
    }
    else
    {
      released_status_link.children('a').text('Release');
      assessment_show_status.html('No');
    }
  };

  var displaySetTimeModal = function(url) {
    $.ajax({
      url: url,
      success: (data) => {
        $('.js-set-times').html(data);

        $('.js-modal-set-times').vhlModal('init');

        // Enable sorting
        const titles = $('.js-sort-col');
        titles.each((idx, title) => {
          $(title).click(function() {
            const $caret = $(title).find('.c-icon');
            const asc = $($caret).hasClass('c-icon--sort-asc');
            $caret.toggleClass('c-icon--sort-asc', !asc);
            $caret.toggleClass('c-icon--sort-desc', asc);
          });
        });
        $('.js-time-limits-table').stupidtable();

        // Show the time input if "Custom" is selected
        // Show the noentry icon if "Unlimited" is selected
        $('.js-limit-type').change(function() {
          const type = $(this).val();
          const $formItem = $($(this).parent().get(0));
          const $customInput = $formItem.siblings('.js-custom-limit');
          const $timeInput = $customInput.find('input');
          const $unlimitedIcon = $formItem.siblings('.js-unlimited-icon');

          // Restore Default state
          $timeInput.val('');
          $customInput.addClass('u-hidden');
          $unlimitedIcon.addClass('u-hidden');

          // Show input if Custom
          if(type == 'Custom') {
            const defaultTimeLimit = $('.js-default-time-limit').data('default-limit');
            $timeInput.val(defaultTimeLimit);
            $customInput.removeClass('u-hidden');

          // Show icon if Unlimited
          } else if(type == 'Unlimited') {
            $timeInput.val(0);
            $unlimitedIcon.removeClass('u-hidden');
          }
        });

        $('.js-submit-form').click(function(evt) {
          let url = $(this).data('url');
          evt.preventDefault();
          VHL.Assessments.submitTimeLimits(url);
        });

        $('.js-modal-set-times').vhlModal('open');
      }
    });
  };

  var submitTimeLimits = function(url) {
    let posting = $.post(url, $('.js-time-limits-form').serialize());

    posting.done((data) => {
      const successMsg = 'Updated time limits successfully';

      let flashNotice = `<div class="flash-notice  c-flash  c-flash--notice" id="flash_notice">
                            ${successMsg}
                         </div>`;
      $('.l-page-title-block').append(flashNotice);

      $('.js-modal-set-times').vhlModal('close');
    });

    posting.fail((data) => {
      const errors = JSON.parse(data.responseText);
      $('.js-errors').removeClass('u-hidden');
      for(let user_id in errors) {
        $(`.js-error-${user_id}`).html(errors[user_id]);
        $(`.js-custom-limit-${user_id}`).parent().addClass('c-form-item--error');
      }
    });
  };

  function alignQuestions(parentElement, childElement) {
    let fillInTheBlanks = document.querySelectorAll(parentElement)

    if(fillInTheBlanks.length > 0) {
      fillInTheBlanks.forEach((question) => {
        question.querySelectorAll(childElement).forEach((blank) => {
          blank.classList.remove('u-dis-inline-block');
        });
      });
    }
  }

  function addActivityTitle() {
    let activity_title = document.querySelector("[data-print-title]");
    activity_title.innerHTML = activity_title.getAttribute('data-print-title');
  }

  function printAssessment() {
    window.print();
  }

  return{
    init : init,
    update_assessment : update_assessment,
    update_release_status: update_release_status,
    displayModal: displaySetTimeModal,
    submitTimeLimits: submitTimeLimits,
    printAssessment: printAssessment
  }
})();
