import { reactive } from 'vue';
import LearningTrackHttp from './models/learning_track_http';
import UnitRange from './models/unit_range';
import GroupMenu from './models/group_menu';

/**
 * @typedef {
 *  import('features/course_wizard/models/new_course_data_store.js').NewCourseDataStoreType
 * } NewCourseDataStoreType
 */

/**
 * @typedef {import('./models/due_date_updater.js').DueDateType} DueDateType
 */

/**
 * @typedef {
 *  import('features/assignment_wizard/models/assignment_wizard.js').DayOfWeekObject
 * } DayOfWeekObject
 */

/**
 * @typedef {
  *  import('features/assignment_wizard/models/assignment_wizard.js').SectionSourceObject
  * } SectionSourceObject
  */

/**
 * @typedef {
  *  import('features/learning_tracks/directives/work_load_graph.js').WorkLoadObject
  * } WorkLoadObject
  */

/**
 * @typedef {ConfigObject}
 * @property {boolean} chooseTrack
 * @property {string} end_date
 * @property {boolean} has_assignments
 * @property {Array} previous_courses
 * @property {string} start_date
 * @property {string} unit_label
 */

/**
 * @typedef {
  *  import('features/assignment_wizard/models/assignment_calendar.js').DueDate
  * } DueDate
  */

/**
 * @typeDef {AssignmentWizardStoreObject}
 * @property {Array.<DueDateType>} allDueDates
 * @property {Object} calendar - calendar object.
 * @property {Array} categories - array of categories object
 * @property {Array.<string>} categoryMappingList
 * @property {Object} courseInfo - course info Object.
 * @property {Array.<DayOfWeekObject>} daysOfWeek
 * @property {boolean} disableAllControls
 * @property {boolean} includeInstructorGradedActivities
 * @property {boolean} includeMicrophoneActivities
 * @property {boolean} includePartnerActivities
 * @property {Object} learningTrack - learning track object
 * @property {Object} learningTracksConfig - configuration for learning tracks.
 * @property {boolean} loadingLearningTracks
 * @property {boolean} respectDueDates
 * @property {boolean} sectionHasAssignments
 * @property {SectionSourceObject} sectionSource
 * @property {String} selectedTrackName
 * @property {Object} setupDescriptions
 * @property {Array} strands - array of strands
 * @property {UnitRange} unitRange
 * @property {Object} usingPredefinedTrack - learning track object
 */

/**
 * This class initializes Learning Track app state and
 * has methods to manipulate the app state.
 */
export default class LearningTrackDataStore {
  /**
   * Initialize reactive object which stores learning track app state
   * @constructor
   * @param {AssignmentWizard|LearningTracksStepDataStore} parentModel - Either Assignment Wizard
   * or Course Wizard model
   */
  constructor(parentModel) {
    this.parentModel = parentModel;
    this.store = reactive(this.initStoreData);
    this.groupMenu = new GroupMenu(parentModel);
    if (window.moment) {
      this.now = moment();
    }
  }

  /**
   * returns activities per lesson.
   * @return {number}
   */
  get activitiesPerLesson() {
    const unitCount = this.parentDataStore.unitRange.count;
    if (unitCount > 0 && this.workLoad) {
      return Math.round(this.workLoad.activityCount / unitCount);
    } else {
      return 0;
    }
  }

  /**
   * returns average work hours per lesson.
   * @return {number}
   */
  get averageWorkHoursPerLesson() {
    if (this.workLoad) {
      return (this.workLoad.avg / 60).toFixed(1);
    } else {
      return 0;
    }
  }

  /**
   * returns chooseTrack
   * @return {boolean}
   */
  get chooseTrack() {
    return this.parentDataStore.learningTracksConfig.chooseTrack;
  }

  /**
   * sets chooseTrack
   * @param {string} newValue - value fetched from v-model.
   */
  set chooseTrack(newValue) {
    this.parentDataStore.learningTracksConfig.chooseTrack = newValue;
  }

  /**
   * returns config
   * @return {ConfigObject}
   */
  get config() {
    return this.parentDataStore.learningTracksConfig;
  }

