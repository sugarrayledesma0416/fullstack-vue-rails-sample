import LearningTrackHttp from 'features/learning_tracks/models/learning_track_http';
import getCourseOptions from 'features/course_wizard/services/course_options_http';
import CourseHttp from 'features/course_wizard/services/course_http';
import JobProgress from 'features/learning_tracks/models/job_progress';
import UnitRange from 'features/learning_tracks/models/unit_range';
import { getDefaultDaysOfWeek } from 'features/learning_tracks/models/common_data';
import { pick } from 'shared/utils';

import {
  sectionTemplateStats,
  sendSectionStats,
  sendSectionTemplateStats,
} from 'features/learning_tracks/models/send_section_template_stats';

/**
 * This stores course wizard app state for learning tracks
 * and has methods to manipulate the app state.
 */
export default class LearningTracksStepDataStore {
  /**
   * @constructor
   * @param {NewCourseDataStore} courseDataStore - New Course Data Store main model
   * which shares reactive store with this model
   * @param {AssignmentCalender} assignmentCalendar - assignment calendar object.
   * @param {boolean} instAdmin
   * @param {number} programId
   * @param {number} schoolId
   */
  constructor(courseDataStore, assignmentCalendar, instAdmin, programId, schoolId) {
    this.store = courseDataStore.store;
    this.resetDefaultsOnReload();
    this.assignmentCalendar = assignmentCalendar;
    this.programId = programId;
    this.learningTrackHttp = new LearningTrackHttp(this.programId);
    this.courseHttp = new CourseHttp({ instAdmin, programId, schoolId });
    this.jobProgress = new JobProgress(this.onError);
    this.courseFormState = courseDataStore.courseFormState;
    this.store.loadingLearningTracks = true;
    this.fetchLearningTracksAndCourseOptionsAndUpdateData();
  }

  /**
   * this fetches learning tracks data and course options from the server then updates the model.
   */
  async fetchLearningTracksAndCourseOptionsAndUpdateData() {
    await this.learningTrackHttp.getTracks();
    const courseOptions = await getCourseOptions();
    this.store.loadingLearningTracks = false;
    this.store.calendar = null;
    this.vistaOnlineLearning = VISTA_ONLINE_LEARNING;
    this.store.learningTracksConfig = {
      chooseTrack: true,
      end_date: this.store.course.endDate,
      previous_courses: courseOptions.previous_courses,
      previous_course_templates: courseOptions.previous_course_templates,
      start_date: this.store.course.startDate,
      unit_label: courseOptions.program.unit_label,
      units: courseOptions.units,
    };
    this.bindAssignmentCalendarRefresh();
  }

  /**
   * Navigate to dashboard
   */
  returnToDashboard() {
    this.courseHttp.returnToDashboard({ id: this.courseId });
  }

  /**
   * @private
   * Add event listener for 'assignment_calendar_refresh' event on document.
   * This updates calendar information in the model
   */
  bindAssignmentCalendarRefresh() {
    document.addEventListener('assignment_calendar_refresh', (event) => {
      const calendar = event.detail.calendar;
      this.store.calendar = calendar;
    });
  }

  /**
   * Create course via express path
   */
  async expressCreate() {
    /* In the event of external assignments only, the calendar will be null. Set to
       an empty object in order for the code to run. */
    this.store.calendar = this.store.calendar || {};
    this.store.disableAllControls = false;
    this.jobProgress.shouldShow = true;
    /* If the calendar is empty, use the course first/last unit */
    this.store.course.firstUnitId =
      this.store.calendar.firstUnitId || this.store.course.firstUnitId;
    this.store.course.lastUnitId = this.store.calendar.lastUnitId || this.store.course.lastUnitId;
    this.store.calendar.srcSectionId = this.store.selectedSectionId;
    this.store.calendar.copyIgc = this.assignmentCalendar.copyIgc;
    this.store.course.selectedLearningTrack = this.store.selectedTrackName;
    this.courseFormState.markClean();
    try {
      const response = await this.courseHttp.expressCreate(this.store.course, this.store.calendar);
      this.jobProgress.jobIds = [response.job_id];
      this.courseId = response.course_id;
      this.store.saving = false;
      this.sendSectionTemplateStatsForSection();
    } catch (e) {
      this.jobProgress.shouldShow = false;
      this.store.saving = false;
      this.onError();
    }
  }

  /**
   * @private
   * Error handler which displays alert on failure.
   */
  onError() {
    alert('Failed to create assignments!');
  }

  /**
   * @private
   * This resets store for learning tracks. This is required when user
   * navigates to previous steps and then comes again on learning tracks step.
   */
  resetDefaultsOnReload() {
    this.store.daysOfWeek = getDefaultDaysOfWeek();
    this.store.disableAllControls = undefined;
    this.store.includeInstructorGradedActivities = true;
    this.store.includeMicrophoneActivities = true;
    this.store.includePartnerActivities = true;
    this.store.learningTracksConfig = {};
    this.store.loadingLearningTracks = true;
    this.store.unitRange = new UnitRange(undefined, undefined, []);
  }

  /**
   * @private
   * This dispatches stats indicating section creation and
   * what type of template was applied to the sections
   */
  sendSectionTemplateStatsForSection() {
    try {
      const template = this.store.usingPredefinedTrack ?
        'learning_track_template' : 'previous_section_template';
      this.store.course.sections.forEach(() => {
        sendSectionStats();
        const sectionObj = pick(this.store,
          'calendar',
          'includeInstructorGradedActivities',
          'includeMicrophoneActivities',
          'includePartnerActivities',
          'selectedTrackName',
          'strands'
        );
        sendSectionTemplateStats(sectionTemplateStats(sectionObj), template);
      });
    } catch (e) {
      console.log('there was an error sending stats', e);
    }
  }
}
