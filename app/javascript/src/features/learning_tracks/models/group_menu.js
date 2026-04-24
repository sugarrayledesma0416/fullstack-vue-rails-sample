import { reactive } from 'vue';
import AssignmentGroup from './assignment_group';
import { dispatchCustomEvent, firstInArray, lastInArray } from 'shared/utils';
import * as ActivityDistributor from 'features/learning_tracks/models/activity_distributor';

/**
 * @typedef {
 *  import('features/learning_tracks/learning_track_data_store.js').AssignmentWizardStoreObject
 * } AssignmentWizardStoreObject
 */

/**
 * @typedef {StrandGroupType}
 * @property {string} lesson
 * @property {string} name
 * @property {number} toMinutes
 * @property {Array.<AssignmentGroup>} groups
 */

/**
  * @typedef {OpenGroupMenuEventType}
  * @property {Object} detail
  * @property {Object} detail.date
  * @property {string} detail.date.name
  * @property {number} detail.position
  */

/**
 * This class initializes Group Menu related app state and
 * has methods to manipulate the app state.
 */
export default class GroupMenu {
  /**
   * Initialize reactive object which stores group menu modal state
   * @constructor
   * @param {AssignmentWizard|CourseWizard} parentModel - Either Assignment Wizard or Course Express
   */
  constructor(parentModel) {
    this.parentModel = parentModel;
    this.store = reactive({
      date: undefined,
      noActivities: false,
      showFirst: false,
      showLast: false,
      strandAssignmentGroups: [],
      strandGroupPosition: 0,
    });
    this.assignmentCalendar = this.parentModel.assignmentCalendar;
  }

  /**
   * Return groups in calendar for date
   * @return {Array.<AssignmentGroup>}
   */
  get groups() {
    return this.parentDataStore.calendar.calendar[this.store.date.name];
  }

  /**
   * returns the parent data store i.e. either assignment wizard or course express.
   * @return {AssignmentWizardStoreObject}
   */
  get parentDataStore() {
    return this.parentModel.store;
  }

  /**
   * Get row index in graph rows corresponding to date
   * for which GroupMenu is to be shown
   * @return {number}
   */
  get rowIndexForDate() {
    return this.assignmentCalendar.dueDates.map(
      (date) => date.name
    ).indexOf(this.store.date.name);
  }

  /**
   * Return group for strand group position
   * @return {StrandGroupType}
   */
  get strandGroup() {
    return this.strandGroups[this.store.strandGroupPosition];
  }

  /**
   * Return strand groups
   * @return {Array.<StrandGroupType>}
   */
  get strandGroups() {
    return this.store.strandAssignmentGroups;
  }

  /**
   * Return whether there are no activities in any of the groups.
   * Return true if there are no groups.
   * @return {boolean}
   */
  activitiesEmpty() {
    const groups = this.strandGroup?.groups;
    // Check existence of groups because it's possible the user deletes all of them
    if (groups) {
      return groups?.every((group) => group.activities.length == 0);
    }
    return true;
  }

  /**
   *
  * @param {Object.<string, Array.<AssignmentGroup>>} calendar - calendar object
  * with date strings as its keys
  * @param {OpenGroupMenuEventType} event - event payload
  * Build date and strand specific data to open GroupMenu modal
  */
  buildDataToOpenGroupMenu(calendar, event) {
    this.store.date = event.detail.date;
    this.store.strandGroupPosition = event.detail.position;
    const assignmentGroups = calendar[event.detail.date.name];
    this.store.strandAssignmentGroups = ActivityDistributor.groupByStrand(assignmentGroups);
    this.store.noActivities = this.activitiesEmpty();
    this.displayMoveButtons();
  }

  /**
   * Delete an activity
   * @param {number} groupIndex - group index
   * @param {number} activityIndex - activity index
   */
  deleteActivity(groupIndex, activityIndex) {
    const currentGroup = this.strandGroup.groups[groupIndex];
    currentGroup.deleteActivity(activityIndex);
    if (currentGroup.activities.length === 0) {
      // Set this flag here because there will be no activities
      // only after an activity deletion and group deletion
      this.store.noActivities = this.activitiesEmpty();
      this.destroyGroups();
    }
    this.displayMoveButtons();

    dispatchCustomEvent({ name: 'assignmentShifted', detail: {}});
  }

  /**
   * Determines whether buttons are shown according to number of
   * activities, position, and row.
   */
  displayMoveButtons() {
    const previousDate = this.getPreviousDate(this.rowIndexForDate);
    const nextDate = this.getNextDate(this.rowIndexForDate);

    // Only show for first group in each due date, and not for the first due date,
    // and not if the previous date is locked
    const displayMoveFirst = this.store.strandGroupPosition == 0 &&
      this.rowIndexForDate != 0 &&
      !previousDate.locked;

    // Only show for last group in each due date, and not for the last due date,
    // and not if the next date is locked
    const displayMoveLast = this.store.strandGroupPosition == this.strandGroups.length - 1 &&
      this.rowIndexForDate != this.assignmentCalendar.dueDates.length - 1 &&
      !nextDate.locked;

    // Only show if there are activities in the first group
    const firstGroup = firstInArray(this.groups);
    this.store.showFirst = displayMoveFirst && firstGroup && firstGroup.activities.length > 0;

    // Only show if there are activities in the last group
    const lastGroup = lastInArray(this.groups);
    this.store.showLast = displayMoveLast && lastGroup && lastGroup.activities.length > 0;
  }

