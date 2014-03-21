var plotMatrix = function()  {
  var margin = {top: 40, right: 40, bottom: 40, left: 40},
      width = 600,
      height = 600;

  var intensity = [];
  var aggreInOut = [];
  // refactoring to draw from the nodes dataset

  var init = function(){
      $("#matrix").html("");

      for(var i = 0; i < 40; i++)
      aggreInOut[i] = [];

      for(var i = 0; i < flowdata.length; i++){         //go thru all time slots
        for(var j=0; j < flowdata[i].length;  j++){   //go thru all edges in that time slot
          var src = parseInt(flowdata[i][j].source);
          var tar = parseInt(flowdata[i][j].target);
          if(isNaN(aggreInOut[src][tar])){
            aggreInOut[src][tar] = 1;
          }else{
            aggreInOut[src][tar]++;
          }
        }
      }

      //generating intensity using in and out degrees
      for(var i = 0; i < in_out_degree_at_timeslot.length; i++){
        intensity[i] = [];
        for(var j = 0; j < in_out_degree_at_timeslot.length; j++){
          intensity [i][j] = 0;
          //console.log( parseInt(in_out_degree_at_timeslot[1]) / aggreIn[j]);
          intensity [i][j] = parseInt(in_out_degree_at_timeslot[i][1]) / aggreInOut[i][j]; //0 or 1?
        }
      }

      //console.log(intensity);

      var h = 0.8,
      w = 0.8;

      var colorLow = '#f1f1f1', colorMed = 'darkred', colorHigh = 'gold';
      var colorScale = d3.scale.linear()
      .domain([0, 0.2, 0.4])
      .range([colorLow, colorMed, colorHigh]);

      var svg = d3.select("#matrix").append("svg")
      .attr("width", w * 15 * 40)
      .attr("height", h * 15 * 40)
      .append("g");

      var x = d3.scale.linear()
      .range([0, width])
      .domain([0,intensity[0].length]);

      var y = d3.scale.linear()
      .range([0, height])
      .domain([0,intensity.length]);

      var row = svg.selectAll(".row")
      .data(intensity)
      .enter().append("svg:g")
      .attr("class", "row");

      var col = row.selectAll(".cell")
      .data(function (d, i) { return d.map(function(a) { return {value: a, row: i}; } ) })
      .enter().append("svg:rect")
      .attr("class", "cell")
      .attr("x", function(d, i) { return x(i) * w; })
      .attr("y", function(d, i) { return y(d.row) * h; })
      .attr("width", x(1) * w)
      .attr("height", y(1) * h)
      .style("fill", function(d) { 
        if(isNaN(d.value)){
          return '#f1f1f1';
        }
        return colorScale(d.value); })
        .on('mousemove', function(d, i){mousemove(d, i)})
        .on("mouseover", mouseover)
        .on("mouseout", mouseout);

        var div = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 1e-6);

        function mousemove(d, i){
          div
          .html("Source: " + (i + 1) + "<br/>" + "Target: " + (d.row + 1) + " " + "Intensity: " + (d.value).toFixed(2))
          .style("left", (d3.event.pageX ) + "px")
          .style("top", (d3.event.pageY) + "px");
        }

        function mouseover() {
          div.transition()
          .duration(300)
          .style("opacity", 1);
        }

        function mouseout() {
          div.transition()
          .duration(300)
          .style("opacity", 1e-6);
        }
  }

  var draw = function(cur, duration){

      //remove svg
      $("#matrix").html("");
      
      //console.log(cur + '-'+duration);

      for(var i = 0; i < 40; i++)
      aggreInOut[i] = [];

      for(var i = cur; i < cur + duration; i++){         //go thru all time slots
        if(i < flowdata.length){
        for(var j=0; j < flowdata[i].length;  j++){   //go thru all edges in that time slot

          var src = parseInt(flowdata[i][j].source);
          var tar = parseInt(flowdata[i][j].target);
          if(isNaN(aggreInOut[src][tar])){
            aggreInOut[src][tar] = 1;
          }else{
            aggreInOut[src][tar]++;
          }
        }
        }
      }
      //console.log(aggreInOut);
      //console.log(in_out_degree_at_timeslot[1]);
      //generating intensity using in and out degrees
      for(var i = 0; i < in_out_degree_at_timeslot.length; i++){
        intensity[i] = [];
        for(var j = 0; j < in_out_degree_at_timeslot.length; j++){
          intensity [i][j] = 0;
          if(isNaN(aggreInOut[i][j]) == false && (nodedata[i].selected == 1 || nodedata[j].selected == 1 )) {
          //console.log( parseInt(in_out_degree_at_timeslot[1]) / aggreIn[j]);
          intensity [i][j] = parseInt(in_out_degree_at_timeslot[i][1]) / aggreInOut[i][j]; //0 or 1?
          }
        }
      }

      //console.log(intensity);

      var h = 0.8,
      w = 0.8;

      var colorLow = '#f1f1f1', colorMed = 'darkred', colorHigh = 'gold';
      var colorScale = d3.scale.linear()
      .domain([0, 1, 10])
      .range([colorLow, colorMed, colorHigh]);

      var svg = d3.select("#matrix").append("svg")
      .attr("width", w * 15 * 40)
      .attr("height", h * 15 * 40)
      .append("g");

      var x = d3.scale.linear()
      .range([0, width])
      .domain([0,intensity[0].length]);

      var y = d3.scale.linear()
      .range([0, height])
      .domain([0,intensity.length]);

      var row = svg.selectAll(".row")
      .data(intensity)
      .enter().append("svg:g")
      .attr("class", "row");

      var col = row.selectAll(".cell")
      .data(function (d, i) { return d.map(function(a) { return {value: a, row: i}; } ) })
      .enter().append("svg:rect")
      .attr("class", "cell")
      .attr("x", function(d, i) { return x(i) * w; })
      .attr("y", function(d, i) { return y(d.row) * h; })
      .attr("width", x(1) * w)
      .attr("height", y(1) * h)
      .style("fill", function(d) { 
        if(isNaN(d.value)){
          return '#f1f1f1';
        }
        
        return colorScale(d.value); })
        .on('mousemove', function(d, i){mousemove(d, i)})
        .on("mouseover", mouseover)
        .on("mouseout", mouseout);


        var div = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 1e-6);


        function mousemove(d, i){
          div
          .html("Source: " + (i + 1) + "<br/>" + "Target: " + (d.row + 1) + " " + "Intensity: " + (d.value).toFixed(2))
          .style("left", (d3.event.pageX ) + "px")
          .style("top", (d3.event.pageY) + "px");
        }

        function mouseover() {
          div.transition()
          .duration(300)
          .style("opacity", 1);
        }

        function mouseout() {
          div.transition()
          .duration(300)
          .style("opacity", 1e-6);
        }
  }


  return {
    init: init,
    draw: draw
  };

}();