  /**
   * sets config
   * @param {string} newValue
   */
  set config(newValue) {
    this.parentDataStore.learningTracksConfig = newValue;
  }

  /**
   * it returns the current step which is highlighted.
   * @return {number} the current step
   */
  get currentStep() {
    let step = -1;
    const lastUnitIndex = this.parentDataStore.unitRange.lastUnitIndex;
    const firstUnitIndex = this.parentDataStore.unitRange.firstUnitIndex;
    const selectValues = lastUnitIndex && lastUnitIndex !== '-1' && firstUnitIndex !== '';

    const unitsExist = this.store.units && this.store.units.length > 0;
    const unitsSelected = unitsExist && selectValues;
    const daysSelected = this.store.selectedDayValues && this.store.selectedDayValues.length > 0;

    if (this.chooseTrack) {
      step = 0;
    } else if (unitsExist && !unitsSelected) {
      step = 1;
    } else if (unitsSelected && !daysSelected) {
      step = 2;
    } else if (daysSelected) {
      step = 3;
    } else if (this.parentModel.assignmentCalendar.copyIgc) {
      // if currentStep gets here, it means "Copy Instructor-created Activities and Items"
      // was checked and the chosen section has only external items,
      // so there are not units available because
      // learning tracks do not contain external items.
      // Then we can go to step 3(2 in the code) for the instructor
      // to be able to complete the import from the Assignment Wizard.
      step = 2;
    }
    return step;
  }

  /**
   * @private
   * Initialise store data for learning tracks.
   */
  get initStoreData() {
    return {
      allowMultipleLessonsOnDates: true,
      availableSections: [],
      allStrands: null,
      breakGroupAcrossDates: true,
      breakStrandAcrossDates: true,
      expandChooseTemplateStep: false,
      expandDueDatesStep: false,
      expandSelectContentStep: false,
      expandReviewAssignmentsStep: false,
      insufficientLicenseGroups: false,
      learningTracks: null,
      predefinedTracks: null,
      predefinedTrackNames: null,
      selectedCourse: '',
      selectedCourseName: '',
      selectedCourseIsEnterprise: false,
      selectedDayValues: [],
      selectedSection: '',
      selectedSectionName: '',
      selectedSectionClassDaysCount: 0,
      selectedSectionId: null,
      loadingPreviousTrack: false,
      trackTabs: { index: 0 },
      units: null,
      VOL: VISTA_ONLINE_LEARNING,
    };
  }

  /**
   * used in UI to control access to the asignment wizard template chooser.
   * @return {boolean}
   */
  get isTemplateChooserDisabled() {
    return (
      this.parentDataStore.sectionHasAssignments ||
      !!this.allDueDates?.some((date) => date.locked) ||
      this.parentDataStore.disableAllControls
    );
  }

  /**
   * returns the parent data store i.e. either assignment wizard or course express.
   * @return {AssignmentWizardStoreObject|NewCourseDataStoreType}
   */
  get parentDataStore() {
    return this.parentModel.store;
  }

  /**
   * returns the section source type
   * @return {string}
   */
  get sectionSourceType() {
    return this.parentDataStore.sectionSource.type;
  }

  /**
   * sets the section source value.
   * @param {string} newValue - value fetched from v-model.
   */
  set sectionSourceType(newValue) {
    this.parentDataStore.sectionSource.type = newValue;
  }

  /**
   * returns the learning tracks defined in setup description from either
   * assignment wizard or express course setup.
   * @return {Array}
   */
  get setupTracks() {
    return this.parentDataStore.setupDescriptions.learning_tracks;
  }

  /**
   * returns unitLabel
   * @return {string}
   */
  get unitLabel() {
    return this.parentDataStore.learningTracksConfig.unit_label;
  }

  /**
   * sets unitLabel
   * @param {string} newValue
   */
  set unitLabel(newValue) {
    this.parentDataStore.learningTracksConfig.unit_label = newValue;
  }

  /**
   *  returns the calendar workload
   * @return  {WorkLoadObject} workLoad - represents workload.
   */
  get workLoad() {
    return this.parentDataStore.calendar?.workLoad;
  }

