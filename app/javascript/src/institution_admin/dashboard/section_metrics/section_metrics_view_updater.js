/**
 * @summary Updates view with metrics data for a section.
 * An object of this class receives section-metrics data, queries the DOM for
 * the elements that should be updated with it, and updates them. It is
 * registered as an observer of a SectionMetricsObservable instance that
 * requests data and, on receiving it, calls #update on its observers to pass
 * the data to them.
 */
class SectionMetricsViewUpdater {
  /**
   * Finds DOM elements that should be updated with given data and updates them.
   * @param {Object} data - hash of section-metrics data from
   * InstitutionAdminDashboardPresenter#section_metrics_data
   */
  update(data) {
    // updating slower loading data client side to reduce delay to the user
    // section average, average time spent per student, needs grading and idle students
    var metrics = ['section_average',
                   'avg_time_spent_per_student',
                   'needs_grading',
                   'idle_students_with_link',
                   'assignments'];
    if (data.data_admin) metrics.pop();
    metrics.forEach(metric => {
        let elm = document.querySelector(`.js-${metric}-${data.section_id}`);
        elm.innerHTML = data[metric];
      });
  }
}

export default SectionMetricsViewUpdater;
