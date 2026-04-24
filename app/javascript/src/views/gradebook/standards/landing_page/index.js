import { getCsvFile } from 'music';
import { mountVueAppOnElm } from 'shared/utils/vue';
import LandingStandardsReportsApp
  from 'features/gradebook/standards/landing_standards_reports/LandingStandardsReportsApp';

document.addEventListener('DOMContentLoaded', () => {
  const LandingStandardsReportsAppElm = document.querySelector('.js-landing-standards-reports-app');

  // Filter requested event
  document.addEventListener('click', function(event) {
    if (!document.querySelector('.assessment-multi-select')?.contains(event.target)) {
      document.dispatchEvent(new Event('disclosureClick'));
    }
  });

  // Set action for Export button in Student report from Section
  const studentExportButton = document.querySelector('.js-student-export-button');
  if (studentExportButton) {
    const params = JSON.parse(studentExportButton?.getAttribute('params').replaceAll('&quot;', '"'));

    studentExportButton?.addEventListener('click', (e) => {
      const csvFilename = `export_student_csv_${params.assessment_ids}.csv`;
      let getURL = `${studentExportButton?.getAttribute('formaction')}`;
      getURL += `?standard_set_display_name=${params.standard_set_display_name}`;
      getURL += `&lesson_id=${params.lesson_id}`;
      getURL += `&assessment_ids=${params.assessment_ids}`;
      getURL += `&standard_id=${params.standard_id}`;
      getCsvFile(getURL, csvFilename);
    }); 
  }

  // this is a quick fix to get the review items modal working from the section report
  const reviewableItems = document.querySelectorAll('.js-reviewable-item');

  if (reviewableItems) {
    reviewableItems.forEach( (reviewableItem) => {
      reviewableItem.addEventListener('click', function(event) {
        document.dispatchEvent(new CustomEvent('openReviewItems', { 'detail': event.currentTarget.dataset }));
      });
    });
  }

  if (LandingStandardsReportsAppElm) {
    mountVueAppOnElm(LandingStandardsReportsApp, '.js-landing-standards-reports-app', true);
  }
});
