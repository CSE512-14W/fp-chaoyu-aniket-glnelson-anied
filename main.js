//(function(){ // make everything same namespace for now so easier
// console inspect; refactor into private / local namespaces as needed
// I checked nodeinfo for no namespace collisions
  var margin = {top: 40, right: 40, bottom: 40, left: 40},
      width = 600,
      height = 600;

  var svg = d3.select("#graph")
              .append("svg")
              .attr("width", width)
              .attr("height", height);
                //.attr("class", 'graph-svg')

  var node = svg.selectAll(".node");
  var packet = svg.selectAll(".packet");

  // flowdata is [[src, target], ...], next timestep, ...]
  var nodedata, groupnode, flowdata = [];
  var x_range, y_range, x_scale, y_scale, c_scale;

  var current_time_step = 0;
  var controller_brusher;

  var flow_id;
  // Start animtaion
  function start(){
    flow_id = ptc3_flow();
  }
  function stop(){
    if (flow_id !== undefined) clearInterval(flow_id);
  }
  window.start = start;

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
  var ptc3_network = function() {
    node = node.data(nodedata)
        .enter()
        .append("circle")
          .attr({
            "class": function(d){ return "node " + d.category; },
            "fill": function(d){ return c_scale(d.category); },
            "r": function(d){ return (d.r * 3) + 4; },
            "cx": function(d){ return d.cx; },
            "cy": function(d){ return d.cy; }
          })
        .call(add_tooltip); 
  };

  var update_textbox = function(start){
      d3.select("#textbox_timestart")
        .attr("value", start);
      d3.select("#textbox_timestop")
        .attr("value", start + duration);
    };

  // Animation parameters
  var animation_duration = 1800;
  var duration = 7;
  var time_interval = animation_duration / duration;

  var graph_contoller = function(){
    
    var controller_area = d3.select('#controller')
      .attr('width', 600)
      .attr('height', 60)
      .style("display","block")
      .style("margin","auto")
      .style("width","600px");

    // Add control buttons
    controller_area.append("input")
      .attr("type","button")
      .attr("class","btn btn-default")
      .attr("value", "Start")
      .on("click", start);
    controller_area.append("input")
      .attr("type","button")
      .attr("class","btn btn-default")
      .attr("value", "Stop")
      .on("click", stop);
    controller_area.append("input")
      .attr('id', 'textbox_timestart')
      .style("width","40px") // was 50
      .attr("value", "0");
      // .on("click", function (d) {
      //   current_time_step = parseInt(d3.select('#textbox_timestart').attr('value'));
      //   });
    controller_area.append("span")
      .text(' to ');
    controller_area.append("input")
      .attr('id', 'textbox_timestop')
      .style("width","40px") // was 50
      .attr("value", "7");
      // .on("click", time_update(0, 7));
    controller_area.append("span")
      .text(' ms');

    var controller_height = 40;
    var controller_width = 600;
    var x = d3.scale.identity().domain([0, controller_width]);
    var defaultExtent = [0,duration];
    
    var slidersvg = controller_area.append("svg")
        .attr("width", controller_width)
        .attr("height", controller_height);

    var controller_scale = d3.scale.linear()
                            .domain([0, 600])
                            .range([0, controller_width])
                            .nice();
    /*
     * TODO user clicks on timeline while animation running
     * timeline goes to that point in time immediately
     * without having to press start again
     */
    var brushed = function() {
      var extent = brush.extent();
      var start = Math.floor(extent[0])

      update_textbox(start);

      // was trying to get this to be instantly brushable
      // wasn't working out well
      //current_time_step = start;
      //d3.select(this).transition() // i think not working bc of how initialized
      // .call(brush.extent(target_extent));
    };

    var brushended = function() {
      console.log("c brushended");

      var extent = brush.extent();
      var start = Math.floor(extent[0])
      var target_extent = [start, start + duration];
      current_time_step = start;
      d3.select(this).transition()
        .call(brush.extent(target_extent));
      // was trying to get this to be instantly brushable
      // wasn't working out well, need refactor drawing
      // to make it work well I think
      // so draw has interface draw(start,stop,loop_start,loop_end)
      // that sets up interval etc
      // update_time_step(current_time_step);
    };

    // TODO look at doc and see if different events
		  // for center (ie drag click)
		  // vs extent / duration drag clicks
    var brush = d3.svg.brush()
                  .x(controller_scale)
                  .extent(defaultExtent)
                  .on("brush", brushed)
                  .on("brushend", brushended);

    // TODO replace with avg in and out degree
		  // summary plot
    slidersvg.append("rect")
        .attr({
          width: controller_width,
          height: controller_height,
          class: 'controller-background'
        });

    var gBrush = slidersvg.append("g")
                    .attr("class", "brush")
                    .call(brush)
                    .call(brush.event);
                    gBrush

    gBrush.selectAll("rect")
      .attr("height", controller_height)

    return brush;
  };

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

  var update_time_step = function(cur) {
    current_time_step = cur;
    d3.select("#controller g")
      .transition()
      .call(controller_brusher.extent([cur, cur+duration]));

    update_textbox(cur);
  }

  var ptc3_flow = function(){
    console.log("redraw");
    var cur = current_time_step;
    var ll  = flowdata.length;

    function flow(){
      if(cur >= ll){ cur = 0; current_time_step = 0;}
      console.log("cur: " + cur);
      selected = _.filter(flowdata[cur % ll], function(d){ return nodedata[d.source].selected == true });
      
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

  // TODO switch to nodes being clicked or not
  var start_brushing = function(){
    var defaultExtent = [[7, 132], [216, 450]],
        x = d3.scale.identity().domain([0, width]),
        y = d3.scale.identity().domain([0, height]);

    var brushed = function() {
      var extent = brush.extent();
      console.log(extent);
      node.each(function(d) {
        d.selected = (extent[0][0] <= d.cx) && (d.cx < extent[1][0])
                    && (extent[0][1] <= d.cy) && (d.cy < extent[1][1]);
      });
      node.classed("selected", function(d){ return d.selected;})
    };


    var brushended = function() {
      console.log("brushended");
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
    
    ptc3_network();
    brushed();
    brushended();
  };

  d3.csv("data/PTC3-V.csv", function(data) {
    nodedata = data.map(function(d) {
      return {
        label: d.label,
        x: +d.xcoord,
        y: +d.ycoord,
        z: +d.zcoord,
        area: d.area,
        plot: d.plot,
        time_data: new Array() // index = t, [in_degree, out_degree]
      };
    });
    init_scales();
 
    var array_in_out_size_of_nodes = function(nodes){
      var x = [];
      _.each(nodes, function(d){
        x.push([0,0]);
      });
      return x;
    };

    // load the time data
    d3.csv("data/F-PTC3-words95-LD-E.csv", function(data) {
      var previous_timeslot;
      var in_out_degree_at_timeslot = 1;

      _.each(data, function(d) {
        if(d.t == previous_timeslot) {
          flowdata[flowdata.length-1].push({"source": +d.src -1, "target": +d.snk - 1})
          in_out_degree_at_timeslot[+d.src-1][1]+= 1;
          in_out_degree_at_timeslot[+d.snk-1][0]+= 1;

        } else {
          if (in_out_degree_at_timeslot!= 1){
            // load the in_out_degree into nodedata
            for( var i = 0; i<nodedata.length; i++){
              nodedata[i]["time_data"].push(in_out_degree_at_timeslot[i]);
            };
          };
          in_out_degree_at_timeslot = array_in_out_size_of_nodes(nodedata);
          previous_timeslot = d.t;
          flowdata.push([{"source": +d.src - 1, "target": +d.snk -1}]);
          in_out_degree_at_timeslot[+d.src-1][1]+= 1;
          in_out_degree_at_timeslot[+d.snk-1][0]+= 1;
        }
      });
      plotMatrix(in_out_degree_at_timeslot, flowdata, 0);
      start_brushing();
      controller_brusher = graph_contoller();
    });

  });
//})();

/*
 * TODO
 *
(NAME) to say I will do this
(NAME+) I will help with this

(GREG+) Writeup - Greg has refs and structure in head / from poster

Features that remain:

1. Aggregate charts for selection (on right hand side)
2. Matrix representation of graph
(GREG)  Refactor to show with time
3. Visual hypothesis testing 
4. Comparing two datasets ie data from nonsense vs real word

Nice to have:
1. Fix "density" issue for nodes closer together (route through center? adjust?)
2. Show inverse of the graph
3. More fully featured sensors and deriving sensors from simpler sensors (frequency filters, differences, et)
4. Comparing >2 datasets
5. Changing layout between physical and circle

Conrad's thoughts
Features to do: (Preface: Don't worry about getting it all done! Future work is acceptable)
1) Nice feature, but do this lastish
2) Great! You guys have been working on this already
3) I'll make some null models. There are a few ways to do it. I'll whiteboard it in the HCI lab tomorrow morning.
4) Great! Again, there is no one way to compare this data so I'll whiteboard it to capture a sense.
5) Persistent labels. This "shouldn't" be difficult.

Nice to have:
1) That would be cool, Jeff would appreciate it for sure, also if it is a toggle
2) I don't think that would be useful for this data, even as a comparison point. Null models will be better.
3) Cool, but sounds complicated :p Let's get to that if we have time
4) Yes! Addressed before.
5) Changing layout between circle & physical (both have drawbacks but I think it is good to have both representations).
 *
 * Maybe TODO
 * refactor time since we're juggling between index and actual time value
 */