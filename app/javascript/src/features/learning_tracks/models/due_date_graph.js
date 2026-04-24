import { dispatchCustomEvent, unique } from 'shared/utils';
import { nextTick } from 'vue';
import * as ActivityDistributor from '../models/activity_distributor';

/**
 * @typedef {
 *  import('features/assignment_wizard/models/assignment_calendar.js').DueDate
 * } DueDate
 */

/**
 * @typeDef {GroupInfoData}
 * @property {string} name - name of strand.
 * @property {string} lesson - name of lesson.
 * @property {number} totalMinutes - total minutes.
 * @property {Array} groups - array of assignment groups.
 */

/**
  * @typeDef {LocalstoreObject}
  * @property {DueDate} dueDate - due date for the assignments.
  * @property {Array} groups - array of assignment groups.
  * @property {WorkLoadObject} workLoad - represents workload.
  * @property {string} unitLabel - label for the unit.
  */

/**
  * @typeDef {RangeBarSpec}
  * @property {string} fill - fill attribute for rect element.
  * @property {string} separatorFill - fill attribute for second rect element.
  * @property {string} height - height of for rect element.
  * @property {string} yPos - y position of for rect element.
  * @property {string} spacerWidth - width of for rect element.
  */

/**
  * @typeDef {GraphParamObject}
  * @property {RangeBarSpec} rangeBarSpecs - range bar graph parameters.
  * @property {Array} strandGroups - array of strands.
  * @property {Element} svg - due date graph svg element.
  * @property {string} unitLabel - label for the unit.
  * @property {Function} xScale - function that maps input domain to
  * output range.
  */

/**
  * @typedef {
  *  import('features/learning_tracks/directives/work_load_graph.js').WorkLoadObject
  * } WorkLoadObject
  */

/** Class for Due Date Graph model. */
class DueDateGraph {
  /**
   * Set up the configutation required for initializing
   * DueDateGraph.
   * @constructor
   * @param {Element} graphElm - Vue reactive element on which due date
   * load graph is mounted.
   * @param {Element} groupInfoElm - Vue reactive ref element on which assignment group info
   * is shown.
   * @param {LocalstoreObject} localstore - Vue reactive object to store
   * DueDateGraph component state.
   */
  constructor(graphElm, groupInfoElm, localstore) {
    this.store = localstore;
    this.graphElm = graphElm;
    this.groupInfoElm = groupInfoElm;
  }

  /**
   * creates a svg graph representing assignment distribution for a dueDate.
   */
  drawGraph() {
    const graphParams = {};

    graphParams.strandGroups = ActivityDistributor.groupByStrand(this.store.groups);
    const maxWorkHours = Math.round(this.store.workLoad.max / 60 * 100)/100;

    graphParams.scaleDomain = [0, this.createDomain(maxWorkHours)];
    graphParams.scaleRange = [0, 700];
    graphParams.svgWidth = 770;
    graphParams.svgHeight = 15;
    graphParams.svgTextColor = '#737373';

    graphParams.rangeBarSpecs = {
      fill: '#2a7ab0',
      separatorFill: '#FFFFFF',
      height: '15',
      yPos: 0,
      spacerWidth: 2,
    };

    graphParams.svg = d3
      .select(this.graphElm.value)
      .append('svg').attr('width', graphParams.svgWidth)
      .attr('height', graphParams.svgHeight);

    graphParams.xScale = d3.scale.linear().domain(graphParams.scaleDomain).range(
      graphParams.scaleRange
    );
    graphParams.unitLabel = this.store.unitLabel;
    const group = this.createGroupElement(graphParams);
    this.addGroupElmEventListeners(group);
  }

  /**
   * @private
   * adds a unit label text at the end of graph bar element.
   * @param {Element} bar - graph bar element.
   * @param {GraphParamObject} graphParams - graph parameters.
   */
  addLabelToBarElm(bar, graphParams) {
    bar.append('text')
      .text(function(data, i) {
        if (i === graphParams.strandGroups.length - 1 ) {
          const minutes = graphParams.strandGroups.reduce((memo, strandGroup) => {
            return strandGroup.totalMinutes + memo;
          }, 0);

          const lessonLabels = graphParams.strandGroups.map((strandGroup) => {
            const match = strandGroup.lesson.match(/(?:\S+ ){1}(\S+)/);
            return match ? match[1]: ' ';
          });

          const lessonLabel = unique(lessonLabels).join(', ');

          return (minutes/60).toFixed(1) + ' hrs; ' + graphParams.unitLabel + ' ' + lessonLabel;
        }
        return null;
      })
      .attr('x', this.xAccumulator(graphParams.xScale, true, 5))
      .attr('y', graphParams.rangeBarSpecs.yPos)
      .attr('dy', '12px')
      .attr('class', 'date-end-label')
      .attr('fill', graphParams.svgTextColor);
  }

