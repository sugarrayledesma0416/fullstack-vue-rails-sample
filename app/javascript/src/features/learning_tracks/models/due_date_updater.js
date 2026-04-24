import {
  isFunction, sortByFunction, union, unique, uniqueWithFunction,
} from 'shared/utils';

/** Class for Due Date Updater model. */
class DueDateUpdater {
  /**
   * Due Date type definition
   * @typedef {Object} DueDateType
   * @property {string} name - Date string eg "01/30/2021"
   * @property {string} label - Date in format eg "Jan 30"
   * @property {string} dayOfWeek - Day of week in 2 char abbreviation eg "Mo" for monday
   * @property {boolean} selected
   * @property {boolean} locked
   */

  /**
   * Moment Js Date instance
   * @typedef {Object} MomentJsDateType
   */

  /**
   * This method generates due date objects from an array of date strings. The
   * date array is assumed to be composed of due dates for existing
   * assignments. Dates that are prior to the current date are marked
   * as locked.
   * @param {Array.<string>} dates
   * @return {Array.<DueDateType>} dueDates
   */
  static fromExistingDates(dates) {
    const now = moment();
    return dates.map((date) => {
      return {
        name: date,
        label: moment(date).format('MMM DD'),
        selected: true,
        dayOfWeek: moment(date).format('dd'),
        locked: moment(date).isBefore(now),
      };
    });
  }

  /**
   * This method returns an array of dates that fall more than once per week.
   * This takes in a user defined array of days of week and returns all
   * instances of them between the course's start and end dates.
   * @param {string} startDate
   * @param {string} endDate
   * @param {Array.<number>} dueDays - User defined array of days of week
   * (from 0 for Sunday to 6 for Saturday)
   * @return {Array.<DueDateType>} dueDates
   */
  static getCustomDates(startDate, endDate, dueDays) {
    const now = moment();
    const dueDates = [];
    if (!Array.isArray(dueDays) || dueDays.length == 0) {
      return dueDates;
    }

    this.pushDueDatesInLoop(
      startDate, endDate, dueDates, dueDays, now
    );
    return dueDates;
  }

  /**
   * Get locked dueDates
   * @param {Array.<DueDateType>} dueDates
   * @return {Array.<DueDateType>} - Locked due dates
   */
  static getLockedDueDates(dueDates) {
    return dueDates?.filter((date) => {
      return date.locked;
    });
  }

  /**
   * This method examine the first 2 weeks of assignments and take our best
   * guess at what the due date configuration is.
   * @param {Object} sectionTrack
   * @return {Array.<string>} - Human readable days of week eg. ['Monday', 'Tuesday']
   */
  static guessDueDates(sectionTrack) {
    const dueDates = this.getSortedDueDatesForTwoWeeks(sectionTrack);
    const readableDueDates = dueDates.map((date) => {
      // Human readable day of week eg. 'Monday'
      return date.format('dddd');
    });
    const uniqueDays = unique(readableDueDates);
    return uniqueDays;
  }

  /**
   * This method combines two arrays of dates, removes duplicates, and sorts them.
   * The first array argument takes precedence when deciding between two date objects
   * with the same name.
   * @param {Array.<DueDateType>} lockedOrExistingDates
   * @param {Array.<DueDateType>} courseDates
   * @param {Function} courseDateModifier
   * @return {Array.<DueDateType>} sortedDates
   */
  static synthesizeDates(lockedOrExistingDates, courseDates, courseDateModifier) {
    if (isFunction(courseDateModifier)) {
      courseDates?.forEach((date) => {
        courseDateModifier(date);
      });
    }
    const selectedLockedOrExistingDates = this.getSelectedLockedOrExistingDates(
      lockedOrExistingDates
    );
    const combinedDates = union(selectedLockedOrExistingDates, courseDates);
    const uniqueDates = uniqueWithFunction(combinedDates, (date) => {
      return date.name;
    });
    const sortedDates = sortByFunction(uniqueDates, (date) => {
      return new Date(date.name);
    });
    return sortedDates;
  }

  /**
   * @private
   * Get Moment Js instance of due date for sectionTrack activity at given index
   * @param {Object} sectionTrack
   * @param {number} activityIndex
   * @return {MomentJsDateType} - Moment Js instance of due date
   */
  static getDateObjInActivity(sectionTrack, activityIndex) {
    if (sectionTrack.activities.length > 0) {
      return moment(sectionTrack.activities[activityIndex].due_date);
    }
    // Need to return valid moment object if there are no activities
    return moment();
  }

  /**
   * @private
   * Get dates which are either selected or locked
   * @param {Array.<DueDateType>} lockedOrExistingDates
   * @return {Array.<DueDateType>} - Dates which are either selected or locked
   */
  static getSelectedLockedOrExistingDates(lockedOrExistingDates) {
    const now = moment();
    return lockedOrExistingDates?.filter((date) => {
      return date.selected || moment(date.name).isAfter(now);
    });
  }

  /**
   * @private
   * Get all due dates for the first 2 weeks, sorted.
   * @param {Object} sectionTrack
   * @return {Array.<MomentJsDateType>} - Sorted due dates
   */
  static getSortedDueDatesForTwoWeeks(sectionTrack) {
    const dueDates = [];
    const endDate = DueDateUpdater.getDateObjInActivity(sectionTrack, 0).add('weeks', 2);
    for (let i = 0; i < sectionTrack.activities.length; ++i) {
      const dueDate = DueDateUpdater.getDateObjInActivity(sectionTrack, i);
      if (dueDate.isBefore(endDate)) {
        dueDates.push(dueDate);
      } else {
        break;
      }
    }
    return dueDates;
  }

  /**
   * @private
   * This method runs loop and pushes due dates between the course's start and end dates.
   * @param {string} startDate
   * @param {string} endDate
   * @param {Array.<DueDateType>} dueDates
   * @param {Array.<number>} dueDays - User defined array of days of week
   * (from 0 for Sunday to 6 for Saturday)
   * @param {MomentJsDateType} now - Moment js instance for current time.
   */
  static pushDueDatesInLoop(startDate, endDate, dueDates, dueDays, now) {
    const dueDate = moment(startDate).day(dueDays[0]);
    const endDateInMoment = moment(endDate);
    while (dueDate.isBefore(endDateInMoment) || dueDate.isSame(endDateInMoment)) {
      for (let i = 0; i < dueDays.length; i++) {
        const dayVal = dueDays[i];
        this.pushDueDatesIfInRange(startDate, endDate, dueDates, dueDate, dayVal, now);
      }
      dueDate.add('days', 7);
    }
  }

  /**
   * @private
   * This method pushes due dates between the course's start and end dates.
   * @param {string} startDate
   * @param {string} endDate
   * @param {Array.<DueDateType>} dueDates
   * @param {MomentJsDateType} dueDate - Moment js instance.
   * @param {number} dayVal - Day of week (from 0 for Sunday to 6 for Saturday)
   * @param {MomentJsDateType} now - Moment js instance for current time.
   */
  static pushDueDatesIfInRange(startDate, endDate, dueDates, dueDate, dayVal, now) {
    // Create a temporary copy of `dueDate` so that calling `day()` won't
    // mutate the original.
    const candidate = dueDate.clone().day(dayVal);
    if (moment(startDate).twix(endDate).contains(candidate)) {
      const isPastDate = candidate.isBefore(now);
      dueDates.push({
        name: candidate.format('MM/DD/YYYY'),
        label: candidate.format('MMM DD'),
        dayOfWeek: candidate.format('dd'),
        selected: !isPastDate,
        locked: isPastDate,
      });
    }
  }
}

export default DueDateUpdater;
