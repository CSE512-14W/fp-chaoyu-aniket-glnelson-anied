/*
 * Data Flow Animation plugin for D3.js
 *
 */

/* 
 * CONTROLL BRUSHING:
 * step(5 * 60 * 1000) 
 * next()
 * prev()
 * start()
 *
 * ANIMATION:
 * transition(d)
 * delay()
 * duration
 * ease
 * 
 * DRAW:
 * object(d)
 */
(function(){
  var flow = function() {
    var flow = {};
    flow.data = {},
    flow.nodes = [],
    flow.links = [],
    flow.duration = 1000;

    /* 
     * flow.node(nodes)
     *     .links(links)
     *     .data(data)
     *     .init(svg);
     */
    flow.init = function(svg) {
      flow.period = data.length;
      flow.cur = 0;
      flow.timeline = _.keys(data); 
      flow.packet = svg.selectAll('.packet');
    }


    /* d:
     *   [{src, snk, value},...]
     *   animations in one time unit
     */
    flow.tick = function() {
      //flow.packet.data(flow.data[timeline[cur%flow.period]])
      

    };

    flow.loop = function() {

    };

    flow.data = function(_) {
      if (!arguments.length) return data;
      data = _;
      return flow;
    };

    flow.nodes = function(_) {
      if (!arguments.length) return nodes;
      nodes = _;
      return flow;
    };

    flow.links = function(_) {
      if (!arguments.length) return links;
      links = _;
      return flow;
    };

    return flow;
  }; // end of d3.flow=
})();
