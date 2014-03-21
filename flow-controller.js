var update_textbox = function(start){
  d3.select("#textbox_timestart")
  .attr("value", start);
  d3.select("#textbox_timestop")
  .attr("value", start + flow.duration);
};

var update_time_step = function(cur) {
  current_time_step = cur;
  d3.select("#controller g")
    .transition()
    .call(controller_brusher.extent([cur, cur+flow.duration]));

  update_textbox(cur);
}

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
  var defaultExtent = [0,flow.duration];

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
    var end = Math.floor(extent[1])

    flow.duration = Math.min(end - start, 50);
    flow.duration = Math.max(flow.duration, 7);
    console.log(flow.duration);
    // flow.time_interval = flow.animation_duration / flow.duration;

      var target_extent = [start, start + flow.duration];
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