  /**
   * @private
   * add on hover and click listener for the graph group element.
   * @param {Element} group - due date graph 'g' element.
   * @param {DueDate} dueDate - due date.
   */
  addGroupElmEventListeners(group) {
    const self = this;
    group.on('mouseover', function(data) {
      const rect = this.querySelector('rect');
      self.showGroupInfo(data, rect);
    });

    group.on('mouseout', () => {
      this.store.showGroupInfoElm = false;
    });

    group.on('click', (eventData, strandPosition) => {
      this.triggerOpenGroupMenu(strandPosition);
    });
  }

  /**
   * @private
   * returns the maximum domain for the input data.
   * @param {number} maxWorkHours - max working hours.
   * @return {number}
   */
  createDomain(maxWorkHours) {
    const interval = 5;
    return interval * Math.ceil(maxWorkHours / interval);
  }

  /**
   * @private
   * create and returns a 'g' (group) element in due date svg graph.
   * @param {GraphParamObject} graphParams - graph parameters.
   * @return {Element}
   */
  createGroupElement(graphParams) {
    const bar = graphParams.svg.selectAll('rect')
      .data(graphParams.strandGroups)
      .enter();
    const group = bar.append('g');

    group.append('rect')
      .attr('height', graphParams.rangeBarSpecs.height)
      .attr('width', function(d) {
        return graphParams.xScale(d.totalMinutes / 60);
      })
      .attr('x', this.xAccumulator(graphParams.xScale))
      .attr('fill', graphParams.rangeBarSpecs.fill)
      .attr('y', graphParams.rangeBarSpecs.yPos);

    group.append('rect')
      .attr('height', graphParams.rangeBarSpecs.height)
      .attr('width', graphParams.rangeBarSpecs.spacerWidth)
      .attr('x', this.xAccumulator(graphParams.xScale))
      .attr('fill', graphParams.rangeBarSpecs.separatorFill)
      .attr('y', graphParams.rangeBarSpecs.yPos);

    this.addLabelToBarElm(bar, graphParams);
    return group;
  }

  /**
   * @private
   * round off total hour to one decimal point.
   * @param {number} totalMinutes - total minutes.
   * @return {number}
   */
  roundedHour(totalMinutes) {
    return (totalMinutes/60).toFixed(1);
  }

  /**
   * @private
   * calculates the x-offset of the given rect or text node.
   * @param {Function} xScale - function that maps input domain to
   * output range.
   * @param {boolean} label - whether label is to be shown or not.
   * @param {number} labelOffset - label offset.
   * @return {Function}
   */
  xAccumulator(xScale, label, labelOffset) {
    let counter = 0;

    return function(d) {
      const oldCounter = counter;
      counter += xScale(d.totalMinutes / 60);
      if (label) {
        // if positioning label, advance to furthest point
        // plus padding.
        return counter + labelOffset;
      }
      return oldCounter;
    };
  }

  /**
   * @private
   * calculates the x-offset of the group info tooltip.
   * @param {Element} rect - rect element of the due date graph.
   * @return {number}
   */
  xOffset(rect) {
    let x = parseInt(rect.getAttribute('x'), 10);

    const groupInfoWidth = this.groupInfoElm.value.offsetWidth;
    const rectWidth = parseInt(rect.getAttribute('width'), 10);
    // Centers popup above rectangle.
    if (groupInfoWidth > rectWidth) {
      x -= parseInt((groupInfoWidth - rectWidth) / 2, 10);
    }

    // The math above is correct, but it still looks slightly right aligned.
    // This also covers cases where the rect and groupInfo are the same width.
    x -= 8;

    return x;
  }

  /**
   * @private
   * show group info tool tip with the group info data.
   * @param {GroupInfoData} data - data to be shown in the tooltip.
   * @param {Element} rect - rect element of the group on which mouse is hovered.
   */
  async showGroupInfo(data, rect) {
    this.store.groupInfoData.strandHeading =
      data.name[0].toUpperCase() + data.name.slice(1) + ' : ' + data.lesson;

    this.store.groupInfoData.activityCount = data.groups.reduce((memo, group) => {
      return memo + group.activities.length;
    }, 0);

    this.store.groupInfoData.totalMinutes = this.roundedHour(data.totalMinutes);
    this.store.showGroupInfoElm = true;
    await nextTick();
    this.groupInfoElm.value.style.marginLeft = this.xOffset(rect) + 'px';
    this.groupInfoElm.value.style.marginTop = - (this.groupInfoElm.value.offsetHeight + 10) + 'px';
  }

  /**
   * @private
   * Raise 'openGroupMenu' event if due date is not locked
   * and pass due date and strand position in payload
   * @param {number} strandPosition
   */
  triggerOpenGroupMenu(strandPosition) {
    if (!this.store.dueDate.locked) {
      dispatchCustomEvent({
        name: 'openGroupMenu',
        detail: {
          date: this.store.dueDate,
          position: strandPosition,
        },
      });
    }
  }
}

export default DueDateGraph;
