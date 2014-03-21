//(function(){ // make everything same namespace for now so easier
// console inspect; refactor into private / local namespaces as needed
// I checked nodeinfo for no namespace collisions
  var nodedata, groupnode, flowdata = [];
  var in_out_degree_at_timeslot = 1;
  
  var current_time_step = 0;
  var controller_brusher;
  var flow_id;

  var array_in_out_size_of_nodes;

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
        time_data: new Array() // index = t, [in_degree, out_degree]
      };
    });
    flow.init_scales();
 
    array_in_out_size_of_nodes = function(nodes){
      var x = [];
      _.each(nodes, function(d){
        x.push([0,0]);
      });
      return x;
    };

    loaddata()
  });

  // load the time data
  first_run = true;
  function loaddata() {
    hash = location.hash;
    if(hash == null || hash == "") {
      hash = '95-LD';
    }
    perc = hash.substring(1, 3);
    cond = hash.substring(4, 6);
    if(perc == '50') {
      filename = "data/F-PTC3-words-" + cond + "-E.csv";
    } else {
      filename = "data/F-PTC3-words" + perc + "-" + cond + "-E.csv";
    }
    d3.csv(filename, function(data) {
      var previous_timeslot;
      flowdata = [];
      
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

      if(first_run) {
        flow.init()
        controller_brusher = graph_contoller();
        first_run = false;
      }

      plotMatrix.init();
    });
  }
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
