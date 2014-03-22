var plotMatrix = function()  {
  var margin = {top: 40, right: 40, bottom: 40, left: 40},
      width = 600,
      height = 600;

  var intensity = [];
  var aggreInOut = [];
  // refactoring to draw from the nodes dataset
  var key = function(d){
    return d
  };
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
            nodedata[tar].temp_in_count = 1;
          }else{
            aggreInOut[src][tar]++;
            nodedata[tar].temp_in_count++;
          }
        }
      }

      //generating intensity using in and out degrees
      for(var src = 0; src < nodedata.length; src++){
        intensity[src] = [];
        for(var tgt = 0; tgt < nodedata.length; tgt++){
          intensity [src][tgt] = 0;
          intensity [src][tgt] = parseInt(aggreInOut[src][tgt]) / nodedata[tgt].temp_in_count; 
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
      .attr("width", w * 15 * 40 + 60)
      .attr("height", h * 15 * 40 + 60)
      .append("g");

      var x = d3.scale.linear()
      .range([0, width])
      .domain([0,intensity[0].length]);

      var y = d3.scale.linear()
      .range([0, height])
      .domain([0,intensity.length]);

      var textX = svg.selectAll("text")
         .data(nodedata)
                        .enter()
                        .append("text")
                        .attr("transform", function(d, i) { return "translate(" + (70 + x(i)/1.25) + ", " + 50 + ")rotate(-90)"; });

      //Add SVG Text Element Attributes
      
      var textLabelsX = textX
                 .attr("x", function(d,i) { return 0; })
                 .attr("y", function(d) { return 0; })
                 .attr("text-anchor", "start")
                 .text( function (d,i) { return nodedata[i].label; })
                 .attr("font-family", "sans-serif")
                 .attr("font-size", "10px")
                 .attr("fill", "black");
      
      var textY = svg.selectAll("textY")
         .data(nodedata)
                        .enter()
                        .append("text")
                        .attr("transform", function(d, i) { return "translate(" + 0 + ", " + (60 + y(i)/1.25) + ")"; });
      
      //Add SVG Text Element Attributes
      var textLabelsY = textY
                 .attr("x", function(d,i) { return 0; })
                 .attr("y", function(d) { return 0; })
                 .attr("text-anchor", "start")
                 .text( function (d,i) { return nodedata[i].label; })
                 .attr("font-family", "sans-serif")
                 .attr("font-size", "10px")
                 .attr("fill", "black");



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
      .attr("transform", function(d, i) { return "translate(" + 60 + ", " + 50 + ")"; })
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
          .html("Target: " + nodedata[i].label + "<br/>" + "Source: " + nodedata[d.row].label + " " + "Intensity: " + (d.value).toFixed(2))
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

  // can speed up by
  // turning off the old edges
  // and turning on the new edges
  // so O(edges) instead of O(n^2)
  var draw = function(cur, duration){

      //remove svg
      // TODO performance - remove, don't append each time
      //$("#matrix").html("");
      
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
            nodedata[tar].temp_in_count = 1;
          }else{
            aggreInOut[src][tar]++;
            nodedata[tar].temp_in_count++;
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
          intensity [i][j] = parseInt(in_out_degree_at_timeslot[i][1]) / nodedata[i].temp_in_count; //0 or 1?
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

      var svg = d3.select("#matrix")/*.append("svg")
      .attr("width", w * 15 * 40 + 60)
      .attr("height", h * 15 * 40 + 60)
      .append("g");
*/
      var x = d3.scale.linear()
      .range([0, width])
      .domain([0,intensity[0].length]);

      var y = d3.scale.linear()
      .range([0, height])
      .domain([0,intensity.length]);


 /*     var textX = svg.selectAll("text")
         .data(nodedata)
                        .enter()
                        .append("text")
                        .attr("transform", function(d, i) { return "translate(" + (70 + x(i)/1.25) + ", " + 50 + ")rotate(-90)"; });

      //Add SVG Text Element Attributes
      
      var textLabelsX = textX
                 .attr("x", function(d,i) { return 0; })
                 .attr("y", function(d) { return 0; })
                 .attr("text-anchor", "start")
                 .text( function (d,i) { return nodedata[i].label; })
                 .attr("font-family", "sans-serif")
                 .attr("font-size", "10px")
                 .attr("fill", "black");
      
      var textY = svg.selectAll("textY")
         .data(nodedata)
                        .enter()
                        .append("text")
                        .attr("transform", function(d, i) { return "translate(" + 0 + ", " + (60 + y(i)/1.25) + ")"; });
      
      //Add SVG Text Element Attributes
      var textLabelsY = textY
                 .attr("x", function(d,i) { return 0; })
                 .attr("y", function(d) { return 0; })
                 .attr("text-anchor", "start")
                 .text( function (d,i) { return nodedata[i].label; })
                 .attr("font-family", "sans-serif")
                 .attr("font-size", "10px")
                 .attr("fill", "black");

*/
      var row = svg.selectAll(".row")
      .data(intensity)
      //.enter().append("svg:g")
      
      //.attr("class", "row");

      var col = row.selectAll(".cell")
      .data(function (d, i) { return d.map(function(a) { return {value: a, row: i}; } ) })
      //.enter().append("svg:rect")
      .attr("class", "cell")
      //.attr("x", function(d, i) { return x(i) * w; })
      //.attr("y", function(d, i) { return y(d.row) * h; })
     // .attr("width", x(1) * w)
     // .attr("height", y(1) * h)
    //  .attr("transform", function(d, i) { return "translate(" + 60 + ", " + 50 + ")"; })
      .style("fill", function(d) { 
        if(isNaN(d.value)){
          return '#f1f1f1';
        }
        
        
        return colorScale(d.value); })
        .on('mousemove', function(d, i){mousemove(d, i)})
        .on("mouseover", mouseover)
        .on("mouseout", mouseout)
        .transition();


        var div = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 1e-6);


        function mousemove(d, i){
          div
          .html("Target: " + nodedata[i].label + "<br/>" + "Source: " + nodedata[d.row].label + " " + "Intensity: " + (d.value).toFixed(2))
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
    draw: draw,
    intensity: intensity,
    aggreInOut: aggreInOut
  };

}();
