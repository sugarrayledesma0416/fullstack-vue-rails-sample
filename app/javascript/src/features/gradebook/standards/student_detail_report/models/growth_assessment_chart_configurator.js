import { createApp } from 'vue';
import ColumnTooltip from '../components/ColumnTooltip';

const MID_UNIT_COLOR = '#3051ff';
const END_OF_UNIT_COLOR = '#000000';
const MID_BOOK_COLOR = '#9362fb';
const END_OF_BOOK_COLOR = '#8b8b8b';
const LOW_GRADE_THRESHOLD = 60;
const Y_AXIS_TICK_INTERVAL = 20;
const PLOT_HEIGHT = 200;

const MID_BOOK_SERIES_INDEX = 2;
const END_BOOK_SERIES_INDEX = 3;

/**
 * lookup will return `undefined` for Mid-Book and End-of-Book,
 * which is OK because those series won't connect between units.
 */
const DASH_STYLES = {
  'Mid-Unit': 'ShortDash',
  'End-of-Unit': 'Solid',
};

const SERIES_SYMBOLS = {
  'Mid-Unit': 'circle',
  'End-of-Unit': 'circle',
  'Mid-Book': 'circle',
  'End-of-Book': 'circle',
}

function midBookIconElements(x, y) {
  return [
    this.renderer.circle(x, y, 11)
      .attr({fill: this.series[MID_BOOK_SERIES_INDEX].color}),
    this.renderer.circle(x, y, 5)
      .attr({fill: '#ffffff'})
  ];
}

function endBookIconElements(x1, y1, x2, y2) {
  return [
    this.renderer.rect(x1, y1, 22, 22, 4)
      .attr({fill: this.series[END_BOOK_SERIES_INDEX].color}),
    this.renderer.rect(x2, y2, 11, 11, 2)
      .attr({fill: '#ffffff'})
  ];
}

function drawMidBookLegendSymbol(legendGroup, legendItem) {
  midBookIconElements.call(this, legendItem.x + 17, legendItem.y + 15)
    .forEach((element) => element.add(legendGroup));
}

function drawEndBookLegendSymbol(legendGroup, legendItem) {
  endBookIconElements.call(this, legendItem.x + 6, legendItem.y + 4.5, legendItem.x + 11.5, legendItem.y + 10)
    .forEach((element) => element.add(legendGroup));
}

const drawLegendSymbolFunctions = {
  'Mid-Book': drawMidBookLegendSymbol,
  'End-of-Book': drawEndBookLegendSymbol,
};

function drawMidBookPlotMarker(markerGroup, point) {
  midBookIconElements.call(this, point.plotX, point.plotY)
    .forEach((element) => element.add(markerGroup));
}

function drawEndBookPlotMarker(markerGroup, point) {
  endBookIconElements.call(this, point.plotX - 11, point.plotY - 11, point.plotX - 5.5, point.plotY - 5.5)
    .forEach((element) => element.add(markerGroup));
}

const drawPlotMarkerFunctions = {
  'Mid-Book': drawMidBookPlotMarker,
  'End-of-Book': drawEndBookPlotMarker,
};

function changeLegendSymbol(seriesIndex, seriesName) {
  const legendItem = this.legend.allItems[seriesIndex].legendItem;
  legendItem.symbol.element.remove();

  this.legend.group.element.querySelectorAll(`.${seriesName}-legend-group`).forEach((node) => node.remove());
  this.legend.group.element.querySelector(`.highcharts-series-${seriesIndex} .highcharts-graph`).setAttribute('stroke-width', 0);

  const legendGroup = this.renderer.g().attr({ class: `${seriesName}-legend-group` });

  /**
   * Call the appropriate function to draw the symbol,
   * passing it the legend group and the legend item
   */
  drawLegendSymbolFunctions[seriesName].call(this, legendGroup, legendItem);

  legendGroup.add(this.legend.group);
}

function changePlotMarker(seriesIndex, seriesName) {
  this.series[seriesIndex].points.forEach((point) => {
    if(!(point.graphic)) { return; }

    // hide the marker in the plot
    point.graphic.hide();

    // remove any custom marker already in the DOM for this point
    point.graphic.parentGroup.element.querySelectorAll(`.${seriesName}-marker-group`).forEach((node) => node.remove());

    // draw a custom marker
    const markerGroup = this.renderer.g().attr({ class: `${seriesName}-marker-group` });

    /**
     * Call the appropriate function to draw the marker,
     * passing it the marker group and the point
     */
    drawPlotMarkerFunctions[seriesName].call(this, markerGroup, point);

    markerGroup.add(point.graphic.parentGroup);
  });
}

