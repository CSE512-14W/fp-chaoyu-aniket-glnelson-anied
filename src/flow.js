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
  /* Generating flow object
   */
  d3.flow = function() {
      var flow = {},
          flow.data = {},
          flow.nodes = [],
          flow.links = [],
          flow.duration = 1000,
          flow.currnt = 0;

      

      /* d:
       *   [{src, snk, value},...]
       *   animations in one time unit
       */
      flow.tick = function(d) {
        
      
      };

      flow.loop = function() {
      
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
  };

})();
