/**
 * Set up the endpoint for the passed viewType &
 * bind event listener to a lesson selector dropdown.
 * @param {String} viewType 'section' or 'individual'
 */
const bindLessonSelectorEvents = (viewType) => {
  const lessonUnitSelector = document.querySelector('.js-lesson-select') ||
                             document.querySelector('.js-unit-select');
  const twoTierProgram = (document.querySelector('.js-two-tier-program').value == 'true');
  const { programId, courseId, sectionId, studentId } = lessonUnitSelector.dataset;
  const urlPrefix = `${location.origin}/gradebook/${programId}/courses/${courseId}` +
        `/sections/${sectionId}/analytics/practice_test`;
  let urlSuffix;
  const lessonUnitParam = twoTierProgram ? 'unit_id=' : 'lesson_id=';
  if (viewType === 'section') {
    urlSuffix = `?${lessonUnitParam}`;
  } else {
    urlSuffix = `/individual_student?student_id=${studentId}&${lessonUnitParam}`;
  }

  lessonUnitSelector.addEventListener('change', (event) => {
    const studyPlanTab = document.getElementById('study-plan-tab');
    const lessonUnitId = lessonUnitSelector.value;

    if (studyPlanTab != null) {
      const currentTab =
        studyPlanTab.classList.contains('is-current') ? 'study-plan-tab' : 'practice-test-tab';
      window.location = urlPrefix + urlSuffix + lessonUnitId + `&current_tab=${currentTab}`;
      return;
    }
    window.location = urlPrefix + urlSuffix + lessonUnitId;
  });
};

/**
 * Style the clicked tab on the practice test subnav as current,
 * and show the data for the chosen tab.
 * @param {Element} target The clicked element on the subnav
 */
const togglePracticeTestAndStudyPlan = (target) => {
  const subnavLinks = document.querySelectorAll('.js-practice-test-subnav .c-subnav__link');
  subnavLinks.forEach((elm) => elm.classList.toggle('is-current', elm === target));

  /**
   * Toggle the visibility of the content area
   */
  const content = document.querySelectorAll('.js-practice-test-content, .js-study-plan-content');
  content.forEach((elm) => elm.classList.toggle('u-hidden'));
};

/**
 * Shows a title with the title of the activity
 * if the text in the cell is truncated.
 */
const showActivityTitleTruncated = () => {
  const activityTitles = document.querySelectorAll('.js-check-truncated-title');

  const isActivityTitleTruncated = (e) => {
    return (e.offsetWidth < e.scrollWidth);
  };
  activityTitles.forEach((elm) => {
    if (isActivityTitleTruncated(elm)) elm.setAttribute('title', elm.dataset.activityTitle);
  });
};

export {
  bindLessonSelectorEvents,
  togglePracticeTestAndStudyPlan,
  showActivityTitleTruncated,
};
