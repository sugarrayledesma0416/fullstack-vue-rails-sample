import {
  firstDayOfMonthFromDate,
  lastDayOfMonthFromDate,
  dateFromCourseDateString,
  dateInSectionTimezone,
} from 'shared/date_utils';

/** Class representing an Assignment Sets Calendar main model. */
class AssignmentSetsCalendar {
  /**
   * Instantiate the AssignmentSetsCalendar class.
   * @constructor
   * @param {String} courseStartDateString - string representing the selected section's start date
   * @param {String} courseEndDateString - string representing the selected section's end date
   */
  constructor(courseStartDateString, courseEndDateString) {
    this.courseStartDate = dateFromCourseDateString(courseStartDateString);
    this.courseEndDate = dateFromCourseDateString(courseEndDateString);
  }

  /**
   * Retrieve date that will be the earliest selected on the datepicker
   * @return {Date}
   */
  firstSelectedDate() {
    const firstDayOfMonth = firstDayOfMonthFromDate(dateInSectionTimezone(new Date()));

    return firstDayOfMonth < this.courseStartDate ? this.courseStartDate : firstDayOfMonth;
  }

  /**
   * Retrieve date that will be the latest selected on the datepicker
   * @return {Date}
   */
  lastSelectedDate() {
    const lastDayOfMonth = lastDayOfMonthFromDate(dateInSectionTimezone(new Date()));

    return lastDayOfMonth > this.courseEndDate ? this.courseEndDate : lastDayOfMonth;
  }

  /**
   * Retrieve datepicker component attributes
   * @return {Array}
   */
  attributes() {
    return [{
      dates: [
        { start: this.firstViewableDate(), end: this.courseStartDate },
        { start: this.courseEndDate, end: this.lastViewableDate() },
      ],
      popover: {
        label: 'Date must be between the course start and end date.',
        visibility: 'click',
      },
    }];
  }

  /**
   * Retrieve formatted object for app component
   * @return {Object}
   */
  forComponent() {
    return {
      dateRange: {
        start: this.firstSelectedDate(),
        end: this.lastSelectedDate(),
      },
      attributes: this.attributes(),
      courseStartDate: this.courseStartDate,
      courseEndDate: this.courseEndDate,
    };
  }

  /**
   * Retrieve date that will be the first viewable in the datepicker
   * @return {Date}
   */
  firstViewableDate() {
    return firstDayOfMonthFromDate(this.courseStartDate);
  }

  /**
   * Retrieve date that will be the last viewable in the datepicker
   * @return {Date}
   */
  lastViewableDate() {
    return lastDayOfMonthFromDate(this.courseEndDate);
  }
}

export default AssignmentSetsCalendar;
