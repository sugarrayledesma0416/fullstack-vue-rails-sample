import { bindLessonSelectorEvents, togglePracticeTestAndStudyPlan, showActivityTitleTruncated } from './utils';
document.addEventListener('DOMContentLoaded', () => {
  const subnavTabs = document.querySelectorAll('.js-practice-test-tab, .js-study-plan-tab');
  subnavTabs.forEach((tab) => {
    tab.addEventListener('click', (event) => {
      togglePracticeTestAndStudyPlan(event.target);
    });
  });

  bindLessonSelectorEvents('section');
  showActivityTitleTruncated();
});
