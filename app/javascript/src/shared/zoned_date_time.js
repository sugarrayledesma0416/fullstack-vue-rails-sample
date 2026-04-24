import { format, isValid } from 'date-fns';
import { utcToZonedTime } from 'date-fns-tz';

/** Class representing a date using timezone */
class ZonedDateTime {
  /**
   * Instatite a ZonedDateTime object
   *
   * @param {String} dateString The ISO date in string data type
   */
  constructor(dateString) {
    this.dateString = dateString?.trim() || '';
  }

  /**
   * Whether the date to be formatted is empty or not
   *
   * @return {Boolean}
   */
  isEmpty() {
    return this.dateString.length == 0;
  }

  /**
   * Format the date honoring the timezone
   *
   * @param {String} formatString Format to render the date
   * @return {String} The formatted date
   */
  format(formatString) {
    if (this.isEmpty()) {
      return '';
    }

    return format(this.parsedDate(), formatString);
  }

  /**
   * Custom date format. Using format 'MMMM d, yyyy'
   *
   * @return {String} Formatted value
   */
  formattedDate() {
    return this.format('MMMM d, yyyy');
  }

  /**
   * Custom time format. Using format 'h:mm:ss a'
   *
   * @return {String} Formatted value
   */
  formattedTime() {
    return this.format('h:mm:ss a');
  }

  /**
   * Parses the date depending on whether or not it includes the timezone
   * with the timezone: it retains the timezone and does not convert the date
   * without timezone: it assumes it is UTC, so it is converted to the timezone environment
   *
   * @return {Date} Parseed date
   */
  parsedDate() {
    if (this.isEmpty()) {
      return '';
    }

    let date;
    let timeZone;

    if (this.isValidTimeZoneOffset()) {
      date = this.dateString;
      timeZone = this.getTimeZone();
    } else {
      date = new Date(`${this.dateString}Z`);
      timeZone = this.getLocalTimeZone();
    }

    const parsedDate = utcToZonedTime(date, timeZone);

    if (!isValid(parsedDate)) {
      throw new Error(`Invalid date format ${this.dateString}`);
    }

    return parsedDate;
  }

  /**
   * The timezone of the date. If no timezone detected, returns empty string
   *
   * @return {String} The timezone
   */
  getTimeZone() {
    if (this.isValidTimeZoneOffset()) {
      return this.dateString.slice(-6);
    }

    return '';
  }

  /**
   * The timezone of the system/environment
   *
   * @return {String} The timezone
   */
  getLocalTimeZone() {
    return format(new Date(), 'XXX');
  }

  /**
   * Validates whether the timezone of the date is valid or not
   *
   * @return {Boolean}
   */
  isValidTimeZoneOffset() {
    return /^[-+]\d{2}:\d{2}$/.test(this.dateString.slice(-6));
  }
}

export default ZonedDateTime;
