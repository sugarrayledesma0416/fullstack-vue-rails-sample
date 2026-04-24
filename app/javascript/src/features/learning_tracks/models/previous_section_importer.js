import AssignmentGroup from './assignment_group';

/**
 * @typeDef {ActivityObject}
 * @property {number} id - id of the activity.
 * @property {string} activity_type - type of the activity.
 * @property {string} title - title of activity.
 * @property {string} strand - activity strand.
 * @property {number} unit_id - activity`s unit id.
 */

/**
 * @typedef {
  *  import('features/learning_tracks/models/activity_distributor.js').AssignmentObject
  * } AssignmentObject
  */

/**
 * @typeDef {MemoObject}
 * @property {number} activityCount - total number of activities.
 * @property {Object} calendar - calendar object.
 * @property {boolean} jsonIsCurrent - whether activities JSON is out of date.
 */


/** Class representing a PreviousSectionImporter. */
class PreviousSectionImporter {
  /**
   * Import learnintg track, activities and returns a
   * calender with assignments.
   * @param {Object} learningTrack - learningTrack object.
   * @param {Object} activities - activities object.
   * @return {object}
   */
  static import(learningTrack, activities) {
    const assignmentMap = learningTrack.activities.reduce(
      (memo, assignment) => {
        const groups = this.getAssignmentGroups(memo, assignment);
        const activity = activities[assignment.id];
        if (activity) {
          this.setActivityProperties(activity, assignment);
        }

        const res = this.addActivityToGroup(groups, assignment, activity);

        return {
          activityCount: memo.activityCount + res.activityToAddCount,
          jsonIsCurrent: res.jsonIsCurrent,
          calendar: memo.calendar,
        };
      },
      { calendar: {}, jsonIsCurrent: true, activityCount: 0 }
    );

    return {
      calendar: assignmentMap.calendar,
      firstUnitId: learningTrack.first_unit_id,
      lastUnitId: learningTrack.last_unit_id,
      coursePackageIds: learningTrack.course_package_ids,
      activityCount: assignmentMap.activityCount,
      categories: learningTrack.categories,
      jsonIsCurrent: assignmentMap.jsonIsCurrent,
    };
  }

  /**
   * @private
   * add activity to the assignment group.
   *
   * @param {Array} groups - array of assignment groups.
   * @param {AssignmentObject} assignment - assignment object.
   * @param {ActivityObject} activity - activity object.
   * @return {Object}
   */
  static addActivityToGroup(groups, assignment, activity) {
    let group = groups[groups.length - 1];
    let jsonIsCurrent = true;
    let activityToAddCount = 1;

    if (activity === undefined) {
      jsonIsCurrent = false;
      activityToAddCount = 0;
    } else {
      if (this.shouldAddAssignmentGroup(group, assignment, activity)) {
        group = new AssignmentGroup(
          assignment.group, activity.strand_name, activity.lesson_name
        );
        groups.push(group);
      }
      group.addActivity(activity);
    }

    return { jsonIsCurrent, activityToAddCount };
  }

  /**
   * @private
   * return array of assignment groups
   * belonging to current assignment due date.
   *
   * @param {MemoObject} memo - return value of previous invocation.
   * @param {AssignmentObject} assignment - assignment object.
   * @return {Array}
   */
  static getAssignmentGroups(memo, assignment) {
    const groups = (() => {
      const dueDate = assignment.due_date;
      if (!Array.isArray(memo.calendar[dueDate])) {
        memo.calendar[dueDate] = [];
      }
      return memo.calendar[dueDate];
    })();
    return groups;
  }

  /**
   * @private
   * If the activity`s lesson, strand and assignment`s group name
   * matches to that of current group in the calender, activity
   * should be added to the current group, otherwise new group
   * should be created.
   *
   * Returns whether new group should be created.
   * @param {Object} group - assignment group object.
   * @param {Object} assignment - assignment object.
   * @param {Object} activity - activity object.
   * @return {boolean}
   */
  static shouldAddAssignmentGroup(group, assignment, activity) {
    return !(group && assignment.group === group.name &&
            activity.lesson_name === group.lesson &&
            activity.strand_name === group.strand);
  }

  /**
   * @private
   * Sets the activity's group_id, category, and individually_assignable flag
   *
   * @param {Object} activity - activity object.
   * @param {Object} assignment - assignment object.
   */
  static setActivityProperties(activity, assignment) {
    activity.group_id = assignment.group_id;
    activity.category = assignment.category;
    // Set to false if property is undefined.
    activity.individually_assignable = assignment.individually_assignable || false;
  }
}

export default PreviousSectionImporter;