  /**
   * Get GroupMenu dialog title
   * @return {string}
   */
  getGroupMenuDialogTitle() {
    const lesson = this.strandGroup.lesson.split('|')[0].trim();
    const strand = this.strandGroup.groups[0].strand;
    const dateName = this.store.date.name;
    return `Assignments for ${dateName}, ${lesson} | ${strand}`;
  }

  /**
   * Return hours for a strand group.
   * Truncate hours to 1 decimal point.
   * If no strand group, return 0 hours as a fail-safe.
   * @return {number}
   */
  hoursForStrandGroup() {
    const currentStrandGroup = this.strandGroup;
    if (currentStrandGroup) {
      const groups = currentStrandGroup.groups;
      const totalMinutes = groups.reduce((memo, group) => {
        return memo + group.totalMinutes;
      }, 0);
      return (totalMinutes / 60).toFixed(1);
    }
    return 0;
  }

  /**
   * Moves the first activity in a group to be the last activity of
   * the last group on the previous due date.
   */
  moveFirstActivity() {
    const previousDate = this.getPreviousDate(this.rowIndexForDate);
    const currentGroup = firstInArray(this.groups);
    const targetGroup = lastInArray(this.parentDataStore.calendar.calendar[previousDate.name]);
    this.moveActivity(
      currentGroup,
      0,
      targetGroup,
      (activity) => {
        targetGroup.addActivity(activity);
      },
      (group) => {
        const existingGroups = this.parentDataStore.calendar.calendar[previousDate.name];
        if (existingGroups) {
          existingGroups.push(group);
        } else {
          this.parentDataStore.calendar.calendar[previousDate.name] = [group];
        }
      }
    );
  }

  /**
   * Moves the last activity in a group to be the first activity of
   * the first group on the next due date.
   */
  moveLastActivity() {
    const nextDate = this.getNextDate(this.rowIndexForDate);
    const currentGroup = lastInArray(this.groups);
    const index = currentGroup.activities.length - 1;
    const targetGroup = firstInArray(this.parentDataStore.calendar.calendar[nextDate.name]);
    this.moveActivity(
      currentGroup,
      index,
      targetGroup,
      (activity) => {
        targetGroup.addActivityToFront(activity);
      },
      (group) => {
        const existingGroups = this.parentDataStore.calendar.calendar[nextDate.name];
        if (existingGroups) {
          existingGroups.unshift(group);
        } else {
          this.parentDataStore.calendar.calendar[nextDate.name]= [group];
        }
      }
    );
  }

  /**
   * @private
   * Searches among groups and deletes the first group with no activities
   * There will only ever be one group that needs to be deleted when this function is called
   */
  destroyGroups() {
    let index;
    for (let i = 0; i < this.groups.length; i++) {
      const group = this.groups[i];
      if (group.activities.length === 0) {
        index = i;
        break;
      }
    }
    if (index >= 0) {
      this.groups.splice(index, 1);
    }
  }

  /**
   * @private
   * Get next due date
   * @param {number} rowIndexForDate - row index in graph rows corresponding to date
   * for which GroupMenu is to be shown
   * @return {DueDateType}
   */
  getNextDate(rowIndexForDate) {
    return this.assignmentCalendar.dueDates[rowIndexForDate + 1];
  }

  /**
   * @private
   * Get previous due date
   * @param {number} rowIndexForDate - row index corresponding to date
   * for which GroupMenu is to be shown
   * @return {DueDateType}
   */
  getPreviousDate(rowIndexForDate) {
    return this.assignmentCalendar.dueDates[rowIndexForDate - 1];
  }

  /**
   * @private
   * Move an activity from one group to another, creating a new
   * group if necessary.
   * @param {AssignmentGroup} group
   * @param {number} activityIndex - activity index
   * @param {AssignmentGroup} targetGroup
   * @param {Function} addActivityFn - callback to add a new activity to
   * the assignment group activities
   * @param {Function} addGroupFn - callback function to add group
   */
  moveActivity(group, activityIndex, targetGroup, addActivityFn, addGroupFn) {
    const activity = group.deleteActivity(activityIndex);
    if (targetGroup && group.name === targetGroup.name && group.strand === targetGroup.strand) {
      addActivityFn(activity);
    } else {
      const newGroup = new AssignmentGroup(group.name, activity.strand_name, activity.lesson_name);
      newGroup.addActivity(activity);
      addGroupFn(newGroup);
    }
    if (group.activities.length === 0) {
      this.store.noActivities = this.activitiesEmpty();
      this.destroyGroups();
    }

    dispatchCustomEvent({
      name: 'assignmentShifted',
      detail: {},
    });
    this.displayMoveButtons();
  }
}
