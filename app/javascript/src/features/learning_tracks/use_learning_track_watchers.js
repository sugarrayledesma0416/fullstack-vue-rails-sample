import { watch, toRef, computed } from 'vue';
import { dispatchCustomEvent, omit } from 'shared/utils';
import UnitRange from './models/unit_range';
import DueDateUpdater from 'features/learning_tracks/models/due_date_updater';

/**
 * @typedef {import('./models/due_date_updater.js').DueDateType} DueDateType
 */

/**
 * This composable has a method that loads all the watcher required for learning tracks.
 * @param {AssignmentCalender} assignmentCalendar - AssignmentCalendar object.
 * @param {learningTrackDataStore} learningTrackData - LearningTrackData object.
 * @param {number} reviewComponentKey - Review Assignment Component key (used to reload
 * component on change).
 * @return {Object} - An object wrapping addWatchers method
 */
const useLearningTrackWatchers = (assignmentCalendar, learningTrackData, reviewComponentKey) => {
  /**
   * It loads all the watcher required for learning tracks.
   */
  function addWatchers() {
    addDaysOfWeekWatcher();
    addSectionSourceWatcher();
    addConfigWatcher();
    addLearningTrackWatcher();
    addRespectDueDatesWatcher();
    addSelectedCourseWatcher();
    addSelectedSectionWatcher();
    addUnitRangeWatcher();
    addCurrentStepWatcher();
    addStrandsWatcher();
    addSelectedDayValuesWatcher();
    addAllowMultipleLessonsOnDatesWatcher();
    addBreakStrandAcrossDatesWatcher();
    addBreakGroupAcrossDatesWatcher();
    addAllDueDatesWatcher();
    addUnitsWatcher();
    requirementFilter('instructor_graded', 'includeInstructorGradedActivities');
    requirementFilter('require_microphone', 'includeMicrophoneActivities');
    requirementFilter('require_partner', 'includePartnerActivities');
  }

  /**
   * sets chooseTrack and unitLabel on change in config.
   */
  function addConfigWatcher() {
    watch(learningTrackData.config, (config) => {
      if (config) {
        learningTrackData.chooseTrack = config.chooseTrack;
        learningTrackData.unitLabel = config.unitLabel;
      }
    });
  }

  /**
   * Add watcher for any update in currentStep getter function.
   */
  function addCurrentStepWatcher() {
    watch(currentStepComputed, (newCurrentStepIndex) => {
      if (newCurrentStepIndex === -1) {
        return;
      } else if (newCurrentStepIndex === 0) {
        learningTrackData.store.expandChooseTemplateStep = true;
        learningTrackData.store.expandChooseTemplateAltContent = false;
      } else if (newCurrentStepIndex > 0) {
        learningTrackData.store.expandChooseTemplateStep = false;
        learningTrackData.store.expandChooseTemplateAltContent = true;
      }

      // Expand step content when its the current step, or if current step has moved past
      learningTrackData.store.expandSelectContentStep = newCurrentStepIndex >= 1;
      learningTrackData.store.expandDueDatesStep = newCurrentStepIndex >= 2;
      learningTrackData.store.expandReviewAssignmentsStep = newCurrentStepIndex >= 3;
    });
  }

  /**
   * When selection of day checkboxes changes, return true if
   * at least one day is checked.
   */
  function addDaysOfWeekWatcher() {
    const daysOfWeekRef = toRef(learningTrackData.parentDataStore, 'daysOfWeek');
    watch(daysOfWeekRef, () => {
      learningTrackData.store.selectedDayValues =
        learningTrackData.parentDataStore.daysOfWeek.filter((dayOfWeek) => {
          return dayOfWeek.selected;
        }).map((week) => week.value);
    }, { deep: true });
  }

  /**
   * When a different course template is selected, the following steps get executed:
   * Get its units
   * Set the range of the selected units
   * Update the assignment calendar categories
   */
  function addLearningTrackWatcher() {
    const learingTrackRef = toRef(learningTrackData.parentDataStore, 'learningTrack');
    watch(learingTrackRef, (track) => {
      if (track) {
        learningTrackData.parentDataStore.strands = selectStrands(track.strands);
        learningTrackData.parentDataStore.completeStrands = selectStrands(track.strands);
        assignmentCalendar.strands = Object.values(track.strands);
        learningTrackData.store.units = assignmentCalendar.units = track.units.map(
          (unit, index) => {
            unit.index = `${index}`;
            return unit;
          });
        learningTrackData.parentDataStore.unitRange = assignmentCalendar.unitRange = new UnitRange(
          learningTrackData.parentDataStore.unitRange.firstUnitIndex,
          learningTrackData.parentDataStore.unitRange.lastUnitIndex,
          learningTrackData.store.units
        );
        assignmentCalendar.learningTrack = track;

        if (track.categories === Object(track.categories)) {
          assignmentCalendar.categories = track.categories;
        } else {
          assignmentCalendar.categories =
            learningTrackData.store.learningTracks.categories[track.categories];
        }
      }
      refresh();
    }, { deep: true });
  }

  /**
   * For preexisting sections, if the user toggles "Keep assignments grouped
   * as they were in the existing section", update the settings of the
   * remaining assignment options to suit.
   */
  function addRespectDueDatesWatcher() {
    const respectDueDatesRef = toRef(learningTrackData.parentDataStore, 'respectDueDates');
    watch(respectDueDatesRef, (respectDueDates) => {
      assignmentCalendar.respectDueDates = respectDueDates;
      if (respectDueDates) {
        learningTrackData.store.allowMultipleLessonsOnDates = true;
        learningTrackData.store.breakGroupAcrossDates = true;
        learningTrackData.store.breakStrandAcrossDates = true;
      }
      refresh();
    });
  }

  /**
   * When institution admin toggles between source = course/section
   * and source = course template/section template, set both course
   * and section dropdown to the neutral option:
   */
  function addSectionSourceWatcher() {
    watch(learningTrackData.parentDataStore.sectionSource, () => {
      learningTrackData.store.selectedCourse = '';
      learningTrackData.store.selectedSection = '';
    });
  }

  /**
   *  When user selects an existing course, set the section dropdown
   *  to the neutral option.
   */
  function addSelectedCourseWatcher() {
    const selectedCourseRef = toRef(learningTrackData.store, 'selectedCourse');
    watch(selectedCourseRef, (newCourse) => {
      if (newCourse) {
        const courses = previousCourses();
        const requiredCourse = courses.find((course) => course.id.toString() === newCourse);
        if (!requiredCourse) {
          resetAvailableSections();
          return;
        }

        const { enterprise, sections, name } = requiredCourse;
        const firstSection = sections?.[0] || {};

        Object.assign(learningTrackData.store, {
          selectedCourseIsEnterprise: !!enterprise,
          selectedCourseName: name,
          availableSections: sections || [],
          selectedSection: enterprise ? firstSection.id : '',
          selectedSectionName: enterprise ? firstSection.name : '',
          selectedSectionId: enterprise ? firstSection.id : null,
          selectedSectionClassDaysCount: enterprise ? firstSection.class_days_count : null,
        });
      }
    });
  }

  /**
   * Get previous courses or course templates, depending on section source type.
   * @return {Proxy} Reactive copy of an array of courses
   */
  function previousCourses() {
    if (learningTrackData.sectionSourceType === 'section') {
      return learningTrackData.config.previous_courses;
    }
    return learningTrackData.config.previous_course_templates;
  }

  /**
   *  When user selects an available section, selected section id is set.
   */
  function addSelectedSectionWatcher() {
    const selectedSectionRef = toRef(learningTrackData.store, 'selectedSection');
    watch(selectedSectionRef, (newValue) => {
      if (learningTrackData.store.selectedCourseIsEnterprise) {
        return;
      }

      if (newValue) {
        const { store: { availableSections }} = learningTrackData;
        const requiredSection = availableSections.find(
          (section) => section.id.toString() === newValue
        );
        learningTrackData.store.selectedSectionName = requiredSection?.name;
        learningTrackData.store.selectedSectionClassDaysCount = requiredSection?.class_days_count;
        learningTrackData.store.selectedSectionId = requiredSection?.id;
      } else {
        learningTrackData.store.selectedSectionId = null;
      }
    });
  }

  /**
   * Add watcher for change in strands value.
   */
  function addStrandsWatcher() {
    const strandsRef = toRef(learningTrackData.parentDataStore, 'strands');
    watch(strandsRef, (strands) => {
      assignmentCalendar.strands = getSelectedStrands(strands);
      refresh();
    }, { deep: true });
  }

  /**
   *  Add watcher for change in units.
   */
  function addUnitRangeWatcher() {
    const unitRangeRef = toRef(learningTrackData.parentDataStore, 'unitRange');
    watch(unitRangeRef, (newVal) => {
      if (newVal) {
        if (learningTrackData.parentDataStore.unitRange.isValid) {
          if (learningTrackData.store.units) {
            let selectedIds = learningTrackData.store.units.map((unit, index) => {
              if (index >= newVal.firstUnitIndex && index <= newVal.lastUnitIndex) {
                return unit.id
              }
            } );
            const selectedStrands = learningTrackData.parentDataStore.completeStrands.filter(
              (strand) => {
                return strand.unit_ids.some((unit_id) => { return selectedIds.includes(unit_id) });
              }
            );
            learningTrackData.parentDataStore.strands = selectedStrands;
            refresh();
          }
        }
      }
    }, { deep: true });
  }

  /**
   *  When the set of selected days changes, update the set of dates used
   *  in the assignment calendar:
   */
  function addSelectedDayValuesWatcher() {
    const selectedDayValuesRef = toRef(learningTrackData.store, 'selectedDayValues');
    watch(selectedDayValuesRef, () => {
      // Ensure that start/end date range is present.
      if (learningTrackData.config.start_date && learningTrackData.config.end_date) {
        // courseInfo.start_date and course.start_date are both in different formats.
        // the former is for the Assignment Wizard, and the latter is for Express Course Creation.
        const startDateInAssignment = learningTrackData.parentDataStore.courseInfo?.start_date;
        const startDateInExpressCourse = learningTrackData.parentDataStore.course?.startDate;
        const startDate = startDateInAssignment || startDateInExpressCourse;
        const start = moment(startDate).format('MM/DD/YYYY');
        const courseDueDates = DueDateUpdater.getCustomDates(
          start,
          learningTrackData.config.end_date,
          learningTrackData.store.selectedDayValues
        );
        const lockedDueDates = DueDateUpdater.getLockedDueDates(
          learningTrackData.parentDataStore.allDueDates
        );
        // we may optimize by setting locked due dates on assignment calendar here
        learningTrackData.parentDataStore.allDueDates = DueDateUpdater.synthesizeDates(
          lockedDueDates,
          courseDueDates
        );
        // If there are no learning track activities and we are here
        // is because the course has external items that are going to be imported
        // but does not have assignments.
        // We need to add the course categories to the categoryMappingList
        // so external items are imported to the new course category
        if (learningTrackData.parentDataStore.learningTrack.activities.length === 0) {
          learningTrackData.parentDataStore.categoryMappingList = Object.keys(
            learningTrackData.parentDataStore.learningTrack.categories
          );
        }
      }
    });
  }

  /**
   * If the "allow multiple lessons on one date" checkbox is clicked,
   * toggle that calendar property.
   */
  function addAllowMultipleLessonsOnDatesWatcher() {
    const allowMultipleLessonsOnDatesRef = toRef(
      learningTrackData.store,
      'allowMultipleLessonsOnDates'
    );
    watch(allowMultipleLessonsOnDatesRef, (isChecked) => {
      assignmentCalendar.splitLessons = !isChecked;
      refresh();
    });
  }

  /**
   * If the "Allow strand to be split across dates" checkbox is clicked,
   * toggle that calendar property.
   * When the breakStrandAcrossDates is unchecked, uncheck breakGroupAcrossDates too.
   * Same when breakStrandsAcrossDates is checked.
   */
  function addBreakStrandAcrossDatesWatcher() {
    const breakStrandAcrossDatesRef = toRef(learningTrackData.store, 'breakStrandAcrossDates');
    watch(breakStrandAcrossDatesRef, (isChecked) => {
      assignmentCalendar.keepStrands = !isChecked;
      learningTrackData.store.breakGroupAcrossDates = isChecked;
      refresh();
    });
  }

  /**
   * If the "Allow learning group assignments to be split across dates"
   * checkbox is clicked, toggle that calendar property.
   */
  function addBreakGroupAcrossDatesWatcher() {
    const breakGroupAcrossDatesRef = toRef(learningTrackData.store, 'breakGroupAcrossDates');
    watch(breakGroupAcrossDatesRef, (isChecked) => {
      assignmentCalendar.keepGroups = !isChecked;
      refresh();
    });
  }

  /**
   * Add watcher on allDueDates property
   */
  function addAllDueDatesWatcher() {
    watch(allDueDatesWithLockedOmitted, () => {
      const allDueDates = learningTrackData.parentDataStore.allDueDates;
      assignmentCalendar.dueDates = allDueDates.filter((date) => date.selected);
      refresh();
    }, { deep: true });
  }

  /**
   * Add watcher on units property
   */
  function addUnitsWatcher() {
    const unitsRef = toRef(learningTrackData.store, 'units');
    watch(unitsRef, (newVal) => {
      if (Array.isArray(newVal) && newVal.length > 0) {
        learningTrackData.chooseTrack = false;
      }
    }, { deep: true });
  }

  /**
   * Add watcher on different requirements like instructor_graded, require_microphone,
   * require_partner.
   * @param {string} requirement
   * @param {string} flag
   */
  function requirementFilter(requirement, flag) {
    const requiredRef = toRef(learningTrackData.parentDataStore, flag);
    watch(requiredRef, () => refresh());

    assignmentCalendar.registerFilter((activity) => {
      return learningTrackData.parentDataStore[flag] ||
        !activity.activity_requirements[requirement];
    });
  }

  /**
   * it retrieves the strands specified by the strand names and marks them as selected.
   * @param {Array.<string>} strandNames - names of the desired strands
   * @return {Array}
   */
  function selectStrands(strandNames) {
    return strandNames.map((strandName) => {
      const strand = learningTrackData.store.learningTracks.strands[strandName];
      strand.selected = true;
      return strand;
    });
  }

   /**
   * Resets the available sections and related selection properties.
   * This is used when no course is selected or the selected course does not exist.
   */
   function resetAvailableSections() {
    // Reset the list of available sections to an empty array.
    learningTrackData.store.availableSections = [];

    // Clear the selected section and its related properties.
    learningTrackData.store.selectedSection = '';
    learningTrackData.store.selectedSectionId = null;
    learningTrackData.store.selectedSectionName = '';
    learningTrackData.store.selectedSectionClassDaysCount = null;

    // Mark the course as non-enterprise by default.
    learningTrackData.store.selectedCourseIsEnterprise = false;
  }

  /**
   * returns the name of selected strands name.
   * @param {Array} strands - array of strands object
   * @return {Array.<string>} - strand names array
   */
  function getSelectedStrands(strands) {
    const selectedStrands = strands.filter((strand) => strand.selected);
    return selectedStrands.map((strand) => strand.name);
  }

  /**
   * Refresh the assignment calendar.
   */
  function refresh() {
    const calendar = assignmentCalendar.build();
    assignmentCalendar.prev = calendar;
    if (calendar) {
      dispatchCustomEvent({
        name: 'assignment_calendar_refresh',
        detail: { calendar },
      });
      reviewComponentKey.value += 1;
    }
  }

  const currentStepComputed = computed(() => learningTrackData.currentStep);

  /**
   * Computed property to get allDueDates with 'locked' property omitted in each date object.
   * @return {Array.<DueDateType>} - dueDates without 'locked' property
   */
  const allDueDatesWithLockedOmitted = computed(() => {
    return learningTrackData.parentDataStore.allDueDates?.map((date) => {
      return omit(['locked'], date);
    });
  });

  return { addWatchers };
};

export default useLearningTrackWatchers;
