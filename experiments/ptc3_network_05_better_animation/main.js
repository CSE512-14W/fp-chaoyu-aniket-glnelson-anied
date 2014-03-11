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

    _.each(nodedata, function(d) {
      d.cx = x_scale(d.x);
      d.cy = y_scale(d.y);
    });

    categories = _.uniq(_.map(nodedata, function(x){ return x.category; }));
    c_scale = d3.scale.category20().domain(categories);
  };

  var ptc3_network = function() {
    init_scales(nodedata);
        
    node = node.data(nodedata)
        .enter()
        .append("circle")
        .attr({
          "class": "node",
          "fill": function(d){ return c_scale(d.category); },
          "r": 3,
          "cx": function(d){ return d.cx; },
          "cy": function(d){ return d.cy; }
        });
  };

  var ptc3_flow = function(){
    console.log("redraw");
    cur = 0;
    ll  = flowdata.length
    function flow(){
      console.log("cur: " + cur);
      
      packet.data(_.filter(flowdata[cur % ll], function(d){ return node.data()[d.source - 1].selected == true }))
            .enter()
            .append("circle")
            .attr("class", '.packet')
            .attr("fill", function(d){ return c_scale(node.data()[d.source -1].category); })
            .style("opacity", 0)
            .attr("r", 1)
            .attr("cx", function(d){ return node.data()[d.source - 1].cx; })
            .attr("cy", function(d){ return node.data()[d.source - 1].cy; })
          .transition()
            .ease('linear')
            .duration(2000)
            .style("opacity", 0.9)
            .attr("r", 2)
            .attr("cx", function(d){ return node.data()[d.target - 1].cx; })
            .attr("cy", function(d){ return node.data()[d.target - 1].cy; })
          .transition()
            .duration(300)
            .style('opacity', 0.1)
            .remove();

      cur++;
    }
    return setInterval(flow, 500);
  }

  var start_brushing = function(){
    var defaultExtent = [[240, 34], [440, 234]],
        x = d3.scale.identity().domain([0, width]),
        y = d3.scale.identity().domain([0, height]);

        //x = d3.scale.identity().domain([margin.left, width - margin.right]),
        //y = d3.scale.identity().domain([margin.top, height - margin.bottom]);
    
    //var quadtree = d3.geom.quadtree()
    //                      .extent([[margin.left, margin.top],
    //                              [width - margin.right, height - margin.bottom]])
    //                      (_.map(nodedata, function(d){ return [d.cx, d.cy] }));

    //var search = function(quadtree, x0, y0, x3, y3) {
    //  //console.log(quadtree);
    //  quadtree.visit(function(node, x1, y1, x2, y2) {
    //    console.log(node);
    //    var p = node.point;
    //    if(p) p.selected = (p.cx >= x0) && (p.cx <x3) && (p.cy >= y0) && (p.cy < y3);
    //    return x1 >= x3 || y1 >= y3 || x2 < x0 || y2 < y0;
    //  });
    //};

    var brushed = function() {
      var extent = brush.extent();
      console.log(extent);
      node.each(function(d) {
        d.selected = (extent[0][0] <= d.cx) && (d.cx < extent[1][0])
                    && (extent[0][1] <= d.cy) && (d.cy < extent[1][1]);
      });
      //node.each(function(d) { d.selected = false; });
      //search(quadtree, extent[0][0], extent[0][1], extent[1][0], extent[1][1]);
      node.classed("selected", function(d){ return d.selected;})
    };

    var flow_id;
    var brushended = function() {
      console.log("brushended");
      //if (!d3.event.sourceEvent) return;
      if (flow_id !== undefined) clearInterval(flow_id);
      flow_id = ptc3_flow();
    };

    var brush = d3.svg.brush()
                  .x(x)
                  .y(y)
                  .extent(defaultExtent)
                  .on("brush", brushed)
                  .on("brushend", brushended);
   
    svg.append("g")
      .attr("class", "brush")
      .call(brush)
      .call(brush.event);
    
    brushended();
  };

  

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
      start_brushing();
    });
  });
})();

