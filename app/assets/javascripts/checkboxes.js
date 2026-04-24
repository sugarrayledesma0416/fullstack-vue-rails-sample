/*

  Checkboxes - Music version

  * Can be used for any set of checkboxes, with or without a
    "select all" checkbox.

  * If a checked checkbox is inside a table row, the row will 
    be assigned the .is-active class for highlight styling.

  Copied from resources.js. 
  TODO: refactor Resources to 
  use this version and remove the one baked into resources.js.

*/

$(document).ready(function() {
  VHL.Music.Checkboxes.init();
});

VHL.Music.Checkboxes = (function() {

  var ui, rowHighlightClass;

  function highlightRow(checkbox, newState) {
    checkbox.parents('tr').toggleClass(rowHighlightClass, newState);
  }

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
   * Count the number of checked checkboxes.
   */
  function checkedCount() {
    return checkedCheckboxes().length;
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
    return _.some(ui.checkboxes, function(element) {
      return isChecked($(element));
    });
  }

  /**
   * Returns array of checkboxes within the given context that are checked.
   *
   * @return {array of HTMLElements}
   */
  function checkedCheckboxes() {
    return _.filter(ui.checkboxes, function(element) {
      return isChecked($(element));
    });
  }

  /**
   * Sets all checkboxes within the given context to the given state.
   *
   * @param {boolean} newState - new state for checkbox.
   */
  function setAllCheckboxes(newState) {
    var $checkbox;
    ui.checkboxes.each(function() {
      $checkbox = $(this);
      setChecked($checkbox, newState);
      highlightRow($checkbox, newState);
    });
  }

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
    ui.checkboxes.on('click', function(event) {
      handleCheckboxToggle($(event.target));
    });
  }

  function setInitialHighlights() {
    $('.js-checkbox-row').removeClass('is-active');
    $('.js-checkbox:checked').parents('.js-checkbox-row').addClass('is-active');
  }

  function handleSelectAllCheckboxesToggle(checkbox) {
    var newSelectAllState = isChecked($(checkbox));
    setAllCheckboxes(newSelectAllState);
  }

  function handleCheckboxToggle(checkbox) {
    var $checkbox = $(checkbox);
    setChecked(ui.selectAllCheckbox, false);
    highlightRow($checkbox, isChecked($checkbox));
  }

  function init() {
    ui = {
      checkboxes: $('.js-checkbox'),
      selectAllCheckbox: $('.js-select-all-checkboxes')
    };

    rowHighlightClass = 'is-active';
    bindCheckboxes();
    setInitialHighlights();
  }

  return {
    init: init,
    checkedCheckboxes: checkedCheckboxes,
    checkedCount: checkedCount
  };
})();
