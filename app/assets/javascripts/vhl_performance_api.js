/**
 * This class provides some utilities for working the browser's Performance API:
 * https://developer.mozilla.org/en-US/docs/Web/API/Performance
 */

/**
 * PerformanceApi
 * @returns {Object} A module of helper functions for using Performance API.
 **/

VHL.PerformanceApi = (function() {

  /**
   * Checks Performance Api support in browser.
   * @private
   * @returns {boolean} Returns true if supported else returns false.
   */
  function isApiSupported() {
    return (
      (typeof(Performance) !== "undefined") &&
        (performance.mark !== undefined) &&
        (performance.measure !== undefined)
    );
  }

  /**
   * Clears a measure within the Performance API.
   * @private
   * @param {string} measureNames (Optional) Array of Names of measure to be cleared.
   */
  function clearMeasure(measureName) {
    if(measureName) {
      performance.clearMeasures(measureName);
    }
  }

  /**
   * getMetrics
   * getMetrics checks if the Performance API is supported.
   * If it is, it gets the metric, perform a callback with the
   * metric as its argument, and clears the metric
   * from the Performance API.
   * @param {String} metricName - The name of a metric to retrieve from the Performance API
   * @param {Function} callback - A function that has access to the retrieved metric
   * as its argument. This is a place where the metric can be dispatched.
   */
  function getMetrics(metricName, callback) {
    if (isApiSupported) {
      var metric = performance.getEntriesByName(metricName)[0];
      callback(metric);
      clearMeasure(metricName);
    }
  }

  return {
    getMetrics: getMetrics
  };
})();
