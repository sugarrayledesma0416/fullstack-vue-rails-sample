import 'views/gradebook/standards/landing_page/';
import 'views/gradebook/standards/icons/columnAscending';
import 'views/gradebook/standards/icons/columnDescending';
import 'views/gradebook/standards/icons/columnUnsorted';
import 'views/gradebook/standards/icons/assessmentCount';
import 'views/instructor/standards_assigning/icons/magnifyingGlassIcon';
import 'views/gradebook/standards/icons/thickArrow';

document.addEventListener('DOMContentLoaded', () => {
  const reportTabActive = sessionStorage.getItem('reportTabActive') || 'section-report';
  const currentTab = document.querySelector(`.js-report-tab-button[data-tab-info=${reportTabActive}]`);
  const sectionInnerReport = document.querySelector('.js-section-inner-button');
  const studentRows = document.querySelectorAll('.js-student-result-row');

  if (reportTabActive) {
    document.querySelectorAll('.js-report-tab-button').forEach((tab) => {
      tab.classList.remove('is-current');
    });
    if (currentTab) {
      currentTab.classList.add('is-current');
      document.querySelector(`.js-${reportTabActive}`).classList.remove('u-dis-none');
    }
  }

  document.querySelectorAll('.js-report-tab-button').forEach((tab) => {
    tab.addEventListener('click', () => {
      showTabContent(tab.dataset.tabInfo);
    });
  });

  function showTabContent(tabName) {
    sessionStorage.setItem('reportTabActive', tabName);
    document.querySelectorAll('.js-report-tab-button').forEach((tab) => {
      document.querySelector(`.js-${tab.dataset.tabInfo}`).classList.add('u-dis-none');
      document.querySelector(`.js-report-tab-button[data-tab-info=${tab.dataset.tabInfo}]`).classList.remove('is-current');
    });
    document.querySelector(`.js-report-tab-button[data-tab-info=${tabName}]`).classList.add('is-current');
    document.querySelector(`.js-${tabName}`).classList.remove('u-dis-none');
  }

    sectionInnerReport?.addEventListener('click', () => {
      sessionStorage.setItem('reportTabActive', 'student-report');
    });
});