function changeMarkersAndSymbols() {
  // Hide the default circle markers for Mid-Unit and End-of-Unit
  document.querySelector('.highcharts-legend-item.highcharts-series-0 .highcharts-point').setAttribute('opacity', 0);
  document.querySelector('.highcharts-legend-item.highcharts-series-1 .highcharts-point').setAttribute('opacity', 0);

  // Mid-Unit: Widen the line in the legend and change the dash style
  document.querySelector('.highcharts-legend-item.highcharts-series-0 .highcharts-graph').setAttribute('stroke-width', 6);
  document.querySelector('.highcharts-legend-item.highcharts-series-0 .highcharts-graph').setAttribute('stroke-dasharray', '9,5');

  // End-of-Unit: Widen the line in the legend
  document.querySelector('.highcharts-legend-item.highcharts-series-1 .highcharts-graph').setAttribute('stroke-width', 9);

  // Mid-Book:
  changeLegendSymbol.call(this, MID_BOOK_SERIES_INDEX, 'Mid-Book');
  changePlotMarker.call(this, MID_BOOK_SERIES_INDEX, 'Mid-Book');

  // End-of-Book:
  changeLegendSymbol.call(this, END_BOOK_SERIES_INDEX, 'End-of-Book');
  changePlotMarker.call(this, END_BOOK_SERIES_INDEX, 'End-of-Book');
}

function getUnitLabelText(unit) {
  return unit.label || unit.name.split(' |')[0];
}

function setActiveStatus(objectLabel, unitName) {
  Object.values(objectLabel).forEach(element => {
    if (element.label.textStr === unitName) {
      element.label.element.classList.add('is-active');
    } else {
      element.label.element.classList.remove('is-active');
    }
  });
}

function addNoScoreStyle(seriesData) {
  // Get all span tag that shows the unit label in the Chart's xAxis.
  const unitLabels = document.querySelectorAll('div.highcharts-xaxis-labels.unit-labels-container span');
  unitLabels.forEach((label, index) => {
    if (seriesData[index].isNull) {
      label.style.cursor = 'not-allowed';
      label.classList.add('unit-label-none-score');
    }
  });
}

export function consolidateSeriesData(seriesData) {
 let consolidatedData = [];

  for (let i = 0; i < seriesData[0].length; i++) {
    // Initializes the unit with the first value of the corresponding series
    let unitData = seriesData[0][i];

    // Replaces the null value with non-null values from the other series
    for (let j = 1; j < seriesData.length; j++) {
      if (!unitData || unitData.isNull) {
        unitData = seriesData[j][i];
      }
    }

    consolidatedData.push(unitData);
  }

  return consolidatedData;
}

