(function(){
  var ptc3_network = function(dataset){
    var margin = {top: 20, right: 20, bottom: 20, left: 20},
        width = 1000,
        height = 600;

    var svg = d3.select("body")
                .append("svg")
                .attr("width", width)
                .attr("height", height);

    var node = svg.selectAll(".node");

    var x_range = [d3.min(dataset, function(d){ return d.x; }),
                   d3.max(dataset, function(d){ return d.x; })];

    var y_range = [d3.min(dataset, function(d){ return d.y; }),
                   d3.max(dataset, function(d){ return d.y; })];

    var x_scale = d3.scale.linear()
                    .domain(x_range)
                    .range([0 + margin.left, width - margin.left])
                    .nice();

    var y_scale = d3.scale.linear()
                    .domain(y_range)
                    .range([0 + margin.top, height - margin.bottom])
                    .nice();

    node.data(dataset)
        .enter()
        .append("circle")
        .attr({
          "class": "node",
          "r": 5,
          "cx": function(d){ return x_scale(d.x)},
          "cy": function(d){ return y_scale(d.y)}
        });
  }


  d3.csv("../data/PTC3_V.csv", function(data){
    dataset = data.map(function(d) {
      return {
        label: d.label,
        x: +d.xcoord,
        y: +d.ycoord,
        z: +d.zcoord,
        area: d.area,
        plot: d.plot
      }
    });
    ptc3_network(dataset);
  });
})();

