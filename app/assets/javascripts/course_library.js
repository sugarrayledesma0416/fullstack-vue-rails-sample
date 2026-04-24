VHL = VHL || {};

VHL.InstructorCreatedActivitiesList = (function () {
  function bind_course_name_hover() {
    $('[data-page-element="my_content_activity_assigned_courses"]').hover(function () {
      $(this).find('[data-page-element="my_content_activity_course_names"]').removeClass('hidden_helper');
    }, function () {
      $(this).find('[data-page-element="my_content_activity_course_names"]').addClass('hidden_helper');
    });
  }

  function bind_close_event(import_dialog, element) {
    element.off("click");
    element.click(function (evt) {
      evt.preventDefault();
      import_dialog.dialog('close');
    });
  }

  function bind_new_activity_hovers() {
    var addContentLink = $('.create-activity-links');
    var submenu = addContentLink.find('.new-activity');
    var contentDropdown = addContentLink.find('.create-activity-dropdown');
    var activityLinksDropdown = addContentLink.find('.new-activity-links-container');

    function closeMenus() {
      contentDropdown.addClass('hidden_helper');
      activityLinksDropdown.addClass('hidden_helper');
    }

    // Hover menu to show/hide contents:
    addContentLink.hover(function () {
      contentDropdown.removeClass('hidden_helper');
    }, function () {
      contentDropdown.addClass('hidden_helper');
    });

    // Return key on menu toggles menu open/closed state:
    addContentLink.on('keydown', function(evt){
      if (evt.which === VHL.UI.Keys.ENTER) {
        // if closing, close both menu & submenu:
        if (contentDropdown.is(':visible')) {
          closeMenus();
        // otherwise, just the menu:
        } else {
          contentDropdown.toggleClass('hidden_helper');
        }
      }
    });

    // Close the menus when a leaf item is activated w/keyboard:
    activityLinksDropdown.find('.create-activity-link').on('keydown', function(evt){
      if (evt.which === VHL.UI.Keys.ENTER) {
        closeMenus();
      }
    });

    // Hover submenu to show/hide contents:
    submenu.hover(function () {
      activityLinksDropdown.removeClass('hidden_helper');
    }, function () {
      activityLinksDropdown.addClass('hidden_helper');
    });

    // Return key on submenu toggles submenu open/closed state:
    submenu.on('keydown', function(evt){
      if (evt.which === VHL.UI.Keys.ENTER) {
        activityLinksDropdown.toggleClass('hidden_helper');
        evt.stopPropagation();
      }
    });

    // ESC key closes menus:
    $(document).on('keydown', function(evt){
      if (evt.which === VHL.UI.Keys.ESC) {
        closeMenus();
      }
    });

  }

  function save_options_modal(dialog_container, copy_url) {
    const modal_content = $('[data-container="save_options"]').html();
    dialog_container.html(modal_content);
    const copy_link = dialog_container.find('[data-link="copy"]');
    const cancel_link = dialog_container.find('[data-link="cancel"]');

    copy_link.prop('href', copy_url);
    bind_close_event(dialog_container, cancel_link);
  }

  function initialize_modal(dialog_container, link, custom_content) {
    var course_library_dialog = dialog_container;
    var _dialog_options = {
      title: link.attr('title'),
      minHeight: 150,
      minWidth: 600,
      modal: true,
      position: 'center',
      resizable: false,
      open: function (e, ui) {
        custom_content;
      },
      close: function () {
        course_library_dialog.dialog('close');
        return false;
      }
    };
    course_library_dialog.dialog(_dialog_options);
  }

  function init() {
    var my_content_dialog_container = $('.js-my-content-container[data-modal="import_content"]');

    // Course Name Hover
    bind_course_name_hover();

    $(document).on('click', '.js-modal-delete-created-activity .js-modal-confirm', function () {
      let button = $(this);
      let form = button.closest('form');
      button.prop('disabled', true);
      form.submit();
    });

    // Copy as draft modal
    $('.js-copy-created-activity').click(function (evt) {
      evt.preventDefault();
      initialize_modal(my_content_dialog_container, $(this), save_options_modal(my_content_dialog_container, $(this).attr('href')));
    });

    // Bind new Activity Link
    bind_new_activity_hovers();
  }

  return {
    init: init
  };

})();

$(document).ready(function () {
  VHL.InstructorCreatedActivitiesList.init();
});
