import * as ActivityDistributor from 'features/learning_tracks/models/activity_distributor';
import UnitRange from 'features/learning_tracks/models/unit_range';
import { isObjEmpty, pluck, reject, sum, unique } from 'shared/utils';

/**
 * @typedef {
  *  import('features/learning_tracks/models/previous_section_importer.js').ActivityObject
  * } ActivityObject
  */

/**
 * @typeDef {UnitRange}
 * @property {number} firstUnitIndex - index of first unit.
 * @property {number} lastUnitIndex - index of last unit.
 * @property {Array} units - list of units.
 */

/** Class representing an Assignment Calender. */
class AssignmentCalender {
  /**
   * Set up the configutation required for initializing
   * AssignmentCalender.
   */
  constructor() {
    this.learningTrack = {};
    this.activities = [];
    this.categories = [];
    this.groupNames = [];
    this.dueDates = [];
    this.strategies = [];

    // Grouping
    this.keepGroups = false;
    this.keepStrands = false;
    this.splitLessons = false;
    this.respectDueDates = false;

    // Filtering
    this.filters = [];
    this.unitRange = null;
    this.units = [];
    this.strands = [];

    // Previous state
    this.prev = null;
    this.registerStrategies();
  }

  /**
   * Builds a calendar object along with learning track metadata.
   *
   * @return {Object}
   */
  build() {
    if (this.isValid()) {
      const learningTrack = this.reduceLearningTrack(this.unitRange, this.strands);
      const calendar = (() => {
        if (this.splitLessons && this.enoughDueDates) {
          return this.buildByLesson();
        }
        return this.makeCalendar(learningTrack, this.dueDates);
      })();

      return {
        calendar: calendar,
        firstUnitId: this.unitRange.firstUnitId,
        lastUnitId: this.unitRange.lastUnitId,
        coursePackageIds: this.learningTrack.course_package_ids,
        categories: this.categories,
        workLoad: this.calculateWorkLoad(calendar),
        groupNames: unique(this.groupNames),
      };
    }

    return null;
  }

  /**
   * Creates a calender object per lesson and
   * merges them together.
   *
   * @return {Object}
   */
  buildByLesson() {
    let calendar = {};
    const dueDates = this.dueDates.slice(0);
    const numUnits = this.unitRange.count;
    const dueDatesPerLesson = Math.floor(dueDates.length / numUnits);
    let remainder = dueDates.length % numUnits;
    let datesSubset;
    this.unitRange.each((index) => {
      if (remainder > 0) {
        datesSubset = dueDates.splice(0, dueDatesPerLesson + 1);
        remainder--;
      } else {
        datesSubset = dueDates.splice(0, dueDatesPerLesson);
      }

      const reducedUnitRange = new UnitRange(index, index, this.units);
      const reducedLesson = this.reduceLearningTrack(reducedUnitRange, this.strands);
      const calendarSubset = this.makeCalendar(reducedLesson, datesSubset);
      calendar = Object.assign(calendar, calendarSubset);
    });

    return calendar;
  }

  /**
   * Calculate activityCount, avg, max and min
   * of total minutes in a calendar.
   *
   * @param {Object} calendar - Calendar object.
   * @return {Object}
   */
  calculateWorkLoad(calendar) {
    if (calendar && !isObjEmpty(calendar)) {
      let activityCount = 0;
      this.dates = Object.keys(calendar);
      this.dateTimes = this.dates.map((day) => {
        activityCount += this.countActivities(calendar[day]);
        return sum(pluck(calendar[day], 'totalMinutes'));
      });
      this.workLoad = {
        activityCount: activityCount,
        avg: sum(this.dateTimes) / this.dateTimes.length,
        max: Math.max(...this.dateTimes),
        min: Math.min(...this.dateTimes),
      };
    } else {
      this.workLoad = {
        activityCount: 0,
        avg: 0,
        max: 0,
        min: 0,
      };
    }

    return this.workLoad;
  }

  /**
   * Check if assignment calender is valid.
   * @return {boolean}
   */
  isValid() {
    return !isObjEmpty(this.learningTrack) &&
        this.unitRange.isValid &&
        this.units.length > 0 &&
        this.strands.length > 0 &&
        this.dueDates;
  }

