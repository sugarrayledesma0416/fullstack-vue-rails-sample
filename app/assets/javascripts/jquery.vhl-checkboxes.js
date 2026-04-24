//= require content_library
VHL.Checkboxes = (function(){

  function isVisible(element) {
    return !element.parents('tr').hasClass('u-hidden');
  }

  function _toggle_checkbox(element, check_all){
    if (isVisible(element)) {
      element.toggleClass('show_check', check_all);
      element.attr('aria-checked', check_all);
      if (element.hasClass('toc_checkbox')) {
        $thisRow = element.parents('tr').toggleClass('highlight_bg', check_all);
        $thisRow = element.parents('li').toggleClass('highlight_bg', check_all);
      }
      VHL.ContentLibrary.show_hide_unhide_links();
    }
  }

  function _selected_activity_ids() {
    var selected_activity_ids = new Array();
    $('.toc_checkbox.show_check').each(function(index){
      if (isVisible($(this))) {
        activity_id = this.id.replace("activity_", "").replace("_checkbox", "");
        selected_activity_ids.push(activity_id);
      }
    });

    return selected_activity_ids;
  }

  function _set_ids() {
    var selected_activity_ids = _selected_activity_ids();

    base_url = $('#due_date_link_base_url').val();

    $('.set_date_link').attr('href', base_url + '&selected_activities=' + selected_activity_ids.join(','));
    $('.set_due_date_link').attr('href', base_url + '&selected_activities=' + selected_activity_ids.join(','));
  }

  function _time_estimate() {
    var estimated_time = 0;
    var individual_time = 0;
    var time_checked;
    var total_selected;

    $('.toc_checkbox.show_check').each(function(){
      individual_time = $(this).siblings('.activity_time').text();

      estimated_time += parseInt(individual_time);
    })

    var hours = Math.floor(estimated_time / 60);
    var minutes = (estimated_time % 60);

    if (hours == '0') {
      time_checked = minutes + "m";
    } else {
      time_checked = hours + "h " + minutes + "m";
    }

    total_selected = $('#total_selected').html();

    $('#total_selected').text(total_selected + time_checked);
  }

  function _total_checked() {
    var total_number_checked = 0;
    var language_checked = " activities, ";

    $('.toc_checkbox.show_check').each(function(){
      total_number_checked += 1;
    })

    if (total_number_checked == 1) {
      language_checked = " activity, ";
    }

    $('#total_selected').text(total_number_checked + language_checked);

    _time_estimate();

  }


  function vhl_group_checkboxes(options) {
    // Default page is the TOC.
    // TOC and Assessments have the same page structure, so they can use the same call (at least for now).
    // The other page is 'assignments' which is for Calendar Assigning.
    var defaults = {
      page: 'toc'
    };
    var options = $.extend(defaults, options);
    var o = options;

    // Check All Box
    $('.checkbox_program').on('click',function() {
      check_all = !$(this).hasClass('show_check');

      // If we're on the TOC
      var $activityTableWrapper = $('.js-activity-table-wrapper');

      if (o.page == 'toc') {
        if ($(this).hasClass('show_check')) {
          $activityTableWrapper.find('.results_table_hover_assign').addClass('hidden_helper');
          $(this).removeClass('show_check');
        } else {
          $activityTableWrapper.find('.results_table_hover_assign').removeClass('hidden_helper');
          $(this).addClass('show_check');
        }

        $activityTableWrapper.find('.checkbox_all').each(function(index){
           _toggle_checkbox($(this), check_all);
           component_class = $(this).attr('rel');
           $('.toc_checkbox.'+component_class).each(function(index){
             _toggle_checkbox($(this), check_all);
           });
        });
      }
      // If we're on the Calendar Assignment Page
      else if (o.page == 'assignments') {
        var activity_list = $('.unassigned_activities_list');

        if ($(this).hasClass('show_check')) {
          activity_list.find('.results_table_hover_assign').addClass('hidden_helper');
          $(this).removeClass('show_check');
        } else {
          activity_list.find('.results_table_hover_assign').removeClass('hidden_helper');
          $(this).addClass('show_check');
        }

        activity_list.find('.checkbox_all').each(function(index){
          _toggle_checkbox($(this), check_all);
          var lesson = $(this).parent().siblings('ul').find('.toc_checkbox');
          lesson.each(function(index){
            _toggle_checkbox($(this), check_all);
          });
        })

        _total_checked();

      }
      // Adjust Set Due Date Link
      if ($('.checkbox_program').hasClass('show_check')) {
          $('.set_date_link').disable_link_toggle({
            meth: 'enable'
          });
          _set_ids();
      } else {
          $('.set_date_link').disable_link_toggle({
            meth: 'disable',
            disable: 'You must first select an activity.'
          });
      }
    });

    // Toggle Group
    $('.checkbox_all').on('click', function(){
      $('.checkbox_program').removeClass('show_check');

      // If we're on the TOC
      if (o.page == 'toc') {
        check_all = !$(this).hasClass('show_check');

        var table_body = $(this).parents('table').find('tbody');

        if ($(this).hasClass('show_check')) {
            table_body.find('.results_table_hover_assign').addClass('hidden_helper');
            $(this).removeClass('show_check');
        } else {
            table_body.find('.results_table_hover_assign').removeClass('hidden_helper');
            $(this).addClass('show_check');
        }

        // Toggle relevant checkboxes
        component_class = $(this).attr('rel');
        $('.toc_checkbox.'+ component_class).each(function(index){
          _toggle_checkbox($(this), check_all);
        });
      }
      // If we're on Calendar Assignments
      else if (o.page == 'assignments') {
        check_all = !$(this).hasClass('show_check');

        var closest_list = $(this).parent().siblings('ul');

        if ($(this).hasClass('show_check')) {
          closest_list.find('.results_table_hover_assign').addClass('hidden_helper');
          $(this).removeClass('show_check');
        } else {
          closest_list.find('.results_table_hover_assign').removeClass('hidden_helper');
          $(this).addClass('show_check');
        }

        // Toggle relevant checkboxes
        var in_this_lesson = closest_list.find('.toc_checkbox');

        in_this_lesson.each(function(index){
          _toggle_checkbox($(this), check_all);
        });

        _total_checked();
      }

      // Set Assigning Link Status
      if ($('.checkbox_all').hasClass('show_check')) {
        $('.set_date_link').disable_link_toggle({
          meth: 'enable'
        });
      } else {
        $('.set_date_link').disable_link_toggle({
          meth: 'disable',
          disable: 'You must first select an activity.'
        });
      }
      _set_ids();
    });

    // Toggle Individual
    $('.toc_checkbox').on('click', function() {
      $('.checkbox_program').removeClass('show_check');
      _toggle_checkbox($(this));

      // If we're on the TOC
      if (o.page == 'toc') {
       $(this).parent().parent().parent().parent().siblings('thead').find('.checkbox_all').removeClass('show_check');
      }

      // If we're on Calendar Assignments
      else if (o.page == 'assignments') {
        $(this).parent().parent().parent().siblings('.lesson_name').find('.checkbox_all').removeClass('show_check');

        _total_checked();
      }

      // Same structure for both
      if ($(this).hasClass('show_check')) {
        $(this).siblings('.results_table_hover').find('.results_table_hover_assign').removeClass('hidden_helper');
        $('#hover_holder').find('.results_table_hover_assign').removeClass('hidden_helper');
      } else {
        $(this).siblings('.results_table_hover').find('.results_table_hover_assign').addClass('hidden_helper');
        $('#hover_holder').find('.results_table_hover_assign').addClass('hidden_helper');
      }

      // Set assigning Link Status
      if ($('.toc_checkbox').hasClass('show_check')) {
        $('.set_date_link').disable_link_toggle({
          meth: 'enable'
        });
         _set_ids();
      } else {
        $('.set_date_link').disable_link_toggle({
          meth: 'disable',
          disable: 'You must first select an activity.'
        });
      }
    });
  }

  function makeAccessible() {
    let $checkboxes = $('.checkbox_program, .checkbox_all, .toc_checkbox');

    $checkboxes.attr({
        'tabIndex': '0',
        'role': 'checkbox'
    });

    $checkboxes.on('keydown', (evt) => {
      // spacebar
      if (evt.which === 32) {
        let $el = $(evt.target);
        evt.preventDefault();
        _toggle_checkbox($el, !$el.hasClass('show_check'));
      }
    });

    $('.checkbox_all').each((index, el) => {
      let $el = $(el);
      let labelId = $el.attr('rel') + '-label';
      $el.attr('aria-labelledby', labelId);
    });
  }


  return {
    _toggle_checkbox: _toggle_checkbox,
    _set_ids: _set_ids,
    _time_estimate: _time_estimate,
    _total_checked: _total_checked,
    _selected_activity_ids: _selected_activity_ids,
    vhl_group_checkboxes: vhl_group_checkboxes,
    makeAccessible: makeAccessible
  }

})();
