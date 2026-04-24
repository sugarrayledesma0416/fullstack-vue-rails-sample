var VHL = VHL || {}

VHL.GradingTasks = (function(){

  var init = function() {
    // If Choosing a Grading Style
    initialize_grading_style_form();

    // If Selecting students to Spotcheck
    initialize_spotcheck();

    // If looking at Grading Tasks
    initialize_grading_tasks();
  }

  var bind_spotchecking_style = function() {
    // setup click event for spotcheck styles
    $('input.spotcheck_style').click(function(){
      $form = $('#spotcheck_style_form');
      $.ajax({
        type: $form.attr('method'),
        url: $form.attr('action'),
        data: $form.serialize()
      });
      $('.student_list').hide();
      $("#"+  $(this).val() +'_student_list').show();
    });
  }

  var bind_task_sections = function() {
    $('[data-js-link="task_section"]').click(function(){
      var task = $(this).attr('data-js-task');
      var program_id = $(this).attr('data-js-program-id');
      open_task_section(task, program_id);
    })
  }

  var confirm_select = function(set) {
    var selected = false;
    $('input.'+set+'_student_selector').each( function() {
      if($(this).is(':checked')) {
        selected = true;
      }
    });
    if(! selected) {
      alert('Please select some students for spotchecking!');
    }

    return selected;
  }

  var hide_task_sections = function() {
    var current_task = $.urlParam('task_type') || 'needs_grading_section'

    // hide all the task sections
    $('div#already_graded_section').addClass('hidden_helper');
    $('div#needs_grading_section').addClass('hidden_helper');
    $('div#upcoming_grading_section').addClass('hidden_helper');
    $('div#unassigned_activities_section').addClass('hidden_helper');
    // reveal the current task section
    $('div#'+current_task).removeClass('hidden_helper');

    $('li#unassigned_activities_section_header').find('a').css('border', 'none');
    $('li#unassigned_activities_section_header').find('.grading_numbers').css('border-bottom', 'none');
    $('li#unassigned_activities_section_header').find('.grading_numbers').css('height', '37px');
  }

  var highlight_spotchecking = function() {
    $('input.manual_student_selector').each(function() {
      if ($(this).is(':checked')) {
        $(this).parents('.students').addClass('highlight_bg');
      }
    });

    $('input.manual_student_selector').change(function() {
      if ($(this).is(':checked')) {
        $(this).parents('.students').addClass('highlight_bg');
      } else {
        $(this).parents('.students').removeClass('highlight_bg');
      }
    });

    $('[data-js-check="all_students"]').click(function() {
      if ($(this).is(':checked')) {
        $('input.manual_student_selector').each(function() {
          $(this).attr('checked', 'checked');
          $(this).parents('.students').addClass('highlight_bg');
        });
      } else {
        $('input.manual_student_selector').each(function() {
          $(this).removeAttr('checked');
          $(this).parents('.students').removeClass('highlight_bg');
        });
      }
    });

    // set highlighting for manual list
    $('#manual_student_list tr.students').removeClass('selected');

    // set highlighting for random and outliers lists
    $('select#select_num_of_random_students, select#select_num_of_outliers').change(function(){
      $form = $(this).parent('form');
      $.ajax({
        type: $form.attr('method'),
        url: $form.attr('action'),
        data: $form.serialize()
      });

      number_of_students = $(this).val();
      student_rows = $('#'+$(this).parents('.student_list').attr('id')+' tr.students');

      if (number_of_students == 'All') {
        student_rows.addClass('selected');
        student_rows.each(function(){
          $(this).find('input').prop('checked',true);
        });
      } else {
        student_rows.removeClass('selected');
        number_of_students = parseInt(number_of_students)
        curr_count = 0;
        student_rows.each(function(){
          if (curr_count < number_of_students) {
            $(this).addClass('selected');
            $(this).find('input').prop('checked',true);
            curr_count = curr_count + 1;
          } else {
            $(this).find('input').prop('checked',false);
          }
        });
      }
    });
  }

  var initialize_grading_style_form = function() {
    var initialFormState = $('#grading_style_form').serialize();

    // Form for choosing how to grade.
    $('input.grading_style').click(function(){
      var currentFormState = $('#grading_style_form').serialize();
      if (currentFormState !== initialFormState) {
        initialFormState = currentFormState; 
        $('form#grading_style_form').submit();
      }
    });

    $('#grading_style_form').submit(function() {
      $.ajax({
        data: $(this).serialize(),
        dataType: 'script',
        type: 'post',
        url: $(this).attr('action')
      });
      return false;
    });
  }

  var initialize_grading_tasks = function() {
    bind_task_sections();
    hide_task_sections();
  }

  var initialize_spotcheck = function() {
    show_spotcheck_active_list();
    bind_spotchecking_style();
    highlight_spotchecking();
  }

  var open_task_section = function(task_type, program_id) {
    var activities_class = 'instructor_task_activities';
    var section_class = 'grading_task_section';
    var auth_token = '';
    if (typeof(AUTH_TOKEN) != 'undefined') {
      auth_token = AUTH_TOKEN;
    }
    $.ajax({  url: '/instructor/to_do/' + program_id + '/assignments/activities_index',
              dataType: 'html',
              type: 'get',
              beforeSend: function() {
                $('#modal_spinner').remove();
                $('#grading_modal_box').append("<div id='modal_spinner' style='display:none;position:absolute;top:250px;left:35%;'><img alt='SS_icon_throbber' src='/images/loading_32.gif'</div>");
                $('#modal_spinner').show();
              },
              success: function(results){
                $('#modal_spinner').remove();
                $('div#' + task_type).siblings().addClass('hidden_helper');
                $('li#' + task_type + '_header').siblings().removeClass('expanded program-header-bar');
                $('li#'+task_type + '_header').addClass('expanded program-header-bar');
                $('li#'+task_type + '_header').find('a');
                $('div#'+task_type).removeClass('hidden_helper');
                $('div#'+task_type+'>div.'+activities_class).html(results).show();
              },
              data: {
                'task_type': task_type,
                'authenticity_token': encodeURIComponent(auth_token)
              }
    });
  }

  var show_spotcheck_active_list = function() {
    // show active list
    $('div.student_list').hide();
    $('input.spotcheck_style').each (function() {
      if($(this).is(':checked')) {
        $("#"+  $(this).val() +'_student_list').show();
      }
    });
  }

  var toggle_all_selection = function(row_class, checkbox) {
    if (checkbox.checked) {
      $('#manual_student_list tr.'+row_class).addClass('selected');
      $('input.manual_student_selector').prop('checked', true)
    } else {
      $('#manual_student_list tr.'+row_class).removeClass('selected');
      $('input.manual_student_selector').prop('checked', false)
    }
  }

  var toggle_row_style = function(selector, checkbox) {
    if (checkbox.checked) {
      $('#'+selector).addClass('selected');
    } else {
      $('#'+selector).removeClass('selected');
    }
  }

  return {
    init: init,
    confirm_select: confirm_select
  }

})();


$(document).ready(function() {
  VHL.GradingTasks.init();
});