export default class GrowthAssessmentChartConfigurator {
  static #pageFontFamily() {
    const computedStyle = getComputedStyle(document.querySelector('html'));
    return computedStyle.getPropertyValue('font-family');
  }

  static #baseConfig() {
    return {
      title: {
        text: 'Overall Performance Growth on Assessment',
        align: 'center',
        style: {
          fontWeight: '700',
        },
      },

      chart: {
        events: {
          render() {
            document.querySelector('.highcharts-title').style.fontSize = '1.3rem';
            document.querySelector('.highcharts-title').style.letterSpacing = '0.1rem';

            changeMarkersAndSymbols.call(this);

            // Highcharts storage series data on this place.
            const seriesData = this.series.map(series => series.data);
            addNoScoreStyle(consolidateSeriesData(seriesData));
          },
        },
        marginLeft: 100,
        marginTop: 100,
        spacingLeft: 35,
        spacingTop: 38,
        style: {
          fontFamily: this.#pageFontFamily(),
        },
      },

      colors: [
        MID_UNIT_COLOR,
        END_OF_UNIT_COLOR,
        MID_BOOK_COLOR,
        END_OF_BOOK_COLOR,
      ],

      credits: { enabled: false },

      plotOptions: {
        line: {
          marker: { enabled: true },
        },
        series: {
          stickyTracking: false,
          events: {
            mouseOut: function() {
              this.chart.tooltip.hide();
            },
          },
        },
      },

      tooltip: {
        backgroundColor: '#fff',
        borderColor: '#666666',
        borderWidth: '0.5px',
        positioner: function (labelWidth, labelHeight, point) {
          return { x: Math.max(point.plotX - 75, 3), y: this.chart.plotHeight/2.0 };
        },
        shape: 'sharedCallout',
        shared: true,
        snap: 2,
        style : {
          width: '130px',
          height: '186px',
        },
        useHTML: true,
      },

      xAxis: {
        height: PLOT_HEIGHT,
        categories: null,
        className: 'unit-labels-container',
        crosshair: {
          width: 2,
          color: '#666666',
          dashStyle: 'dash',
        },
        gridLineWidth: 1,
        labels: {
          align: 'center',
          style: {
            color: '#333333',
            fontSize: '16px',
            cursor: 'pointer',
            padding: '5px 10px',
          },
          useHTML: true,
        },
        tickmarkPlacement: 'on',
      },

      yAxis: {
        height: PLOT_HEIGHT,
        labels: {
          distance: 30,
          style: {
            color: '#707070',
            fontSize: '16px',
            cursor: 'pointer',
          },
        },
        left: 100,
        min: 0,
        max: 100,
        plotBands: [{
          className: 'low-grade-threshold-band',
          color: '#f5e7e7',
          from: 0,
          to: LOW_GRADE_THRESHOLD,
        }],
        plotLines: [{
          color: '#ea3e3e',
          width: 0.25,
          value: 60,
          zIndex: 3,
        }],
        tickInterval: Y_AXIS_TICK_INTERVAL,
        title: {
          enabled: false,
        },
      },

      legend: {
        align: 'left',
        className: 'growth-chart-legend',
        itemStyle: {
          fontSize: '1.0rem',
          color: '#666666',
        },
        labelFormat: '{name}',
        symbolPadding: 12,
        symbolWidth: 23,
        verticalAlign: 'bottom',
        x: 58,
        y: -15,
      },

      series: null,
    };
  }

  static #transformSeriesData(seriesData) {
    const entries = Object.entries(seriesData);
    return entries.map((entry) => {
      return {
        name: entry[0],
        data: entry[1],
        dashStyle: DASH_STYLES[entry[0]],
        marker: {
          radius: 5,
          symbol: SERIES_SYMBOLS[entry[0]],
        },
      };
    });
  }

  static createHighchartsConfig(chartConfig, emit) {
    const config = this.#baseConfig();

    config.tooltip.formatter = function() {
      const div = document.createElement('div');

      createApp(ColumnTooltip, {
        points: this.points,
        lowGradeThreshold: LOW_GRADE_THRESHOLD,
        hasMidBookAssessment: this.point.category === chartConfig.mid_book_unit_name,
        hasEndBookAssessment: this.point.category === chartConfig.end_book_unit_name,
      }).mount(div);

      return div.innerHTML;
    };

    config.xAxis.categories = chartConfig.units.map((unit) => getUnitLabelText(unit));

    /**
     * Create a lookup table for unit IDs, with unit name as the key.
     */
    const unitIdLookup = chartConfig.units.reduce((acc, unit) => {
      acc[getUnitLabelText(unit)] = unit.id;
      return acc;
    }, {});

    config.xAxis.plotBands = config.xAxis.categories.map((category, index) => {
      const hasData = this.#transformSeriesData(chartConfig.assessments_by_series).some(series => 
        series.data[index] && !series.data[index].isNull
      );

      if (hasData) {
        return {
          from: index - 0.25,
          to: index + 0.25,
          color: '#00000000',
          zIndex: 1,
          events: {
            mouseover: function() {
              this.svgElem.attr({
                cursor: 'pointer',
                fill: '#f9f9f9',
              });
            },
            mouseout: function() {
              this.svgElem.attr({
                fill: '#00000000',
              });
            },
            click: function() {
              setActiveStatus(this.axis.ticks, category);
              emit('unitClicked', { id: unitIdLookup[category], name: category });
            },
          },
        };
      }

      return null;
    }).filter(band => band !== null);

    /**
     * Emit a 'unitClicked' event when a unit label is clicked.
     * Pass the unit ID to the event handler.
     */
    config.xAxis.labels.events = {
      click: function() {
        if (![...this.axis.ticks[this.pos].label.element.classList].includes('unit-label-none-score')) {
          setActiveStatus(this.axis.ticks, this.value);
          emit('unitClicked', { id: unitIdLookup[this.value], name: this.value }); 
        }
      }
    };
    config.series = this.#transformSeriesData(chartConfig.assessments_by_series);
    return config;
  }
}
