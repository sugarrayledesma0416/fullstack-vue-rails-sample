/**
 * returns the maximum domain for the input data.
 * @param {number} maxWorkHours - max working hours.
 * @return {number}
 */
function createDomain(maxWorkHours) {
  const interval = 5;
  return interval * Math.ceil(maxWorkHours / interval);
}

/**
 * @typeDef {WorkLoadObject}
 * @type {Object}
 * @property {number} activityCount - count of activities.
 * @property {number} avg - average working hours.
 * @property {number} max - max working hours.
 * @property {number} min - min working hours.
 */

/**
 * creates a svg graph representing work load.
 * @param {Element} elm - html div element on which work
 * load graph is mounted.
 * @param {WorkLoadObject} workLoad - represents workload.
 */
function drawGraph(elm, workLoad) {
  const oldSvg = elm.querySelector('svg');
  if (oldSvg) {
    oldSvg.remove();
  }

  const avgWorkHours = Math.round(workLoad.avg / 60 * 100)/100;
  const maxWorkHours = Math.round(workLoad.max / 60 * 100)/100;

  const scaleDomain = [0, createDomain(maxWorkHours)];
  const scaleRange = [0, 700];
  const svgWidth = 730;
  const svgHeight = 65;
  const svgBottomPadding = 10;
  const svgTextColor = '#565656';

  const rangeBarSpecs = {
    color: '#1B3D6B',
    height: '15',
    yPos: function() {
      return svgHeight - svgBottomPadding - rangeBarSpecs.height;
    },
  };

  const avgMarkSpecs = {
    xPos: -53,
    yPos: -7,
    textColor: svgTextColor,
    text: 'Average hours per due date',
    fontFamily: 'Tahoma',
    fontSize: 11,
  };

  const hoursLabelSpecs = {
    fontFamily: 'Tahoma',
    fontSize: '9px',
    xPos: 5,
    yPos: 55,
  };

  const arrowSpecs = {
    fill: '#BFBFBF',
    arrowheadPoints: '17.561,10.063 17.561,0 9.561,0 9.561,' +
      '10.063 0,7.559 13.531,32.666 27.081,7.559',
    arrowhead_y: 10,
    xOffset: 15,
  };

  const svg = d3.select(elm).append('svg').attr('width', svgWidth).attr('height', svgHeight);
  const xScale = d3.scale.linear().domain(scaleDomain).range(scaleRange);

  const translateXAmt = () => {
    return xScale(avgWorkHours) - arrowSpecs.xOffset;
  };

  svg.append('text')
    .text('hours')
    .attr('x', hoursLabelSpecs.xPos)
    .attr('y', hoursLabelSpecs.yPos)
    .attr('font-family', hoursLabelSpecs.fontFamily)
    .attr('font-size', hoursLabelSpecs.fontSize);

  const group = svg.append('g')
    .attr('transform', 'translate('+ translateXAmt() +',20)');

  group.append('polygon')
    .attr('points', arrowSpecs.arrowheadPoints)
    .attr('fill', arrowSpecs.fill);

  group.append('text')
    .text(avgMarkSpecs.text)
    .attr('fill', avgMarkSpecs.textColor)
    .attr('x', avgMarkSpecs.xPos)
    .attr('y', avgMarkSpecs.yPos)
    .attr('font-family', avgMarkSpecs.fontFamily)
    .attr('font-size', avgMarkSpecs.fontSize);

  const xAxis = d3.svg.axis()
    .scale(xScale)
    .ticks(createDomain(maxWorkHours))
    .orient('top');

  svg.append('g')
    .attr('class', 'cw-axis')
    .attr('transform', 'translate(0,60)')
    .call(xAxis);
}

export default {
  mounted(elm, binding) {
    drawGraph(elm, binding.value);
  },
};
