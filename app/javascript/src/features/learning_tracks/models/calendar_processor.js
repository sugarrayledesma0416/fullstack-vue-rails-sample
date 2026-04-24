import { reduceObject } from 'shared/utils';

/** Class for Calendar Processor Model. */
class CalendarProcessor {
  /**
   * Get stripped down calendar with just future due dates and activities.
   * @param {Object} calendar - calendar object.
   * @param {Function} activityModifierCallback
   * @return {Object} - Stripped down calendar with just future due dates and activities.
   */
  static stripCalendar(calendar, activityModifierCallback) {
    const initialValue = {};
    const reducerFn = (memo, currentList, currentKey, obj) => {
      return this.getMemoForDueDate(memo, currentList, currentKey, activityModifierCallback);
    };
    return reduceObject(calendar, initialValue, reducerFn);
  }

  /**
   * @private
   * Return activity info in condensed format.
   * @param {Object} activity - activity object.
   * @return {Object} - Activity info in condensed format
   */
  static condenseActivity(activity) {
    return {
      id: activity.id,
      group_id: activity.group_id,
      category: activity.category,
      individually_assignable: activity.individually_assignable,
    };
  }

  /**
   * @private
   * A function to execute on each key/value in the calendar object to reduce it.
   * This function sets accumulator object for future due dates keys
   * with condensed/ flattened activities.
   * @param {Object} memo - Current accumulator.
   * @param {Array} groups - AssignmentGroups for a due date
   * @param {String} dueDate - Calendar due date string
   * @param {Function} activityModifierCallback
   * @return {Object} - New value of accumulator.
   */
  static getMemoForDueDate(memo, groups, dueDate, activityModifierCallback) {
    const now = moment();
    // only send dates that are in the future
    if (moment(dueDate).isAfter(now)) {
      const groupedActivities = groups.map((group) => {
        return group.activities.map((activity) => {
          const condensedActivity = CalendarProcessor.condenseActivity(activity);
          // Currently activityModifierCallback is only used for creating from a
          // predefined track in the assignment wizard ctrl
          if (activityModifierCallback) {
            activityModifierCallback(condensedActivity, group);
          }
          return condensedActivity;
        });
      });
      memo[dueDate] = groupedActivities.flat();
    }
    return memo;
  }
}

export default CalendarProcessor;
