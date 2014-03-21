/* datamenu.js
 * Gives the user options to load data
 * 
 * Author: Yang Chaoyu, Aniket Handa, Gregory Nelson, A Conrad Nied
 *
 * 2014-03-20
 */

// Get the current page hash
hash = location.hash;
if(hash == null || hash == "") {
	hash = '95-LD';
	location.hash = hash;
}

// Get constituents
perc = hash.substring(1, 3);
cond = hash.substring(4, 6);

// Load the page's data
//loaddata();

// Options
conditions = ["HD", "LD", "HF", "LF"];
percentiles = ["99", "95", "50"];
condition_labels = {"HD": "High Lexical Density",
					"LD": "Low Lexical Density",
					"HF": "High Phonological Frequency",
					"LF": "Low Phonological Frequency"};

// Set the datamenu
var datamenu_area = d3.select('#datamenu')
  .attr('width', 600)
  .attr('height', 20)
  .style("display","block")
  .style("margin","auto")
  .style("width","600px");

// Modify Condition
datamenu_area.append("span")
  .text('Condition:')
  .style('padding', '0px 5px 0px 5px');

datamenu_area.append("select")
  .attr('id', 'condition_selector')
  .style("width","240px")
  .attr("value", "7")
  .selectAll("option")
  .data(conditions)
  .enter()
  .append("option")
  	.text(function(d) {return condition_labels[d];})
  	.attr("id", function(d) {return "cond" + d;});

d3.select("#cond" + cond)
	.attr("selected", "");

d3.select("#condition_selector")
	.attr('selectedIndex', 2)
	.on("change", function() {
	  	cond = conditions[this.selectedIndex];
		location.hash = perc + "-" + cond;
		// location.reload();
		loaddata();
  	});
  	
// Modify percentile
datamenu_area.append("span")
  .text('GCI Percentile:')
  .style('padding', '0px 5px 0px 20px');

datamenu_area.append("select")
  .attr('id', 'threshold_selector')
  .style("width","75px")
  .attr("value", "7")
  .selectAll("option")
  .data(percentiles)
  .enter()
  .append("option")
  	.text(function(d) {return d + "th";})
  	.attr("id", function(d) {return "thresh" + d;});

d3.select("#thresh" + perc)
	.attr("selected", "");

d3.select("#threshold_selector")
	.attr('selectedIndex', 2)
	.on("change", function() {
	  	perc = percentiles[this.selectedIndex];
		location.hash = perc + "-" + cond;
		// location.reload();
		loaddata();
  	});
