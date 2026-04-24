import { reactive } from 'vue';
import { hasKeyInObject, metaTagContent } from 'shared/utils.js';
import * as ajaxUtils from 'shared/ajax_utils';
import JobProgress from 'features/learning_tracks/models/job_progress';
import CalendarProcessor from 'features/learning_tracks/models/calendar_processor';
import {
  sectionTemplateStats,
  sendSectionTemplateStats,
} from 'features/learning_tracks/models/send_section_template_stats';
import UnitRange from 'features/learning_tracks/models/unit_range';
import AssignmentWizardInitData from './assignment_wizard_init_data';
import { getDefaultDaysOfWeek } from 'features/learning_tracks/models/common_data';

/**
 * @typedef {
 *  import('features/learning_tracks/learning_track_data_store.js').AssignmentWizardStoreObject
 * } AssignmentWizardStoreObject
 */

/**
 * @typeDef {DayOfWeekObject}
 * @property {string} name
 * @property {boolean} name
 * @property {number} name
 */

/**
 * @typeDef {SectionSourceObject}
 * @property {string} type
 */

const ASSIGNMENT_GROUP_NAMES = [
  'Explore', 'Learn', 'Practice', 'Communicate',
  'Self-check', 'Assessment', 'Build your skills',
];

/** Class representing an Assignment Wizard main model. */
class AssignmentWizard {
  /**
   * Instantiate the AssignmentWizard class.
   * @constructor
   * @param {AssignmentCalender} assignmentCalendar - assignment calendar object.
   */
  constructor(assignmentCalendar) {
    // Reactive data store object
    this.store = reactive(this.getDefaultsForStore());
    this.assignmentCalendar = assignmentCalendar;
    this.initializeData();

    this.initDataFetch = new AssignmentWizardInitData(
      this.store, assignmentCalendar, this.programId, this.instAdmin, this.courseId, this.sectionId
    );
    this.jobProgress = new JobProgress(this.onError);

    // Fetching data in async and having few setTimeouts too
    this.initDataFetch.fetchCourseAndTrackDataAndUpdateModel();

    this.bindAssignmentCalendarRefresh();
  }

  /**
   * Create assignment via posting data to the server
   */
  create() {
    this.store.disableAllControls = false;
    this.jobProgress.shouldShow = true;
    this.addAnyEmptyDueDatesInCalendar();
    const url = this.getCreateAssignmentUrl();
    const payload = this.getPostPayload();
    ajaxUtils.postToEndpoint(
      url,
      payload,
      (response) => {
        if (response) {
          this.jobProgress.jobIds = response.job_ids;
          this.sendSectionTemplateStatsOnSuccess(response);
        } else {
          this.onError();
        }
      }
    );
  }

  /**
   * Change browser window location to return back
   */
  returnToDashboard() {
    if (this.instAdmin) {
      window.location.replace(
        '/institution_admin/sections/' + this.courseId + '?program_id=' + this.programId + '&school_id=' + this.schoolId
      );
    } else {
      window.location.replace('/instructor/dashboard/' + this.programId);
    }
  }

  /**
   * @private
   * Add back in any empty due dates to ensure accuracy of the cutoff date
   * after which we delete assignments
   * This step makes the client and server side consistent and avoids
   * any time zone issues with dates
   */
  addAnyEmptyDueDatesInCalendar() {
    this.store.allDueDates.forEach((dueDate) => {
      if (!hasKeyInObject(this.store.calendar.calendar, dueDate.name)) {
        this.store.calendar.calendar[dueDate.name] = [];
      }
    });
  }

  /**
   * @private
   * Get reduced object with categories in courseInfo corresponding to given category names.
   * Here, categoryName refers to either a group name or a category name,
   * depending on the mapping type
   * @param {Array.<string>} categoryNames
   * @return {Object} - Reduced object with categories in courseInfo corresponding
   * to given category names
   */
  assignDefaultCategories(categoryNames) {
    return categoryNames.reduce((memo, categoryName) => {
      memo[categoryName] = this.assignDefaultCategory(categoryName);
      return memo;
    }, {});
  }

  /**
   * @private
   * Get category in courseInfo corresponding to given category name
   * @param {string} categoryName
   * @return {Object} - Category in courseInfo corresponding to given category name
   */
  assignDefaultCategory(categoryName) {
    // Need this check because express creation will not have course categories set
    // In which case, this will return undefined
    const courseCategories = this.store.courseInfo && this.store.courseInfo.categories;
    return courseCategories?.find((category) => {
      return categoryName.toLowerCase() === category.name.toLowerCase();
    });
  }