  /**
   * Generates a calender from given learning tracks and due dates.
   *
   * @param {Object} learningTrack - learning track object.
   * @param {Array} dueDates - array of due dates.
   * @return {Object}
   */
  makeCalendar(learningTrack, dueDates) {
    const unlockedDueDates = reject(dueDates, function(date) {
      return date.locked;
    });
    let calendar = ActivityDistributor.distribute(
      learningTrack,
      pluck(unlockedDueDates, 'name'),
      this.getStrategy()
    );

    if (this.prev) {
      const lockedCalendar = this.spliceLockedDays(dueDates);
      calendar = Object.assign(calendar, lockedCalendar);
    }

    return calendar;
  }

  /**
   * Filter out learning track activities that:
   * 1. fall outside the lesson and strand ranges.
   * 2. do not satisfy custom filters.
   * 3. assigned on locked days in the previous calendar.
   *
   * @param {Objects} unitRange - unit range.
   * @param {Array} strands - strands list.
   * @return {Array}
   */
  reduceLearningTrack(unitRange, strands) {
    const filters = [this.filterByLesson, this.filterByStrand].concat(this.filters);
    const lockedDates = this.lockedDueDates(this.dueDates);
    const assignmentIds = this.lockedAssignmentIds(lockedDates);
    const activities = this.activities;
    this.groupNames = [];

    return this.learningTrack.activities.reduce((memo, assignment) => {
      let activity = activities[assignment.id];

      /**
       * The way learning tracks are created makes it impossible to
       * include instrutor generated content(InstructorCreatedActivities) because
       * we dont have a way to filter the content the instructors create.
       * So when we try to find IGC in activities
       * we find nothing and activity is set to undefined. When the instructor
       * chooses to copy IGC we need to skip the validation that makes sure the
       * activity is part of the learning track and avoid the undefined activity.
       */
      if (this.copyIgc && assignment.is_igc) {
        activity = assignment;
      }

      /**
       * We need to filter out individually assigned activities if the option
       * was not checked
       */
      if (!this.copyIac && assignment.individually_assignable) {
        activity = null;
      }

      if (activity) {
        activity.group_id = assignment.group_id;
        activity.category = assignment.category;
        activity.individually_assignable = assignment.individually_assignable;

        if (
          this.testActivity(filters, activity, unitRange, strands) &&
          this.filterByLockedDueDates(assignmentIds, assignment)
        ) {
          this.groupNames.push(assignment.group);
          memo.push({
            activity: activity,
            group: assignment.group,
            due_date: assignment.due_date,
          });
        }
      }

      return memo;
    }, []);
  }

  /**
   * Register a given filter in list of filters.
   *
   * @param {Function} filter - filter to be registered.
   */
  registerFilter(filter) {
    this.filters.push(filter);
  }

  /**
   * @private
   * Check if enough due dates are present.
   * @return {boolean}
   */
  get enoughDueDates() {
    return this.unitRange.count <= this.dueDates.length;
  }

  /**
   * @private
   * Basic strategy for distributing assignments among
   * duedates in calendar.
   *
   * @return {boolean}
   */
  basicStrategy() {
    return false;
  }

  /**
  * @private
  * Return the count of activities in a assignment groups.
  *
  * @param {Array} assignmentGroups - Array of assignment groups.
  * @return {number}
  */
  countActivities(assignmentGroups) {
    return assignmentGroups.reduce(function(memo, assignmentGroup) {
      return memo + assignmentGroup.activities.length;
    }, 0);
  }

  /**
   * @private
   * Date strategy for distributing assignments among
   * duedates in calendar.
   *
   * @param {Object} current - current assignment object.
   * @param {Object} previous - previous assignment object.
   * @return {boolean}
   */
  dateStrategy(current, previous) {
    return current.due_date === previous.due_date;
  }

  /**
   * @private
   * Filter out assignments that are in locked due dates in the
   * previously computed calendar.
   *
   * @param {Array} assignmentIds - array of assignment ids.
   * @param {Object} assignment - assignment object.
   * @return {boolean}
   */
  filterByLockedDueDates(assignmentIds, assignment) {
    return !(assignmentIds.includes(assignment.id));
  }

  /**
   * @private
   * return whether activity fall outside the lesson ranges.
   *
   * @param {ActivityObject} activity - activity object.
   * @param {UnitRange} unitRange - unit range.
   * @param {Array.<string>} strands - strands list.
   * @return {boolean}
   */
  filterByLesson(activity, unitRange, strands) {
    return unitRange.includes(activity.unit_id);
  }

  /**
   * @private
   * return whether activity fall outside the strand ranges.
   *
   * @param {ActivityObject} activity - activity object.
   * @param {UnitRange} unitRange - unit range.
   * @param {Array.<string>} strands - strands list.
   * @return {boolean}
   */
  filterByStrand(activity, unitRange, strands) {
    return strands.includes(activity.strand);
  }

