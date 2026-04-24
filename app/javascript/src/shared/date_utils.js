import { getTimezoneOffset } from 'date-fns-tz';
import { isMatch, parse } from 'date-fns';

const localeDateFormat = (date) => {
  return new Date(date).toLocaleDateString(
    'en-US', { year: 'numeric', month: 'long', day: 'numeric' }
  );
};

const localeTimeFormat = (date) => {
  return new Date(date).toLocaleTimeString('en-US');
};

/**
 *  Given a date, it finds and returns the first day of the month in the section timezone
 *
 * @param {Date} date
 * @return {Date} - date in the sections timezone for the first of the same month
 */
function firstDayOfMonthFromDate(date) {
  if (!(date instanceof Date)) {
    return null;
  }

  const month = date.getMonth();
  const year = date.getFullYear();

  return dateInSectionTimezone(new Date(year, month, 1));
}

/**
 *  Given a date, it finds and returns the last day of the month in the section timezone
 *
 * @param {Date} date
 * @return {Date} - date in the sections timezone for the end of the same month
 */
function lastDayOfMonthFromDate(date) {
  if (!(date instanceof Date)) {
    return null;
  }

  const month = date.getMonth();
  const year = date.getFullYear();

  // Increase the month and set the day to 0 to force Date to set to the last day
  // of the month prior to the month index given.
  return dateInSectionTimezone(new Date(year, month + 1, 0));
}

/**
* Converts a date string of format 'YYYY-MM-DD' into a date object.
* While JavaScript's Date object accepts the same formatting, it creates a
* date at midnight in the current timezone. This function creates a date
* at midnight in UTC.
* @param {string} dateString - date string formatted 'YYYY-MM-DD'
* @return {Date}
*/
function dateFromCourseDateString(dateString) {
  if (isMatch(dateString, 'yyyy-MM-dd')) {
    const dateObj = parse(dateString, 'yyyy-MM-dd', new Date());
    return dateInSectionTimezone(dateObj);
  } else {
    throw new Error('Malformatted date string, use "YYYY-MM-DD"');
  }
}

/**
* Create a date from a date in any timezone to one represented by the same local time
* in the current section's timezone.
*
* @param {Date} date
* @return {Date} - date in section's timezone
*/
function dateInSectionTimezone(date) {
  const dateStringWithoutOffset = new Date(
    date.getTime() + getTimezoneOffset(sectionTimezone())
  ).toISOString().replace('Z', '');

  // offset in hours
  const sectionOffset = getTimezoneOffset(sectionTimezone()) / 1000 / 60 / 60;

  const prefix = offsetPrefix(sectionOffset);
  const absoluteOffset = Math.abs(sectionOffset);
  const offsetString = prefix + absoluteOffset + ':00';

  return new Date(dateStringWithoutOffset + offsetString);
}

/**
* @private
* Build an offset string prefix (i.e., + or - and potentially
* a leading zero for single digit hours)
*
* @param {integer} offset in hours (postive or negative)
* @return {String} - a string representing the timezone offset portion of an ISO 8601
*                    formatted datetime string (i.e. +04:00, -10:00, etc.)
*/
function offsetPrefix(offset) {
  let prefix = '';
  if (offset > 0) {
    prefix = '+';
    if (offset > 9) {
      prefix = prefix + '0';
    }
  } else if (offset < 0) {
    prefix = '-';
    if (offset > -10) {
      prefix = prefix + '0';
    }
  }

  return prefix;
}

/**
* Build an offset string prefix (i.e., + or - and potentially
* a leading zero for single digit hours)
*
* @return {String} - a string representing the timezone from the section or the user's browser
*                    default generally in the format of 'Country/Major_City' where each timezone has
*                    limited designations.
*                    See also https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
*/
function sectionTimezone() {
  const metaTag = document.querySelector('meta[name="VHL.section_tz_info"]');
  if (metaTag) {
    if (metaTag.content.length > 0) {
      return metaTag.content;
    }
  }
  // Sensible default
  // eslint-disable-next-line new-cap
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}

/**
 *
 */
function numberOfWeeksBetweenDateStrings(startDate, endDate) {
  const [startMonth, startDay, startYear] = startDate.split('/').map(Number);
  const [endMonth, endDay, endYear] = endDate.split('/').map(Number);

  const start = new Date(startYear, startMonth - 1, startDay);
  const end = new Date(endYear, endMonth - 1, endDay);

  const getWeekNumber = (date) => {
    const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
    return Math.ceil((((date - firstDayOfYear) / 86400000) + firstDayOfYear.getDay() + 1) / 7);
  };

  const startWeek = getWeekNumber(start);
  const endWeek = getWeekNumber(end);
  if (start.getFullYear() === end.getFullYear()) {
    return endWeek - startWeek + 1;
  } else {
    // Handle dates in different years
    const weeksInStartYear = 52 + (new Date(start.getFullYear(), 11, 31).getDay() === 4 ? 1 : 0);
    const weeksRemaining = weeksInStartYear - startWeek + 1;
    const weeksInNewYear = endWeek;
    return weeksRemaining + weeksInNewYear;
  }
}

export {
  localeDateFormat,
  localeTimeFormat,
  firstDayOfMonthFromDate,
  lastDayOfMonthFromDate,
  dateFromCourseDateString,
  dateInSectionTimezone,
  sectionTimezone,
  numberOfWeeksBetweenDateStrings,
};
