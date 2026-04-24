import { getCsvFile } from 'music';

document.addEventListener('DOMContentLoaded', () => {
  const studentExportButton = document.querySelector('.js-student-export-button');
  const params = JSON.parse(studentExportButton.getAttribute('params').replaceAll('&quot;', '"'));

  studentExportButton.addEventListener('click', (e) => {
    const csvFilename = `export_student_csv_${params.assessment_ids}.csv`;
    let getURL = `${studentExportButton.getAttribute('formaction')}`;
    getURL += `?standard_set_display_name=${params.standard_set_display_name}`;
    getURL += `&lesson_id=${params.lesson_id}`;
    getURL += `&assessment_ids=${params.assessment_ids}`;
    getURL += `&standard_id=${params.standard_id}`;
    getCsvFile(getURL, csvFilename);
  });
});
