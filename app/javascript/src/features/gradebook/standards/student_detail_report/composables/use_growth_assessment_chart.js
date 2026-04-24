import Highcharts from 'highcharts';
import CustomEvents from 'highcharts-custom-events';
import GrowthAssessmentChartConfigurator from '../models/growth_assessment_chart_configurator';

/**
 * This line lets us add click event listeners to the xAxis labels as part of the Highcharts config
 * object.
 */
CustomEvents(Highcharts);

/**
 * @param {String} divID The value of the `id` attribute for the chart's container div
 * @param {Object} config Options for the Highcharts chart config
 * @param {Function} emit Function to emit events to the parent component
 * @returns {Object} Object containing reference to createChart function
 */
export default function useGrowthAssessmentChart(divId, config, emit) {
  function createChart() {
    const chartConfig = JSON.parse(config);

    /**
     * @description Defines shape to be used as container for tooltip.
     * @param {Number} x Starting value for x (seems to be 0)
     * @param {Number} y Starting value for y (seems to be 0)
     * @param {Number} w Width of the containing rectangle
     * @param {Number} h Height of the containing rectangle
     * @return {Highcharts.SVGPathArray} Array defining the symbol path
     */
    Highcharts.SVGRenderer.prototype.symbols.sharedCallout = function(x, y, w, h) {
      const radius = 3;

      const segments = [
        // Start at the origin (0, 0) -- this is the upper LH corner
        ['M', x + radius, y],
        // Line to the upper RH corner
        ['H', x + w - radius],
        // Rounded upper RH corner
        ['A', radius, radius, 0, 0, 1, x + w, y + radius],
        /**
         * Triangle jutting out from the right side:
         */
        // Line to just before the halfway point on the right side
        ['V', y + radius + h/2 - 7],
        // Line to a few pixels to the right of the halfway point of the right side
        ['L', x + w + 10, y + radius + h/2],
        // Line back to the right hand side, symmetrical with the previous segment
        ['L', x + w, y + radius + h/2 + 7],

        // Line to the lower RH corner
        ['V', y + h - radius],
        // Rounded lower RH corner
        ['A', radius, radius, 0, 0, 1, x + w - radius, y + h],
        // Line to the lower LH corner
        ['H', x + radius],
        // Rounded lower LH corner
        ['A', radius, radius, 0, 0, 1, x, y + h - radius],
        // Line to the upper LH corner
        ['V', y + radius],
        // Rounded upper LH corner
        ['A', radius, radius, 0, 0, 1, x + radius, y],
        // Complete the path
        'z',
      ];
      return segments.flat();
    };

    Highcharts.chart(
      divId,
      GrowthAssessmentChartConfigurator.createHighchartsConfig(chartConfig, emit)
    );

    const dropShadow = document.querySelector('#highcharts-drop-shadow-0 feDropShadow');
    dropShadow.setAttribute('dx', 2);
    dropShadow.setAttribute('dy', 3);
    dropShadow.setAttribute('flood-opacity', 0.25);
  }

  return { createChart };
}