  /**
   * @private
   * Add event listener for 'assignment_calendar_refresh' event on document.
   * This updates calendar and category information in the model
   */
  bindAssignmentCalendarRefresh() {
    document.addEventListener('assignment_calendar_refresh', (event) => {
      const calendar = event.detail.calendar;
      this.store.calendar = calendar;
      // Set group/category => category mapping defaults
      this.store.categoryMappingList = this.store.usingPredefinedTrack ?
        ASSIGNMENT_GROUP_NAMES : Object.keys(calendar.categories);
      this.store.categories = this.assignDefaultCategories(this.store.categoryMappingList);
    });
  }

  /**
   * @private
   * Get url for create assignment post request.
   * @return {string}
   */
  getCreateAssignmentUrl() {
    let url;
    if (this.instAdmin) {
      url = `/institution_admin/${this.programId}/courses/${this.courseId}/` +
        `assignment_wizard_templates.json?section_id=${this.sectionId}`;
    } else {
      url = `/instructor/${this.programId}/course/${this.courseId}/assignment_wizard.json` +
      `?section_id=${this.sectionId}`;
    }
    return url;
  }

  /**
   * @private
   * Return initial values for reactive data store
   * @return {AssignmentWizardStoreObject}
   */
  getDefaultsForStore() {
    return {
      allDueDates: undefined,
      calendar: undefined,
      categories: undefined,
      categoryMappingList: undefined,
      courseInfo: undefined,
      daysOfWeek: getDefaultDaysOfWeek(),
      disableAllControls: undefined,
      includeInstructorGradedActivities: true,
      includeMicrophoneActivities: true,
      includePartnerActivities: true,
      learningTrack: undefined,
      learningTracksConfig: {},
      loadingLearningTracks: true,
      respectDueDates: false,
      sectionHasAssignments: false,
      sectionSource: { type: 'section' },
      selectedTrackName: '',
      setupDescriptions: undefined,
      strands: undefined,
      unitRange: new UnitRange(undefined, undefined, []),
      usingPredefinedTrack: false,
    };
  }

  /**
   * @private
   * Get payload object for create assignment post request.
   * @return {Object}
   */
  getPostPayload() {
    let processedCalendar;
    if (this.store.usingPredefinedTrack) {
      processedCalendar = CalendarProcessor.stripCalendar(
        this.store.calendar.calendar,
        (activity, group) => {
          activity.category = group.name;
        }
      );
    } else {
      processedCalendar = CalendarProcessor.stripCalendar(this.store.calendar.calendar);
    }

    return {
      'raw_assignments': processedCalendar,
      'categories': this.store.categories,
      'source_section_id': this.store.selectedSectionId,
      'copy_external_items?': this.assignmentCalendar.copyIgc,
    };
  }

  /**
   * @private
   * Initialize variables
   */
  initializeData() {
    this.vistaOnlineLearning = VISTA_ONLINE_LEARNING;
    this.instAdmin = metaTagContent('VHL.in_institution_admin') === 'true';
    this.schoolId = metaTagContent('VHL.course_school_id');
    const urlParams = this.parseUrl();
    this.courseId = urlParams.courseId;
    this.programId = urlParams.programId;
    this.sectionId = urlParams.sectionId;
  }

  /**
   * @private
   * Error callback function when request to create assignment fails
   */
  onError() {
    alert('Failed to create assignments!');
  }

  /**
   * @private
   * Extract program id, course id and section id from window.location URL.
   * @return {Object} - An object that contains programId, courseId and section id.
   */
  parseUrl() {
    let regex;
    if (this.instAdmin) {
      regex = new RegExp([
        /\/institution_admin\/([0-9]+)\/courses\/([0-9]+)/,
        /\/sections\/([0-9]+)\/assignment_wizard_templates/,
      ].map((r) => r.source).join(''));
    } else {
      regex = /\/instructor\/([0-9]+)\/course\/([0-9]+)\/assignment_wizard/;
    }
    const results = regex.exec(window.location);
    const query = VHL.Common.parse_query_string();
    const sectionId = this.instAdmin ? results[3] : query.section_id;
    return { programId: results[1], courseId: results[2], sectionId: sectionId };
  }

  /**
   * @private
   * Send Section Template Stats on post request success.
   * @param {Object} response - Response from post request.
   */
  sendSectionTemplateStatsOnSuccess(response) {
    try {
      const template = this.store.usingPredefinedTrack ?
        'learning_track_template' : 'previous_section_template';
      const sectionObj = {
        calendar: this.store.calendar,
        includeInstructorGradedActivities: this.store.includeInstructorGradedActivities,
        includeMicrophoneActivities: this.store.includeMicrophoneActivities,
        includePartnerActivities: this.store.includePartnerActivities,
        selectedTrackName: this.store.selectedTrackName,
        strands: this.store.strands,
      };
      sendSectionTemplateStats(sectionTemplateStats(sectionObj), template);
    } catch (err) {
      console.log('there was an error sending stats', err);
    }
    this.jobProgress.jobIds = response.job_ids;
  }
}

export default AssignmentWizard;