  /**
   * click event on change course template section.
   * when change course template is enabled, choosing course template step is visible.
   */
  clickTemplateChooser() {
    this.chooseTrack = !this.isTemplateChooserDisabled;
  }

  /**
   * returns whether due date is previous to current date.
   * @param {DueDate} date - due date.
   * @return {boolean}
   **/
  isPrevious(date) {
    return !moment(date.name).isAfter(this.now);
  }

  /**
   * locks a due date.
   * @param {DueDate} date - date object.
   **/
  lockDueDate(date) {
    date.locked = true;
  }

  /**
   * unlocks a due date.
   * @param {DueDate} date - date object.
   **/
  unlockDueDate(date) {
    date.locked = this.isPrevious(date);
  }

  /**
   * returns the length of the subtrack corresponding to the trackName passed.
   * @param  {string} trackName Name of the track
   * @return {number} length of the subtracks.
   */
  preDefinedSubtrackLength(trackName) {
    return Object.keys(this.store.predefinedTracks.tracks[trackName].subtracks).length;
  }

  /**
   * This method returns the state of the panel corresponding to the
   * correct UI state for each section, based on a set of conditions.
   * @param {number} step - Indicates which learning tracks step we are adding classes to.
   * @return { 'upcoming' | 'finished' | 'active' } - State of the panel be applied
   */
  state(step) {
    const currentStep = this.currentStep;
    if (currentStep >= 0) {
      if (step > currentStep) {
        return 'upcoming';
      } else if (step < currentStep) {
        return 'finished';
      }
      return 'active';
    }
  }

  /**
   * When a learning track has been selected, initialize
   * various states and properties.
   *
   * @param {string} trackFamilyName Family (category) of the subtrack.
   * @param {string} subtrackName Name of the subtrack.
   * @param {Object} subtrack The subtrack object.
   */
  usePredefinedTrack(trackFamilyName, subtrackName, subtrack) {
    this.parentDataStore.learningTrack = subtrack;
    this.chooseTrack = false;
    this.parentDataStore.selectedTrackName = trackFamilyName + ': ' + subtrackName;
    this.parentDataStore.respectDueDates = false;
    this.parentDataStore.usingPredefinedTrack = true;
    this.store.insufficientLicenseGroups = false;
  }

  /**
   * When a pre-existing course/section has been selected, retrieve the
   * corresponding course template.
   * Once the data is loaded, set the unit range and initialize
   * various states and properties.
   * @param {AssignmentCalender} assignmentCalendar - assignment calendar object.
   * @param {number} programId
   */
  async useSectionTrack(assignmentCalendar, programId) {
    const currentCourseId = this.parentDataStore.courseInfo ?
      this.parentDataStore.courseInfo.current_course : null;
    const learningTrackHttp = new LearningTrackHttp(programId);
    this.store.loadingPreviousTrack = true;
    const result = await learningTrackHttp.getPreviousTrack(
      this.store.selectedSectionId, currentCourseId
    );

    const externalItems = await learningTrackHttp.getExternalItems(this.store.selectedSectionId);

    this.parentDataStore.showWarningMessage =
      this.setUpWarningMessage(assignmentCalendar,
        this.parentDataStore.sectionHasAssignments,
        externalItems);

    if (assignmentCalendar.copyIgc) {
      this.parentDataStore.externalItems = externalItems;
    } else {
      this.parentDataStore.externalItems = null;
    }

    this.store.loadingPreviousTrack = false;

    this.parentDataStore.selectedSectionId = this.store.selectedSectionId;

    this.parentDataStore.unitRange = assignmentCalendar.unitRange = new UnitRange(
      '0', `${result.units.length - 1}`, this.store.units
    );

    this.store.allowMultipleLessonsOnDates = true;
    this.parentDataStore.respectDueDates = true;
    this.parentDataStore.usingPredefinedTrack = false;
    this.store.insufficientLicenseGroups = result.insufficient_license_groups;

    this.parentDataStore.learningTrack = result;
    this.parentDataStore.selectedTrackName = this.store.selectedCourseName + ', ' +
      this.store.selectedSectionName;

    this.chooseTrack = false;
    this.store.trackTabs = { index: 0 };

    // As the course settings are only used for express course creation,
    // we need to filter them out for assignment wizard checking for course options
    // before we copy the settings.
    if (this.parentDataStore.courseOptions) {
      this.copySourceCourseSettings(parseInt(this.store.selectedCourse));
    }
  }

