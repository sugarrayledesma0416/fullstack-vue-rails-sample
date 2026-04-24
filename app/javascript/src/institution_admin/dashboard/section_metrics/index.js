import { programId } from 'shared/utils.js';
import SectionMetricsObservable from './section_metrics_observable.js';
import SectionMetricsViewUpdater from './section_metrics_view_updater.js';
import SectionMetricsCsvGenerator from './section_metrics_csv_generator.js';

// Query the DOM for section IDs associated with metrics-data elements.
function getSectionIds() {
  return [...document.querySelectorAll('.js-section-metrics-data')].map(
    elm => elm.dataset.sectionId
  );
};

/**
 * On DOMContentLoaded, create a SectionMetricsObservable.
 *
 * It requests section metrics data for one section at a time.
 * It also can register observers.
 * When section data are received, it will call its observers to
 * update themselves with the data.
 *
 * The observers are
 * - a view updater that will be responsible for updating
 *   the section-metrics row for the section with the data
 * - a CSV generator that can
 *   - aggregate the data
 *   - create a CSV file for download
 *   - when all sections have complete data, enable a button
 *     that calls the create-CSV functionality
 */
window.addEventListener('DOMContentLoaded', (event) => {
  let sectionIds = getSectionIds();
  let sectionMetricsObservable = new SectionMetricsObservable(
    programId(),
    sectionIds
  );
  let sectionMetricsViewUpdater = new SectionMetricsViewUpdater();
  let sectionMetricsCsvGenerator = new SectionMetricsCsvGenerator(
    sectionIds
  );

  sectionMetricsObservable.registerObservers(
    [sectionMetricsViewUpdater, sectionMetricsCsvGenerator]
  );

  sectionMetricsObservable.getMetricsData();
});
