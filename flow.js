var flow = function(){
  var margin = {top: 40, right: 40, bottom: 40, left: 40},
      width = 600,
      height = 600;

  var svg = d3.select("#graph")
              .append("svg")
              .attr("width", width)
              .attr("height", height);
                //.attr("class", 'graph-svg')

  var node = svg.selectAll(".node");
  var labels = svg.selectAll(".label");
  var packet = svg.selectAll(".packet");

  // flowdata is [[src, target], ...], next timestep, ...]
  var x_range, y_range, x_scale, y_scale, c_scale;

  
  var init_scales = function() {

    _.each(nodedata, function(d){ 
      d.category = d.label.slice(0, d.label.indexOf("_"));
    });

    categories = _.uniq(_.map(nodedata, function(x){ return x.category; }));

    _.each(nodedata, function(d){
      d.r = _.filter(nodedata, function(x){ return x.category == d.category;}).length;
    });

    c_scale = d3.scale.category20().domain(categories);

    circle_layout();

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

      // coords for label
      d.lx = x_scale(d.x * 1.2);
      d.ly = y_scale(d.y * 1.2);
    });
  };

  var circle_layout = function() {
    //nodedata = _.sortBy(nodedata, function(node){ return node.category });
    var index = 0,
        interval = Math.PI * 2 / categories.length;

    var coords = {};
    _.each(categories, function(c) {
      var x = Math.sin(interval * index);
      var y = Math.cos(interval * index++);
      coords[c] = [x, y];
    })
    
    nodedata =_.map(nodedata, function(node){
      node.x = coords[node.category][0];
      node.y = coords[node.category][1];
      return node;
    });
  };

  // draw the initial nodes
  var draw_ptc3_nodes = function() {
    var drag = d3.behavior.drag()
                  .origin(function(d) { return d; })
                  .on("dragstart", dragstarted)
                  .on("drag", dragged)
                  .on("dragend", dragended);

    var ox, oy;
    function dragstarted(d) {
      d3.event.sourceEvent.stopPropagation();
      //d3.select(this).classed("dragging", true);
      ox = d.cx;
      oy = d.cy;
    }

    function dragged(d) {
      var category = d.category;
      var cx = ox + d3.event.x;
      var cy = oy + d3.event.y;
      console.log(category);

      _.each(node[0], function(dd){
        if (dd.__data__.category == category) {
          d3.select(dd).attr("cx", dd.__data__.cx = cx ).attr("cy", dd.__data__.cy = cy);
        }
      });

      _.each(labels[0], function(dd){
        if (dd.__data__.category == category) {
          d3.select(dd).attr("x",  cx - dd.__data__.category.length * 2.8)
                        .attr("y",  cy + 4);
        }
      });
    }

    function dragended(d) {
      //d3.select(this).classed("dragging", false);
    }

    gnodes = node.data(nodedata)
        .enter()
        .append("g")

    node = gnodes.append("circle")
          .attr({
            "class": function(d){ return "node " + d.category; },
            "fill": function(d){ return c_scale(d.category); },
            "r": 20,
            "cx": function(d){ return d.cx; },
            "cy": function(d){ return d.cy; }
          })
        .call(add_tooltip)
        .call(drag);
        //.call(toggle_select);

    labels = gnodes.append("text")
          .text(function(d){ return d.category;})
          .attr({
            "x": function(d){ return d.cx - d.category.length*2.8; },
            "y": function(d){ return d.cy + 4; },
            "font-size": '10px',
            "font-family": 'sans-serif'
          })
  };

  //function toggle_select(selection){
  //  selection.on('click', function (d) {
  //    category = d.category;
  //    d.selected = d.selected ? false : true;
      
  //    var selected = d.selected;
  //    _.each(node, function(dd){
  //      if (dd.category == category) {
  //        dd.selected = selected
  //      }
  //    });

  //    selection.classed("selected", function(d){ return d.selected;})
  //  });
  //}

  // Animation parameters
  var animation_duration = 8000;
  var duration = 7;
  var time_interval = animation_duration / duration;

  /* 
   * Cut a line by ratio
   * 
   * start     cut            end
   *  o--------o---------------o
   *
   * ratio = dist(start, cut) / dist(start, end)
   * return [cut.x, cut.y]
   * */
  var slice_line = function(ratio, starting_point, ending_point) {
    if(ratio < 0 || ratio > 1) return;
    var delta = ending_point - starting_point;
    return starting_point + (ratio * delta);
  }

  var ptc3_flow = function(){
    console.log("redraw");
    var cur = current_time_step;
    var ll  = flowdata.length;

    function flow(){
      if(cur >= ll){ cur = 0; current_time_step = 0;}
      console.log("cur: " + cur);
      selected = _.filter(flowdata[cur % ll], function(d){ return nodedata[d.source].selected == true });
      
      //

      plotMatrix.draw(cur, duration);

      //  

      var cutting_ratio = 1.0 / (duration - 1); // 0.2
      var draw_tail_duration = animation_duration / (duration - 1); // 500
      var flow_duration = animation_duration - draw_tail_duration; // 2000

      // TODO refactor to include and offset on xsrc, xdest, ysrc, ydest
      //      and intensity / color / style of the line
      // to draw reference or other lines for comparison
      // 	do this by finding orthogonal direction to line
      // 	then offset by small amount in pos or neg direction
      //
      // TODO see what looks like without growing dots, and/or put spaces in there instead 
      // TODO BUG line trails don't change length with duration change
      packet.data(selected)
            .enter()
            .append("line")
            .style("stroke", function(d){ return c_scale(nodedata[d.source].category); })
            .attr({
              x1: function(d){ return nodedata[d.source].cx; },
              y1: function(d){ return nodedata[d.source].cy; }
            })
            .attr({
              x2: function(d){ return nodedata[d.source].cx; },
              y2: function(d){ return nodedata[d.source].cy; }
            })
            .style("opacity", 0)
            .attr("stroke-width", 1)
          .transition()
            .ease('linear')
            .duration(draw_tail_duration)
            .attr({
              x1: function(d){ return nodedata[d.source].cx; },
              y1: function(d){ return nodedata[d.source].cy; }
            })
            .attr({
              x2: function(d){ 
                return slice_line(cutting_ratio, nodedata[d.source].cx, nodedata[d.target].cx);
              },
              y2: function(d){ 
                return slice_line(cutting_ratio, nodedata[d.source].cy, nodedata[d.target].cy);
              }
            })
            .style("opacity", 0.1)
            .attr("stroke-width", 3)
          .transition()
            .ease('linear')
            .duration(flow_duration)
            .attr({
              x1: function(d){ 
                return slice_line(1 - cutting_ratio, nodedata[d.source].cx, nodedata[d.target].cx);
              },
              y1: function(d){ 
                return slice_line(1 - cutting_ratio, nodedata[d.source].cy, nodedata[d.target].cy);
              }
            })
            .attr({
              x2: function(d){ return nodedata[d.target].cx; },
              y2: function(d){ return nodedata[d.target].cy; }
            })
            .style("opacity", 0.6)
          .transition()
            .ease('linear')
            .duration(draw_tail_duration)
            .attr({
              x1: function(d){ return nodedata[d.target].cx; },
              y1: function(d){ return nodedata[d.target].cy; }
            })
            .attr({
              x2: function(d){ return nodedata[d.target].cx; },
              y2: function(d){ return nodedata[d.target].cy; }
            })
            .style("opacity", 0.1)
            .attr("stroke-width", 0.5)
            .remove();

      packet.data(selected)
            .enter()
            .append("circle")
            .attr("class", '.packet')
            .attr("fill", function(d){ return c_scale(nodedata[d.source].category); })
            .style("opacity", 0)
            .attr("r", 0.5)
            .attr("cx", function(d){ return nodedata[d.source].cx; })
            .attr("cy", function(d){ return nodedata[d.source].cy; })
          .transition()
            .ease('linear')
            .duration(animation_duration)
            .style("opacity", 0.9)
            .attr("r", 3)
            .attr("cx", function(d){ return nodedata[d.target].cx; })
            .attr("cy", function(d){ return nodedata[d.target].cy; })
          .transition()
            .duration(300)
            .attr("r", 0)
            .style('opacity', 0.1)
            .remove();

      cur++;
      update_time_step(cur);
    }
    return setInterval(flow, time_interval);
  }

  var start_brushing = function(){
    var x = d3.scale.identity().domain([0, width]),
        y = d3.scale.identity().domain([0, height]);

    var brushstart = function(d){
      node.each(function(d) { d.previouslySelected = d.selected;})
    }

    var brushed = function() {
      var extent = brush.extent();

      node.classed("selected", function(d){ 
        return d.selected = d.previouslySelected ^
                       (extent[0][0] <= d.cx && d.cx < extent[1][0]
                    && extent[0][1] <= d.cy && d.cy < extent[1][1])
      });
    };


    var brushended = function() {
      console.log("brushended");
      d3.event.target.clear();
      d3.select(this).call(d3.event.target);
    };

    var brush = d3.svg.brush()
                  .x(x)
                  .y(y)
                  .on("brushstart", brushstart)
                  .on("brush", brushed)
                  .on("brushend", brushended);
   
    svg.append("g")
      //.datum(function() { return {selected: false, previouslySelected: false}; })
      .attr("class", "brush")
      .call(brush);
  };

  var init = function(){
    start_brushing();
    draw_ptc3_nodes();
  };

  return {
    init: init,
    init_scales: init_scales,
    ptc3_flow: ptc3_flow,
    duration: duration,
    time_interval: time_interval,
    animation_duration: animation_duration
  };
}();
