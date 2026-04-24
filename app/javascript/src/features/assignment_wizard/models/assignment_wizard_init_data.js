import { dispatchCustomEvent } from 'shared/utils.js';
import * as ajaxUtils from 'shared/ajax_utils';
import LearningTrackHttp from 'features/learning_tracks/models/learning_track_http';
import { pick } from 'shared/utils';
import PreviousSectionImporter from 'features/learning_tracks/models/previous_section_importer';
import DueDateUpdater from 'features/learning_tracks/models/due_date_updater';

/**
 * @typedef {import('./models/due_date_updater.js').DueDateType} DueDateType
 */

/**
 * @typedef {
 *  import('features/learning_tracks/learning_track_data_store.js').AssignmentWizardStoreObject
 * } AssignmentWizardStoreObject
 */

/**
 * A type used in learning track data from server
 * @typeDef {ActivityObjType}
 * @property {string} category
 * @property {string} due_date
 * @property {string} group
 * @property {number} group_id
 * @property {number} id
 */

/**
 * A type used in learning track data from server
 * @typeDef {CategoryObjType}
 * @property {boolean} accept_late_work
 * @property {boolean} credit_only
 * @property {number} drop_low_scores
 * @property {boolean} enhanced_feedback_disabled
 * @property {Array} errors
 * @property {boolean} has_assignments
 * @property {number} id
 * @property {string} late_work_penalty
 * @property {number} max_attempts
 * @property {string} name
 * @property {number} penalty_percent
 * @property {number} rank
 * @property {number} weighting_percent
 */

/**
 * A type used in learning tracks data from server
 * @typeDef {ActivityObjInTracksDataType}
 * @property {Object} activity_requirements
 * @property {string} activity_type
 * @property {number} id
 * @property {string} lesson_name
 * @property {number} minutes_to_complete
 * @property {string} strand
 * @property {string} strand_name
 * @property {string} substrand
 * @property {string} title
 * @property {number} unit_id
 * @property {boolean} individually_assignable
 */

/**
 * Learning Track data from server
 * @typedef LearningTrackType
 * @property {Array.<ActivityObjType>} activities
 * @property {Object.<string, CategoryObjType>} categories
 * @property {Array.<number>} course_package_ids
 * @property {string} description
 * @property {number} first_unit_id
 * @property {boolean} insufficient_license_groups
 * @property {number} last_unit_id
 * @property {Array.<string>} strands
 * @property {Array.<Object>} units
 */

/**
 * Learning Tracks data from server
 * @typedef LearningTracksType
 * @property {Object.<number, ActivityObjInTracksDataType>} activities
 * @property {Object.<string, Object.<string, CategoryObjType>>} categories
 * @property {Object.<string, Object>} strands
 * @property {Object.<string, Object>} tracks
 */

/**
 * Calendar object having calender with assignments and other info like categories etc
 * @typedef CalendarObjType
 * @property {number} activityCount
 * @property {Object.<string, Array.<AssignmentGroup>>} calendar
 * @property {Object.<string, Object>} categories
 * @property {Array[number]} coursePackageIds
 * @property {number} firstUnitId
 * @property {boolean} jsonIsCurrent
 * @property {Object} workload
 */

/** Class to update Assignment Wizard main model at initial Data fetch */
class AssignmentWizardInitData {
  /**
   * Instantiate the AssignmentWizardInitData class.
   * @constructor
   * @param {AssignmentWizardStoreObject} store - reactive store in Assignment Wizard main model
   * @param {AssignmentCalender} assignmentCalendar - assignment calendar object.
   * @param {string} programId - Program Id in string
   * @param {boolean} instAdmin - true if in institution admin view, false if not
   * @param {string} courseId - Course Id in string
   * @param {string} sectionId - Section Id in string
   */
  constructor(store, assignmentCalendar, programId, instAdmin, courseId, sectionId) {
    // A reference of Assignment Wizard reactive data store object
    this.store = store;

    this.instAdmin = instAdmin;
    this.courseId = courseId;
    this.programId = programId;
    this.sectionId = sectionId;
    this.assignmentCalendar = assignmentCalendar;
    this.learningTrackHttp = new LearningTrackHttp(this.programId);
  }

  /**
   * Fetch course info from the server then fetch learning track data and update the model.
   */
  fetchCourseAndTrackDataAndUpdateModel() {
    this.getCourseInfo().then((courseInfo) => {
      this.store.courseInfo = courseInfo;
      this.store.setupDescriptions = courseInfo.setup_descriptions;
      this.store.learningTracksConfig = this.getLearningTracksConfigFromCourseInfo(courseInfo);
      this.store.learningTracksConfig.chooseTrack = true;

      // Fetching data in async and having few setTimeouts too
      this.fetchLearningTrackDataAndUpdateModel(courseInfo);
    });
  }

