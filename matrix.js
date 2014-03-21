var plotMatrix = function()  {
  var margin = {top: 40, right: 40, bottom: 40, left: 40},
      width = 600,
      height = 600;

  var intensity = [];
  var aggreInOut = [];
  // refactoring to draw from the nodes dataset
  
  var zero_array = function (dimensions) {
      var x = [];
      
      for (var i = 0; i<dimensions; i++){
        x.push
      };
      _.each(nodes, function(d){
        x.push([0,0]);
      });
      return x;
  
  };
  var aggregate_matrix = function(cur, duration){
      for(var i = 0; i < 40; i++)
        aggreInOut[i] = [];

      for(var i = cur; i < cur + duration; i++){         //go thru all time slots
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
      return aggreInOut;
  };

  var intensity_matrix = function (agg_matrix) {
      var intens = [ ];
        baseline = nodedata;
        for(var src = 0; src < nodedata.length; src++){
          intens[src] = [];
          for(var tgt = 0; tgt < nodedata.length; tgt++){
            intens [src][tgt] = 0;
            if (nodedata[tgt].total_in_degree != 0 && !(isNaN(agg_matrix[src][tgt]))){
                intens [src][tgt] = parseInt(agg_matrix[src][tgt]) / nodedata[tgt].temp_in_count;
            }
          }
        }
      
      return intens;
  };

  var init = function(){
      // aggregate over the whole dataset
      aggreInOut = aggregate_matrix(0, time_max);

      //generating intensity using in and out degrees
      intensity = intensity_matrix(aggreInOut);

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
      
      // aggreInOut is a 2d matrix [src][target] = count of edges over duration
      aggreInOut = aggregate_matrix(cur,duration);
      
      //generating intensity using in and out degrees
      intensity = intensity_matrix(aggreInOut);

      if (cur == 0){
      var breakhere=1;
      }
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
  }

}();
