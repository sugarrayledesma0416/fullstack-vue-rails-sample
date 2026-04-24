var VHL = VHL || {};

VHL.ContentLibrary = (function() {
  function init() {
    var program_id = $('meta[name="VHL.program_id"]').attr('content');
    var section_id = $('meta[name="VHL.section_id"]').attr('content');
    var activity_link;

    $('[data-activity-view="hide"]').click(function () {
      _hide_activity_with_confirmation(program_id, section_id);
      return false;
    });

    $('[data-activity-view="show"]').click(function(){
      unhide_activity(program_id, section_id);
      return false;
    });
  }

  function set_due_date_cell_on_activities(activity_ids, action) {
    var cell_content;
    _.each(activity_ids, function(activity_id) {
      cell_content = set_due_date_cell_content(action, activity_id);
      $("#due_date_cell_for_activity_id_" + activity_id).html(cell_content);
    });
  }

  function set_due_date_cell_content(action, activity_id) {
    var content = '';
    if (action === 'hide') {
      content = '<div class="toc_activity_due_date">hidden</div>';
    } else if (_activity_is_assigned(activity_id)) {
      var due_date = $("#due_date_cell_for_activity_id_" + activity_id + " .toc_activity_due_date").html();
      content = '<div class="toc_activity_due_date">' + due_date + '</div>';
    }
    return content;
  }

  function hide_visible_links_for_activities(activity_ids) {
    _.each(activity_ids, function(activity_id) {
      var visible_link = $('.make_invisible[data-activity-id="' + activity_id + '"]');
      visible_link.addClass('hidden_helper');
      visible_link.siblings('.make_visible').removeClass('hidden_helper');
    });
  }

  function show_visible_links_for_activities(activity_ids) {
    _.each(activity_ids, function(activity_id) {
      var invisible_link = $('.make_visible[data-activity-id="' + activity_id + '"]');
      invisible_link.addClass('hidden_helper');
      invisible_link.siblings('.make_invisible').removeClass('hidden_helper');
    });
  }

  function show_visible_and_hide_links_for_activities(activity_ids) {
    _.each(activity_ids, function(activity_id) {
      var invisible_link = $('.make_visible[data-activity-id="' + activity_id + '"]');
      invisible_link.removeClass('hidden_helper');
      invisible_link.siblings('.make_invisible').removeClass('hidden_helper');
    });
  }

  function _hide_activity(program_id, section_id) {
    var activity_ids = VHL.Checkboxes._selected_activity_ids();

    $.post('/instructor/' + program_id + '/activities/hide',
          { activity_id: activity_ids, section_id: section_id }).done( function(data) {
              set_due_date_cell_on_activities(activity_ids, 'hide');
              hide_visible_links_for_activities(activity_ids);
            });
  };

  function unhide_activity(program_id, section_id) {
    var activity_ids = VHL.Checkboxes._selected_activity_ids();

    $.post('/instructor/' + program_id + '/activities/unhide',
          { activity_id: activity_ids, section_id: section_id }).done( function(data) {
              set_due_date_cell_on_activities(activity_ids, 'show');
              show_visible_links_for_activities(activity_ids);
            });
    return false;
  };

  function show_hide_unhide_links() {
    var activity_ids = VHL.Checkboxes._selected_activity_ids();
    var any_hidden_selected = _any_hidden_selected();
    var any_selected_visible = _.some(activity_ids, function(activity_id) {
      return $('#due_date_cell_for_activity_id_' + activity_id + ' .toc_activity_due_date').html() !== 'hidden';
    });
    if (any_hidden_selected && any_selected_visible){
      show_visible_and_hide_links_for_activities(activity_ids);
    } else {
      if (any_hidden_selected) {
        hide_visible_links_for_activities(activity_ids);
      }
      if (any_selected_visible) {
        show_visible_links_for_activities(activity_ids);
      }
    }
  }

  function _any_hidden_selected() {
    var activity_ids = VHL.Checkboxes._selected_activity_ids();
    return _.some(activity_ids, function (activity_id) {
      return $('#due_date_cell_for_activity_id_' + activity_id + ' .toc_activity_due_date').html() === 'hidden';
    });
  }

  function _any_assigned_activity_selected() {
    var activity_ids = VHL.Checkboxes._selected_activity_ids();
    return _.some(activity_ids, function (activity_id) {
      return _activity_is_assigned(activity_id);
    });
  }

  function _activity_is_assigned(activity_id) {
    // if is not empty and hidden means is an assigned activity
    var elm = $('#due_date_cell_for_activity_id_' + activity_id + ' .toc_activity_due_date').html();
    return !_.isNull(elm) && elm !== 'hidden';
  }

  function hide_activity_modal(program_id, section_id) {
    var content_library = $('[data-modal="content_library"]');

    content_library.dialog({
      resizable: false,
      modal: true,
      width: 400,
      position: 'center',
      title: 'Hiding assigned content',
      open: function () {
        var content_library_container = content_library.parent();
        content_library_container.removeClass('assign-hidden').addClass('hide-assigned');
        content_library.find('.notice').text('Assigned activities will become unassigned when hidden from student view');
        content_library_container.find('.ui-dialog-buttonset').prepend('<a href="#" class="cancel-link">cancel</a>');
        content_library_container.find('.cancel-link').click(function (event) {
          event.preventDefault();
          content_library.dialog('close');
        });
      },
      buttons: {
        'Ok': {
          text: 'Ok',
          class: 'submit',
          click: function () {
            VHL.ContentLibrary._hide_activity(program_id, section_id);
            content_library.dialog('close');
          }
        }
      }
    });
  }

  function _hide_activity_with_confirmation(program_id, section_id) {
    if (VHL.ContentLibrary._any_assigned_activity_selected()) {
      hide_activity_modal(program_id, section_id);
    } else {
      VHL.ContentLibrary._hide_activity(program_id, section_id);
    }
  }

  function assignment_wizard(assignment_link) {
    if (VHL.ContentLibrary._any_hidden_selected()) {
      var content_library = $('[data-modal="content_library"]');

      content_library.dialog({
        resizable: false,
        modal: true,
        width: 400,
        position: 'center',
        title: 'Assigning hidden content',
        open: function () {
          var content_library_container = content_library.parent();
          content_library_container.removeClass('hide-assigned').addClass('assign-hidden');
          content_library.find('.notice').text('All assigned activities will become visible to students.');
          content_library_container.find('.ui-dialog-buttonset').prepend('<a href="#" class="cancel-link">cancel</a>');
          content_library_container.find('.cancel-link').click(function (event) {
            event.preventDefault();
            content_library.dialog('close');
          });
        },
        buttons: {
          'Ok': {
            text: 'Ok',
            class: 'submit',
            click: function () {
              content_library.dialog('close');
              $(assignment_link).assignment_wizard();
            }
          }
        }
      });
    } else {
      $(assignment_link).assignment_wizard();
    }
  }

  return {
    init: init,
    show_hide_unhide_links: show_hide_unhide_links,
    assignment_wizard: assignment_wizard,
    _hide_activity_with_confirmation: _hide_activity_with_confirmation,
    _any_hidden_selected: _any_hidden_selected,
    _any_assigned_activity_selected: _any_assigned_activity_selected,
    _hide_activity: _hide_activity
  }

}());

$(document).ready(function() {
  VHL.ContentLibrary.init();
});