  /**
   * @private
   * Create JS Error log if jsonIsCurrent property is not true in calendar
   * @param {CalendarObjType} calendar
   */
  checkAndCreateJSErrorLog(calendar) {
    if (!calendar.jsonIsCurrent) {
      const errorReport = 'Activities JSON is out of date. ' +
      'Please run the activities rake task for program #' + this.programId + '.';
      VHL.Common.createJSErrorLog(errorReport);
    }
  }

  /**
   * @private
   * Fetch learning track data and update the model.
   * @param {Object} courseInfo - Course Information response from the server.
   */
  fetchLearningTrackDataAndUpdateModel(courseInfo) {
    // Group -> category map.
    this.store.categories = {};
    this.learningTrackHttp.getPreviousTrack(this.sectionId, courseInfo.current_course)
      .then((learningTrack) => {
        this.learningTrackHttp.getTracks().then((learningTracks) => {
          this.updateStoreWithLearningTrackData(learningTrack, learningTracks);
        });
      });
  }

  /**
   * @private
   * Get course information from the server
   * @return {Promise} promise that resolve to course info.
   */
  getCourseInfo() {
    let url;
    if (this.instAdmin) {
      url = `/institution_admin/${this.programId}/course/${this.courseId}/` +
            'assignment_wizard_templates/course_info.json';
    } else {
      url = `/instructor/${this.programId}/course/${this.courseId}/` +
            'assignment_wizard/course_info.json';
    }

    return new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        url,
        (data) => {
          resolve(data);
        }
      );
    });
  }

  /**
   * @private
   * Get trimmed information from courseInfo
   * @param {Object} courseInfo - Course Information response from the server.
   * @return {Object}
   */
  getLearningTracksConfigFromCourseInfo(courseInfo) {
    return pick(
      courseInfo,
      'previous_courses',
      'previous_course_templates',
      'start_date',
      'end_date',
      'has_assignments',
      'unit_label'
    );
  }

  /**
   * @private
   * Update model for due dates and calendar info
   * then trigger custom event 'assignment_calendar_refresh'
   * @param {Array.<DueDateType>} existingDueDates
   * @param {CalendarObjType} calendar
   * @param {LearningTrackType} learningTrack
   */
  updateAllDueDatesAndRefreshCalendar(existingDueDates, calendar, learningTrack) {
    // This assignment will also set the dueDates property on the
    // assignment calendar via watchers in code
    this.store.allDueDates = DueDateUpdater.synthesizeDates(
      existingDueDates,
      this.store.allDueDates,
      (date) => {
        date.selected = false;
      }
    );
    this.assignmentCalendar.prev = calendar;
    this.assignmentCalendar.learningTrack = learningTrack;
    // This timeout is necessary to show the original state of the previous calendar
    // with all due dates after any redistributions have taken place.
    setTimeout(() => {
      dispatchCustomEvent({ name: 'assignment_calendar_refresh', detail: { calendar }});
    });
  }

  /**
   * @private
   * Update reactive store based on learning track data fetched from server
   * @param {LearningTrackType} learningTrack
   * @param {LearningTracksType} learningTracks
   */
  updateStoreWithLearningTrackData(learningTrack, learningTracks) {
    const calendar = PreviousSectionImporter.import(
      learningTrack, learningTracks.activities
    );
    this.checkAndCreateJSErrorLog(calendar);
    calendar.workLoad = this.assignmentCalendar.calculateWorkLoad(calendar.calendar);
    const dueDates = DueDateUpdater.guessDueDates(learningTrack);
    this.store.courseInfo.name = learningTrack.description;
    this.store.unitRange.firstUnitIndex = String(0);
    this.store.unitRange.lastUnitIndex = String(learningTrack.units.length - 1);
    this.store.learningTrack = learningTrack;
    this.store.selectedTrackName = learningTrack.description;
    this.useDueDateConfig(dueDates);
    const existingDueDates = DueDateUpdater.fromExistingDates(
      Object.keys(calendar.calendar)
    );

    // This flag will used to disable the template chooser if the calendar
    // is not empty the calendar will have data when loading the wizard on
    // a section that already has assignments.
    this.store.sectionHasAssignments = existingDueDates.some(
      (dueDate) => dueDate ? true: false
    );
    this.store.respectDueDates = true;
    this.store.loadingLearningTracks = false;

    // This timeout is necessary for course due dates to populate
    // before we incorporate the previous section's due dates
    // The dates are set by the useDueDateConfig function
    setTimeout(() => {
      this.updateAllDueDatesAndRefreshCalendar(existingDueDates, calendar, learningTrack);
    });
  }

  /**
   * @private
   * Check or uncheck days as needed.
   * @param {Array.<string>} dueDates - An array of day names, e.g. ["Monday", "Tuesday"]
   */
  useDueDateConfig(dueDates) {
    this.store.daysOfWeek.forEach((day) => {
      day.selected = dueDates.includes(day.name);
    });
  }
}

export default AssignmentWizardInitData;