  /**
   * @private
   * Get the current strategy.
   * @return {Function}
   */
  getStrategy() {
    return this.strategies.find((record) => {
      return record.predicate();
    }).strategy;
  }

  /**
   * @private
   * Group strategy for distributing assignments among
   * duedates in calendar.
   *
   * @param {Object} current - current assignment object.
   * @param {Object} previous - previous assignment object.
   * @return {boolean}
   */
  groupStrategy(current, previous) {
    return current.group === previous.group;
  }

  /**
   * @private
   * Return all of the assignments that are assigned on locked due
   * dates in the previous assignment calendar.  An empty array is
   * returned if there is no previous calendar.
   *
   * @param {Array.<string>} lockedDates - array of locked dates.
   * @return {Array}
   */
  lockedAssignmentIds(lockedDates) {
    if (this.prev === null) {
      return [];
    }
    let activitiesIds = [];
    for (const [date, groups] of Object.entries(this.prev.calendar)) {
      if (lockedDates.includes(date)) {
        const activities = groups.map((group) => group['activities']);
        const ids = activities.flat().map((activity) => activity['id']);
        activitiesIds = activitiesIds.concat(ids);
      }
    }
    return activitiesIds;
  }

  /**
   * @typeDef {DueDate}
   * @type {Object}
   * @property {string} name - name of the date
   * @property {boolean} locked - Whether it is locked or not.
   */

  /**
   * @private
   * Filter locked due dates from array of due dates.
   *
   * @param {Array.<DueDate>} dueDates - array of due dates.
   * @return {Array.<string>} The names of the locked dates.
   */
  lockedDueDates(dueDates) {
    return dueDates?.filter(
      (date) => date.locked
    ).map((date) => date.name);
  }

  /**
   * @private
   * Register all the stratergies on the assignment calendar
   * initialization.
   */
  registerStrategies() {
    // Respect due dates must have precedence (must be first)
    this.registerStrategy(this.dateStrategy, () => {
      return this.respectDueDates;
    });

    this.registerStrategy(this.groupStrategy, () => {
      return this.keepGroups && !this.keepStrands;
    });

    this.registerStrategy(this.strandStrategy, () => {
      return !this.keepGroups && this.keepStrands;
    });

    this.registerStrategy((current, previous) => {
      return this.strandStrategy(current, previous);
    }, () => {
      return this.keepGroups && this.keepStrands;
    });

    // Default case. *MUST* be last.
    this.registerStrategy(this.basicStrategy, () => {
      return true;
    });
  }

  /**
   * @private
   * Register a new strategy function that will be used when the
   * predicate returns true. Keep in mind that order of operations is
   * important here, the *first* predicate that returns true will be
   * the strategy that is used.
   *
   * @param {Function} strategy - current assignment object.
   * @param {Function} predicate - previous assignment object.
   */
  registerStrategy(strategy, predicate) {
    this.strategies.push({
      predicate: predicate,
      strategy: strategy,
    });
  }

  /**
   * @private
   * Add the unmodified assignments for locked days back in after
   * distribution.  This can only be done if there is a previous
   * assignment calendar to work with.
   *
   * @param {Array} dueDates - array od due dates.
   * @return {Object}
   */
  spliceLockedDays(dueDates) {
    const lockedDates = this.lockedDueDates(dueDates);

    const lockedCalendar = {};
    for (const [key, value] of Object.entries(this.prev.calendar)) {
      if (lockedDates.includes(key)) {
        lockedCalendar[key] = value;
      }
    }
    return lockedCalendar;
  }


  /**
   * @private
   * Strand strategy for distributing assignments among
   * duedates in calendar.
   *
   * @param {Object} current - current assignment object.
   * @param {Object} previous - previous assignment object.
   * @return {boolean}
   */
  strandStrategy(current, previous) {
    return current.activity.strand_name === previous.activity.strand_name;
  }

  /**
   * @private
   * Test given activity against given filters
   *
   * @param {Array} filters - array of filters.
   * @param {Object} activity - activity object.
   * @param {UnitRange} unitRange - unit range.
   * @param {Array.<string>} strands - strands list.
   * @return {boolean}
   */
  testActivity(filters, activity, unitRange, strands) {
    return filters.every((filter) => {
      return filter(activity, unitRange, strands);
    });
  }
}

export default AssignmentCalender;
