/**
 * @param {event} event - event object from manual date input.
 * @param {Object} opts - AssignmentSetsCalendarApp state.
 * Validates date input values on pattern & date range.
 * Updates store.calendar.dateRange.
 * Forces UI update on DateCalendar component via incrementing component's key.
 */
function handleDateInputEvent(event, opts) {
  const val = event.target.value;
  const rangePoint = event.target.name;
  // for testing MM/DD/YYYY format
  const datePattern = /^([0-9][0-9])\/[0-9][0-9]\/([0-9][0-9][0-9][0-9])$/;
  let dateObj;

  if (val === '') {
    return;
  }

  if (!datePattern.test(val)) {
    opts.inputErrors.format = true;
    return;
  } else if (!_isInCourseRange()) {
    opts.inputErrors.range = true;
    return;
  }

  opts.store.calendar.dateRange.start = _updateStartRange();
  opts.store.calendar.dateRange.end = _updateEndRange();

  /**
   * Updating the DatePicker component's key forces the DatePicker's UI to update
   * when the model is updated outside of itself.
   * https://github.com/nathanreyes/v-calendar/issues/389#issuecomment-1140165042
   */
  opts.datePickerKey.value++;

  /** local helper functions for handleDateInputEvent **/

  /**
   * @return {boolean} - whether or not the input value is in course range.
   */
  function _isInCourseRange() {
    /* input value is a string in MM/DD/YYYY format. */
    const dateArr = val.split('/').map((str) => parseInt(str));

    /* Date constructor takes 'YYYY', 'MM', 'DD' (month 0 indexed) */
    dateObj = new Date(dateArr[2], dateArr[0] - 1, dateArr[1]);

    return dateObj >= opts.courseStartDateObj && dateObj <= opts.courseEndDateObj;
  }

  /**
   * @return {date}
   * Updates start point of data store's date range
   */
  function _updateStartRange() {
    return rangePoint === 'start' ? dateObj : opts.store.calendar.dateRange.start;
  }

  /**
   * @return {date}
   * Updates end point of data store's date range
   */
  function _updateEndRange() {
    return rangePoint === 'end' ? dateObj : opts.store.calendar.dateRange.end;
  }
}

export {
  handleDateInputEvent,
};
