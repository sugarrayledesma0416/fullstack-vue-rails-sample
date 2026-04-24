/**
 * @summary Generates section-metrics CSV for export.
 * An object of this class gathers section-metrics data and transforms it to
 * CSV for export. It uses the Observer pattern to gather the data. It is
 * registered as an observer of a SectionMetricsObservable instance that
 * requests data and, on receiving it, calls #update on its observers to pass
 * the data to them.
 */
class SectionMetricsCsvGenerator {
  /**
   * @constructor
   * @param {Array} sectionIds - an array of section IDs
   **/
  constructor(sectionIds) {
    this.sectionIds = sectionIds;
    this.metricsDataLookup = {};
    this.sectionsAwaitingData = new Set(sectionIds);
    this.exportButton = document.querySelector('.js-metrics-export-button');

    if(this.exportButton) {
      this.exportButton.onclick = () => this.generateCsv();
    }
  }

  /**
   * @summary Updates section-metrics dataset with data for a section.
   * @param {Object} data - hash of section-metrics data from
   * InstitutionAdminDashboardPresenter#section_metrics_data
   */
  update(data) {
    this.metricsDataLookup[data.section_id] = data;
    this.sectionsAwaitingData.delete(data.section_id.toString());

    // if we have all of the data, enable the Export button on the view
    if (this.sectionsAwaitingData.size === 0) {
      this.exportButton.removeAttribute('disabled');
    }
  }

  /**
   * @summary Builds the data structure for the CSV export and simulates clicking link
   */
  generateCsv() {
    // header row
    const csvRows = [
      [
        'Course Name',
        'Section',
        'Assistant',
        'Co-instructor',
        'Instructor',
        'Grade Avg',
        'Avg time spent',
        'Needs Grading',
        'Idle Students',
        'Assignments',
      ],
    ];
    for (const id of this.sectionIds) {
      const metricsData = this.metricsDataLookup[id];
      for (const instructor of metricsData.instructors) {
        csvRows.push(this.csvRow(metricsData, instructor));
      }
    }

    // create the CSV file
    let csvContent = 'data:text/csv;charset=utf-8,';
    csvRows.forEach(function(rowArray) {
      const row = rowArray.join(',');
      csvContent += encodeURIComponent(row + '\r\n');
    });

    // download the file
    const csvLink = document.querySelector('.js-csv-link');
    csvLink.setAttribute('href', csvContent);
    csvLink.click();
  }

  /**
   * @summary Builds an individual row for the CSV, there will be row for each
   * instructor for the section.
   * @param {Object} metricsData - data from endpoint for the section id
   * @param {String} instructor - an instructor for the section
   * @return {Array} data row for the CSV
   */
  csvRow(metricsData, instructor) {
    return [
      // replace any commas in course or section name with spaces
      metricsData.course_name.replace(/,/g, ' '),
      metricsData.section_name.replace(/,/g, ' '),
      this.lastNameForRole(instructor, 'Assistant'),
      this.lastNameForRole(instructor, 'Co-instructor'),
      this.lastNameForRole(instructor, 'Instructor'),
      metricsData.section_average,
      metricsData.avg_time_spent_per_student,
      metricsData.needs_grading,
      metricsData.idle_students,
      metricsData.assignments,
    ];
  }
  /**
   * @param {Object} instructor - Intructor object
   * @param {String} role - name of role
   * @return {String} Intructor last name if given role matches instructor role
   */
  lastNameForRole(instructor, role) {
    return instructor.role === role ? instructor.last_name : '';
  }
}

export default SectionMetricsCsvGenerator;
