(function(){
  var margin = {top: 20, right: 20, bottom: 20, left: 20},
      width = 1280,
      height = 700;

  var svg = d3.select("body")
                .append("svg")
                .attr("width", width)
                .attr("height", height);

  var node = svg.selectAll(".node");
  var packet = svg.selectAll(".packet");

  var nodedata, flowdata = [];
  var x_range, y_range, x_scale, y_scale, c_scale;

  var init_scales = function(nodedata) {
    _.each(nodedata, function(d){ 
      d.category = d.label.slice(0, d.label.indexOf("_"));
    });

    x_range = [d3.min(nodedata, function(d){ return d.x; }),
                   d3.max(nodedata, function(d){ return d.x; })];

    y_range = [d3.min(nodedata, function(d){ return d.y; }),
                   d3.max(nodedata, function(d){ return d.y; })];

    x_scale = d3.scale.linear()
                    .domain(x_range)
                    .range([0 + margin.left, width - margin.left])
                    .nice();

    y_scale = d3.scale.linear()
                    .domain(y_range)
                    .range([0 + margin.top, height - margin.bottom])
                    .nice();

    categories = _.uniq(_.map(nodedata, function(x){ return x.category; }));
    c_scale = d3.scale.category20().domain(categories);
  };

  var ptc3_network = function() {
    init_scales(nodedata);
        
    // varibles for brushing
    //var defaultExtent = [[100, 100], [300, 300]],
    //    x = d3.scale.identity().domain([margin.left, width - margin.right]),
    //    y = d3.scale.identity().domain([margin.top, height - margin.bottom]);

    //var brush = d3.svg.brush()
    //              .x(x)
    //              .y(y)
    //              .extent(defaultExtent);

    node = node.data(nodedata)
        .enter()
        .append("circle")
        .attr({
          "class": "node",
          "fill": function(d){ return c_scale(d.category); },
          "r": 3,
          "cx": function(d){ return x_scale(d.x); },
          "cy": function(d){ return y_scale(d.y); }
        });
  };

  var ptc3_flow = function(){
    cur = 0;
    ll  = flowdata.length
    function flow(){
      console.log("cur: " + cur);

      packet.data(flowdata[cur % ll])
            .enter()
            .append("circle")
            .attr("class", '.packet')
            .attr("fill", function(d){ return c_scale(node.data()[d.source -1].category); })
            .attr("r", 2)
            .attr("cx", function(d){ return x_scale(node.data()[d.source - 1].x); })
            .attr("cy", function(d){ return y_scale(node.data()[d.source - 1].y); })
          .transition()
            .duration(6000)
            .attr("cx", function(d){ return x_scale(node.data()[d.target - 1].x); })
            .attr("cy", function(d){ return y_scale(node.data()[d.target - 1].y); })
            .remove();

      cur++;
    }
    setInterval(flow, 1000);
    //brush.on("brush", brushed)
    //     .on("brushend", brushended);
  }

  //var brushed = function() {

  //};

  //var brushended = function() {

  //};

  d3.csv("../../data/PTC3_V.csv", function(data) {
    nodedata = data.map(function(d) {
      return {
        label: d.label,
        x: +d.xcoord,
        y: +d.ycoord,
        z: +d.zcoord,
        area: d.area,
        plot: d.plot
      };
    });
    ptc3_network();

    d3.csv("../../data/F_PTC3_words_LD_E.csv", function(data) {
      var previous_timeslot;

      _.each(data, function(d) {
        if(d.t == previous_timeslot) {
          flowdata[flowdata.length-1].push({"source": +d.src, "target": +d.snk})
        } else {
          previous_timeslot = d.t;
          flowdata.push([{"source": +d.src, "target": +d.snk}]);
        }
      });

      console.log(flowdata);
      // call start
      ptc3_flow()
    });
  });
})();