  /**
   * @private
   * Copies the selected source course settings for express course creation
   * @param {number} selectedCourseId - the id of the selected course.
   */
  copySourceCourseSettings(selectedCourseId) {
    const sourceCourseSettings = this.parentDataStore.courseOptions.settings.find(
      (course) => course.id === selectedCourseId
    );

    this.parentDataStore.settingsCourses.contentSettingsCourse = sourceCourseSettings;
    this.parentDataStore.settingsCourses.categorySettingsCourse = {
      categories: sourceCourseSettings.categories,
    };
  }

  /**
   * @private
   * Validation when the user selects a course and the section does not contain any
   * activities assigned to copy and the checkboxes for Copy activities and elements
   * created by the instructor and Copy activities assigned individually are unchecked.
   *
   * @param {AssignmentCalender} assignmentCalendar - assignment calendar object.
   * @param {boolean} sectionHasAssignments - section and assignments validation.
   * @param {Object} externalItems - external items object.
   * @return {boolean}
   */
  showSelectCourseMsg(assignmentCalendar, sectionHasAssignments, externalItems) {
    return !assignmentCalendar.copyIgc &&
           !assignmentCalendar.copyIac &&
           !sectionHasAssignments &&
           (Array.isArray(externalItems) && externalItems.length !== 0);
  }

  /**
   * @private
   * Validation when the user selects a course and the section does not contain any assigned
   * activities to copy and the checkbox to Copy individually assigned activities is marked.
   *
   * @param {AssignmentCalender} assignmentCalendar - assignment calendar object.
   * @param {boolean} sectionHasAssignments - section and assignments validation.
   * @param {Object} externalItems - external items object.
   * @return {boolean}
   */
  showUncheckOrSelectCourseMsg(assignmentCalendar,
    sectionHasAssignments,
    externalItems) {
    return !assignmentCalendar.copyIgc &&
           assignmentCalendar.copyIac &&
           !sectionHasAssignments &&
           JSON.stringify(externalItems) == '{}';
  }

  /**
   * @private
   * Validation when the user selects a course and the section only has external items to
   * copy and the Copy individually assigned activities is marked.
   *
   * @param {AssignmentCalender} assignmentCalendar - assignment calendar object.
   * @param {boolean} sectionHasAssignments - section and assignments validation.
   * @param {Object} externalItems - external items object.
   * @return {boolean}
   */
  showUncheckOrSelectCourseSectionMsg(assignmentCalendar,
    sectionHasAssignments,
    externalItems) {
    return !assignmentCalendar.copyIgc &&
           assignmentCalendar.copyIac &&
           !sectionHasAssignments &&
           JSON.stringify(externalItems) != '{}';
  }

  /**
   * @private
   * Determinate the warning message according to a validation that is performed.
   *
   * @param {AssignmentCalender} assignmentCalendar - assignment calendar object.
   * @param {boolean} sectionHasAssignments - section and assignments validation.
   * @param {Object} externalItems - external items object.
   * @return {string} - warning message.
   */
  setUpWarningMessage(assignmentCalendar, sectionHasAssignments, externalItems) {
    if (this.showSelectCourseMsg(assignmentCalendar, sectionHasAssignments, externalItems)) {
      return 'The course and section you selected does not contain any assigned activities ' +
        'to copy. To continue, select a different course and section.';
    } else if (this.showUncheckOrSelectCourseMsg(assignmentCalendar,
      sectionHasAssignments,
      externalItems)) {
      return 'The course and section you selected does not contain any activities to copy. ' +
        'To continue, uncheck the box or select a different course and section.';
    } else if (this.showUncheckOrSelectCourseSectionMsg(assignmentCalendar,
      sectionHasAssignments,
      externalItems)) {
      return 'The course and section you selected only contains external items. To continue, ' +
        'uncheck Individually Assigned Activities or select a different course and section.';
    } else {
      return '';
    }
  }
}