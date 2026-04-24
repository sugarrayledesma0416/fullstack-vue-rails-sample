
// Render multiple donut charts on a page
// - Non-AngularJS version.

VHL = VHL || {};

VHL.DataVisuals = (function() {
  function render_donut(el) {
    var $el,val,label,diameter,rp1,width;
    $el = $(el);
    val = parseInt($el.attr('data-value'));
    width = parseInt($el.attr('data-diameter')) || 300;
    rp1 = radialProgress(el)
      .diameter(width)
      .value(val)
      .render();
  }

  function render_pie(el) {
    var $el = $(el);
    var w = "300";
    var h = "300";
    var r = ($el.innerWidth() / 2);
    var data = [
      {
        "label": " ",
        "value": parseInt($el.attr('data-value'))
      },{
        "label": " ",
        "value": parseInt($el.attr('data-value2'))
      }
    ];
    var vis = d3.select(el)
      .data([data])
      .append('svg:g')
      .attr('width', w)
      .attr('height', h)
      .attr("transform", "translate(" + r + "," + r + ")");
    var arc = d3.svg.arc().outerRadius(r);

    var pie = d3.layout.pie()
      .value(function(d) {
        return d.value;
      });

    var arcs = vis.selectAll("g.slice")
      .data(pie)
      .enter()
      .append("svg:g")
      .attr("class", "slice");

    arcs.append("svg:path")
      .attr("d", arc);

    arcs.append("svg:text")
      .attr("transform", function(d) {
        d.innerRadius = 0;
        d.outerRadius = r;
        return "translate(" + arc.centroid(d) + ")";
      })
      .attr("text-anchor", "middle")
      .text(function(d, i) {
        return data[i].label;
      });

    $(document.createElement('div'))
      .addClass('c-pie-chart__outer-label')
      .text(data[0].value + '%')
      .appendTo($el.parent());

  }

  function init(){
    $('.js-d3-radial-inner').each(function(index,item) {
      render_donut(item);
    });

    $('.js-pie-chart').each(function(index,item) {
      render_pie(item);
    });
  }
  return {
    init: init
  };
})();

$(document).ready(function() {
  VHL.DataVisuals.init();
});
