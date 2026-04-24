$(document).ready(function() {
  VHL.Common.prep_common_jquery_modal({});
  VHL.Resources.init();
});

VHL.Resources = (function() {

  var ui, rowHighlightClass, selectAllCheckboxesClass;

  function highlightRow(checkbox, newState) {
    checkbox.parents('tr').toggleClass(rowHighlightClass, newState);
  }

  /*

    Checkbox functions

  */

  /**
   * Gets state of a particular checkbox.
   *
   * @param  {string, HTMLElement, or jQuery}  checkbox
   * @return {Boolean} true if checked, false otherwise.
   */
  function isChecked(checkbox) {
    return $(checkbox).prop('checked');
  }

  /**
   * Set the checked value of a checkbox to true or false
   *
   * @param {string, HTMLElement, or jQuery}  checkbox
   * @param {boolean} newState - new state for checkbox.
   */
  function setChecked(checkbox, newState) {
    var thisCheckbox = $(checkbox);
    thisCheckbox.prop('checked', newState);
  }

  /**
   * Toggle the checked value of a checkbox.
   *
   * @param {string, HTMLElement, or jQuery}  checkbox
   */
  function toggleChecked(checkbox) {
    setChecked($(checkbox), !isChecked($(checkbox)));
  }

  /**
   * Returns true if one or more checkboxes, within the given context
   * element, are checked.
   *
   * @return {boolean}
   */
  function anyAreChecked() {
    return _.some(ui.resourceCheckboxes, function(element) {
      return isChecked($(element));
    });
  }

  /**
   * Returns array of checkboxes within the given context that are checked.
   *
   * @return {array of HTMLElements}
   */
  function checkedCheckboxes() {
    return _.filter(ui.resourceCheckboxes, function(element) {
      return isChecked($(element));
    });
  }

  /**
   * Gets locked visibility state of a resource.
   *
   * @param  {string, HTMLElement, or jQuery}  checkbox
   * @return {Boolean} true if locked, false otherwise.
   */
  function isLocked(element) {
    var button = $(element).parents('tr').find('.js-visibility-toggle');
    return (button.data('resource-visibility') === 'Never');
  }

  /**
   * Returns array of checkboxes within the given context that are NOT locked.
   *
   * @return {array of HTMLElements}
   */
  function onlyUnlocked(checkboxes) {
    return _.filter($(checkboxes), function(element) {
      return !isLocked($(element));
    });
  }

  /**
   * Returns array of checkboxes that are both checked and locked.
   *
   * @return {array of HTMLElements}
   */
  function allSelectedAreLocked() {
    return _.every(checkedCheckboxes(), function(element) {
      return isLocked($(element));
    });
  }

  /**
   * Sets all checkboxes within the given context to the given state.
   *
   * @param {boolean} newState - new state for checkbox.
   */
  function setAllCheckboxes(newState) {
    var $checkbox;
    ui.resourceCheckboxes.each(function() {
      $checkbox = $(this);
      setChecked($checkbox, newState);
      highlightRow($checkbox, newState);
    });
  }

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


  /*

    Main Resources view

  */

  /**
   * Attach event handlers to checkboxes.
   *
   */
  function bindCheckboxes() {
    // Bind "select all"
    ui.selectAllCheckbox.on('click', function(event) {
      handleSelectAllCheckboxesToggle($(event.target));
    });

    // Bind individual checkboxes
    ui.resourceCheckboxes.on('click', function(event) {
      handleCheckboxToggle($(event.target));
    });
  }

  function updateActionsAndMessages() {
    updateResourceActions();
    resource_message();
    $('#resource_flash_warning').hide();
  }

  /* Handle app logic when select-all checkbox is toggled */
  function handleSelectAllCheckboxesToggle(checkbox) {
    var newSelectAllState = isChecked($(checkbox));
    setAllCheckboxes(newSelectAllState);
    updateActionsAndMessages();
  }

  /* Handle app logic when individual checkbox is toggled */
  function handleCheckboxToggle(checkbox) {
    var $checkbox = $(checkbox);
    setChecked(ui.selectAllCheckbox, false);
    highlightRow($checkbox, isChecked($checkbox));
    updateActionsAndMessages();
  }


  /**
   *  Attach event to buttons to toggle the visibility
   *  of a single resource
   *
   */
  function bindVisibilityToggles() {
    $('.js-visibility-toggle').on('click', (e) => {
      e.preventDefault();
      const button = $(e.target);
      toggleVisibility(
        button.data('resource-id'),
        button.data('resource-visibility')
      );
    });

    $('.js-visibility-action').on('click', (e) => {
      const selection = onlyUnlocked(checkedCheckboxes());
      const selectedResourceIds = getSelectedIds(selection);
      const action = $(e.target).data('action');
      setResourceVisibility(selectedResourceIds, action);
    });
  }

  function toggleVisibility(resource, visibilityLabel) {
    var newState = (visibilityLabel === 'Yes') ? 'hidden' : 'shown';
    setResourceVisibility([resource], newState);
  }

  function bindDropdowns() {
    /* When selecting a unit/lesson, send the browser
     * to location stored in the option's value attr.
     */
    ui.lessonSwitcher.on('change', function() {
      window.location.href = $(this).find('option:selected').val();
    });

    $('[data-js-change="validate"]').change(function() {
      var unit = $(this).attr('data-js-unit');
      validate_unit(unit);
    });
  }

  function clearValidationInfo() {
    var unit_label = $('#valid_unit_label').attr('value');
    $("#last_" + unit_label + "_check").html("");
    $("#last_" + unit_label + "_container").attr("class", "");
    $("#last_" + unit_label + "_container").children("div").attr("class", "");
    $("#first_" + unit_label + "_check").html("");
    $("#first_" + unit_label + "_container").attr("class", "");
    $("#first_" + unit_label + "_container").children("div").attr("class", "");
  }

  /* Add/Edit Resource view: First/Last Lesson */
  function setUploadFile() {
    $('.js-file-input').on('change', function() {
      VHL.uploadable.file_container_switch('show');
    });
  }

  function toggleMultiLessonSelects() {
    var unit_label = $('#valid_unit_label').attr('value');
    var unitOptions = $('.js-unit-options');
    var selectedText = unitOptions.find('option:selected').text();
    if (selectedText === 'Multi-' + unit_label) {
      $('.js-multi-lesson-selects').removeClass('u-invisible');
    } else {
      $('.js-multi-lesson-selects').addClass('u-invisible');
      $('.js-start-unit', '.js-end-unit').find('option:selected').prop('selected', '');
      $('.js-start-unit').val(unitOptions.val().split('=')[1]);
      $('.js-end-unit').val('nil');
    }
  }

  function bindMultiLessonSelectsToUnitOptions() {
    $('.js-unit-options').change(function() {
      toggleMultiLessonSelects();
    });
    clearValidationInfo();
  }

  function getResourceID(elementId) {
    return elementId.replace('student_viewable_', '').replace('resource_', '').replace('_checkbox', '');
  }

  function initializeResourceHovers() {
    // Hovers
    if ($('#resources tr').length !== 0) {
      function makeHoverVisible() {
        $(this).find('.js-resource-description').removeClass('u-screen-reader-only');
      }

      function makeHoverHidden() {
        $(this).find('.js-resource-description').addClass('u-screen-reader-only');
      }

      var config = {
        over: makeHoverVisible,
        timeout: 250,
        out: makeHoverHidden
      };

      $('#resources tr').hoverIntent(config);

      // Hide tooltip on click:
      $('body').on('click', makeHoverHidden);
    }
  }

  function initialize_resource_links() {
    updateResourceActions();

    ui.downloadButton.click(function() {
      // link href will download files.
      setAllCheckboxes(false);
    });
  }

  function is_instructor() {
    if ($("#is_instructor").val() === "1") {
      return true;
    } else {
      return false;
    }
  }

  function updateVisibilityButton(cell, visible) {
    var $cell = $(cell);
    var $icon = $cell.find('.c-icon');
    var $button = $cell.find('.js-visibility-toggle');
    var $label = $icon.find('.js-visibility-label');
    const checked = (visible == "Yes");
    var visLabels = {
      'Yes': {title: 'Visible to students', classname: 'c-icon--visibility-on'},
      'No': {title: 'Hidden from students', classname: 'c-icon--visibility-off'}
    };

    /*
      IMPORTANT - These states & labels also need to be set in
      _resources_table.html.erb for the initial page rendering!
    */
    $icon
      .removeClass('c-icon--visibility-on  c-icon--visibility-off')
      .addClass(visLabels[visible].classname);

    $button
      .attr('title', visLabels[visible].title)
      .data('resource-visibility', visible)
      .prop('checked', checked);

    $label.text(visLabels[visible].title);
  }

  function refresh_resources(altered_resources, instructor_resource_setting_status, instructor_resource_setting_friendly_label) {
    $.each(altered_resources, function(index, altered_resource_id) {
      var cell_id = 'student_viewable_status_for_resource_' + altered_resource_id;
      var cell_to_update = $('#' + cell_id);
      updateVisibilityButton(cell_to_update, instructor_resource_setting_friendly_label);
    });

    updateResourceActions();
  }

  function resource_message() {
    var someChecked = anyAreChecked();

    $('.js-resource-message').toggleClass('u-screen-reader-only', someChecked);

    // TODO: Attach the handlers ONCE, and do the check only INSIDE the handler.
    if (!someChecked) {
      ui.visibilityActionButtons
        .on('mouseover focusin', function(){
          $('.js-resource-message').toggleClass('u-screen-reader-only', true);
        })
        .on('mouseout focusout', function(){
          $('.js-resource-message').toggleClass('u-screen-reader-only', false);
        });
    } else {
      ui.visibilityActionButtons.off('mouseover focusin mouseout focusout');
    }
  }

  /**
   * Gathers the IDs of all the selected resources.
   *
   * @param  {jQuery} checkboxes - jQuery object referencing all resource checkboxes.
   * @return {Array of strings}  list of selected IDs
   */
  function getSelectedIds(checkboxes) {
    return _.map(checkboxes, function(element) {
      return getResourceID(element.id);
    });
  }

  function setResourceVisibility(selectedResourceIds, status) {
    var instructor_id = $('#instructor_id').val();
    var url = $('#show_to_students_link_base_url').val();
    var params = "selected_resources=" + selectedResourceIds.join(',')
        + "&user_id=" + instructor_id
        + "&instructor_setting_status=" + status;

    $.ajax({
      type: "post",
      url: url,
      data: params,
      dataType: 'json',
      success: function(data) {
        update_error_message("warning", data.warning_message);
        setAllCheckboxes(false); // needs to come before refresh_resources!
        refresh_resources(data.successful_resources, data.instructor_setting_status, data.friendly_label);
      },
      error: function(data) {
        var errors = $.parseJSON(data.responseText);
        update_error_message("warning", errors.warning_message);
        update_error_message("error", errors.error_message);
        refresh_resources(errors.successful_resources, errors.instructor_setting_status, errors.friendly_label);
      }
    });
  }

  function units_validation_error(validation_obj) {
    clearValidationInfo();
    var valid_unit_label = $("#valid_unit_label").val();
    var err_message, error_txt = '';
    var not_valid_icon = "<img src=\"/images/icon-unavailable.png\" width=\"18\" height=\"19\" alt=\"Invalid\" style=\"padding-right:5px\"/>";
    error_txt = (validation_obj === ('last_' + valid_unit_label) ? "Last " + valid_unit_label + " must be after First " + valid_unit_label : "First " + valid_unit_label + " must be before Last " + valid_unit_label);
    err_message = not_valid_icon + error_txt;
    $("#" + validation_obj + "_check").html(err_message);
    $("#" + validation_obj + "_container").attr("class", "fieldWithErrors");
  }

  function update_error_message(error_type, message) {
    var error_id = "#resource_flash_" + error_type;
    if (message !== '') {
      $(error_id).html(message);
      $(error_id).show();
    } else {
      $(error_id).html('&nbsp;');
      $(error_id).hide();
    }
  }

  function updateResourceActions() {
    var noneChecked = !anyAreChecked();
    var allLocked = allSelectedAreLocked();
    if (is_instructor()) {
      setDisabled(ui.visibilityActionButtons, noneChecked || allLocked);
    }

    setDisabled(ui.downloadButton, noneChecked, 'You must first select a resource.');
    updateDownloadButton();
  }

  function updateDownloadButton() {
    var selected_resources_ids, base_url, resource_id;

    if (anyAreChecked()) {
      base_url = $('#download_selected_resources_link_base_url').val();
      selected_resources_ids = getSelectedIds(checkedCheckboxes());

      ui.downloadButton.attr('href', base_url + '?selected_resources='
          + selected_resources_ids.join(','));
    }
  }

  function validate_unit(obj) {
    var unit_label = $('#valid_unit_label').attr('value');
    clearValidationInfo();
    if (!validate_unit_range()) {
      if (obj === ('last_' + unit_label) || obj === ('first_' + unit_label)) {
        units_validation_error(obj);
      }
    }
  }

  function validate_unit_range() {
    var unit_label = $('#valid_unit_label').attr('value');
    var lesson_range = $('#unit_options').attr('value');
    var start_unit = parseInt($('#resource_first_' + unit_label).attr('value'));
    var end_unit = parseInt($('#resource_last_' + unit_label).attr('value'));
    return (lesson_range === "single_unit") || (end_unit !== '' && (start_unit <= end_unit));
  }

  /* In order to have a floating table headers for the resources table, it's necessary
   * to define two tables (one in index.html.erb and the other in _resourses_list.html.erb).
   * Due to this need, we have to bind the clicks made in the first table, which contains
   * the table titles, and trigger the click in the second table, which contains the
   * resources data.
   * TODO: Combine both resources floating headers and resources data tables (index.html.erb & _resources_list.html.erb.
   */
  function addSortToTableHeaders() {
    $('.js-sort-col').on('keydown', (event) => {
      if (event.which === VHL.UI.Keys.ENTER || event.which === VHL.UI.Keys.SPACE) {
        event.preventDefault();
        event.target.click();
      }
    });

    $('.js-sort-col').on('click', (event) => {
      const $clickedSortableHeader = $(event.target);
      const $allSortableHeaders = $('.js-sort-col');
      const $resourcesTableCaption = $('.js-resource-table-caption');

      $allSortableHeaders.removeClass('is-active');
      $clickedSortableHeader.addClass('is-active');

      // a11y - update table sorting order for screen reader
      const sortOrder = $clickedSortableHeader.hasClass('sorting-asc') ? 'descending' : 'ascending';
      $allSortableHeaders.attr('aria-sort', 'none');
      $clickedSortableHeader.attr('aria-sort', sortOrder);
      $resourcesTableCaption.text(`Sorted by ${event.target.innerText} : ${sortOrder}`);
      setTimeout(() => {
        $resourcesTableCaption.html('');
      }, 2000);
    });

    ui.resourceTable.stupidtable();
  }

  /* There are 3 dropdows in the new/edit form. the first one,
   *  unit-options, is used to display/hide start unit and end unit
   *  on multi unit resources, so, the dropdown value is no persisted.
   *  General Resources is not a valid unit per se, so, we need to add this
   *  option "hidden" in start unit dropdown. This unit is not available
   *  on every book, so, we need to the its existance before trying to do
   *  anything with it.
   * */
  function addGeneralResourcesOption() {
    var generalResourcesID;
    var newOption;
    var unitOption = $('.js-unit-options option').filter(function() {
      return $(this).html() === 'General Resources';
    });

    if (unitOption.length > 0) {
      generalResourcesID = unitOption.val().split('=')[1];
      newOption = $('<option>').text('General Resources')
        .val(generalResourcesID)
        .addClass('u-hidden');
      $('.js-start-unit').append(newOption);
    }
  }

  /* Confirmation of Delete */
  function openDeleteConfirmation() {
    $('.js-delete-btn').on('click', (e) => {
      $(e.currentTarget).siblings('.js-confirm-delete').vhlModal('open');
    });
  }

  function registerNavDisclosure() {
    $('.js-resource-nav-disclosure, .js-resource-nav-disclosure-close').on('click', () => {
      $('.js-refine-elements').toggle();
      $('.js-resources-disclosure-icon').toggleClass('c-icon--down-arrow c-icon--up-arrow');
      window.scrollTo(0, 0);
    })
  }

  function restoreFocusFromQueryParam() {
    const urlParams = new URLSearchParams(window.location.search);

    const componentId = urlParams.get('component_id');
    const startUnitId = urlParams.get('start_unit_id') || urlParams.get('start_unit_id[]');

    if (componentId) {
      document.querySelector(`.js-component-filter-${componentId}`)?.focus();
    } else if (startUnitId) {
      document.querySelector('.js-select-lesson')?.focus();
    }
  }

  function init() {
    ui = {
      visibilityActionButtons: $('.js-visibility-action'),
      downloadButton: $('.js-download-rsrc-button'),
      resourceCheckboxes: $('.js-resource-checkbox'),
      selectAllCheckbox: $('.js-select-all-checkboxes'),
      lessonSwitcher: $('.js-select-lesson'),
      resourceTable: $('.js-resource-list')
    };

    rowHighlightClass = 'u-bg-selected';
    selectAllCheckboxesClass = 'js-select-all-checkboxes';

    // If we're on the add/edit screen
    if ($('.js-unit-options').length > 0) {
      setUploadFile();
      toggleMultiLessonSelects();
      bindMultiLessonSelectsToUnitOptions();
      addGeneralResourcesOption();
    } else { // index
      bindVisibilityToggles();
      bindCheckboxes();
      bindDropdowns();
      initialize_resource_links();
      initializeResourceHovers();
      openDeleteConfirmation();
      resource_message();
      addSortToTableHeaders();
      registerNavDisclosure();
    }

    restoreFocusFromQueryParam();
  }

  return {
    init: init,
    toggleMultiLessonSelects: toggleMultiLessonSelects,
    validate_unit: validate_unit
  };
})();
