//(function(){ // make everything same namespace for now so easier
// console inspect; refactor into private / local namespaces as needed
// I checked nodeinfo for no namespace collisions
  var nodedata, groupnode, flowdata = [];
  var time_max = -1;
  var current_time_step = 0;
  var controller_brusher;
  var flow_id;

  function start(){
    flow_id = flow.ptc3_flow();
  }
  function stop(){
    if (flow_id !== undefined) clearInterval(flow_id);
  }
  window.start = start;

  d3.csv("data/PTC3-V.csv", function(data) {
    nodedata = data.map(function(d) {
      return {
        label: d.label,
        x: +d.xcoord,
        y: +d.ycoord,
        z: +d.zcoord,
        area: d.area,
        plot: d.plot,
	total_in_degree: 1,
	total_out_degree: 1,
	selected: 0,
        time_data: new Array() // index = t, [in_degree, out_degree]
      };
    });
    flow.init_scales();
 
    var array_in_out_size_of_nodes = function(nodes){
      var x = [];
      _.each(nodes, function(d){
        x.push([0,0]);
      });
      return x;
    };

    var set_total_in_out = function(nodes){
      for (var i = 0; i<nodes.length; i++){
	var total_in = 0;
	var total_out = 0;

	_.each(nodes[i].time_data, function(t){
	  total_in += t[0];
	  total_out += t[1];
	});

	nodes[i].total_in_degree = total_in;
	nodes[i].total_out_degree = total_out;
      };
    };

    // load the time data
    d3.csv("data/F-PTC3-words95-LD-E.csv", function(data) {
      var previous_timeslot;

      var this_timeslot = 1;
      _.each(data, function(d) {
        if(d.t == previous_timeslot) {
          flowdata[flowdata.length-1].push({"source": +d.src -1, "target": +d.snk - 1})
          this_timeslot[+d.src-1][1]+= 1;
          this_timeslot[+d.snk-1][0]+= 1;

        } else {
          if (this_timeslot!= 1){
            // load the in_out_degree into nodedata
            for( var i = 0; i<nodedata.length; i++){
              nodedata[i]["time_data"].push(this_timeslot[i]);
            };
          };
          this_timeslot = array_in_out_size_of_nodes(nodedata);
          previous_timeslot = d.t;
          flowdata.push([{"source": +d.src - 1, "target": +d.snk -1}]);
          this_timeslot[+d.src-1][1]+= 1;
          this_timeslot[+d.snk-1][0]+= 1;
        }
      });

      set_total_in_out(nodedata);

      time_max = flowdata.length
      //plotMatrix(in_out_degree_at_timeslot, flowdata, 0);
      flow.init();
      //plotMatrix(in_out_degree_at_timeslot, flowdata, 0);
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
