// Form Brain Image
// var brainImage = new Image();
// 	brainImage.src = "../../data/BrainImages/L-LOC.png";

// Form infotip
var infotip = d3.select("body")
	.append("div")
	.attr("id", "infotips")
	.style("position", "absolute")
	.style("z-index", "10")
	.style("visibility", "hidden")
	.style("background-color", "white")
	.style("border", "2px solid black")
	.style("border-radius", "20px")
	.style("width", "200px")
	.style("padding", "8px")
	.attr("enabled", null);

// Create Info buttons!
function add_tooltips() {
	parent = d3.select("#threshold_selector");
	d3.select("body").append("img")
		.data(["Use the dropdown menus to specify datasets."])
	    .style("left", parent[0][0].offsetLeft + 80 + "px")
	    .style("top", parent[0][0].offsetTop + "px")
	    .call(add_infotip);

	parent = d3.select("circle");
	console.log(parent);
	d3.select("#graph").append("img")
		.data(["Click on a node and drag to move it's location."])
	    .style("left", parent[0][0].offsetParent.offsetLeft + 5 + "px")
	    .style("top", parent[0][0].offsetParent.offsetTop - 40 + "px")
	    .call(add_infotip);

	parent = d3.select("circle");
	console.log(parent);
	d3.select("#graph").append("img")
		.data(["Brush over nodes to select them."])
	    .style("left", parent[0][0].offsetParent.offsetLeft + 25 + "px")
	    .style("top", parent[0][0].offsetParent.offsetTop - 55 + "px")
	    .call(add_infotip);

	parent = d3.select("#controller").select('svg');
	console.log(parent);
	d3.select("#controller").append("img")
		.data(["When stopped, brush over the timeline to specific the start time and stop time."])
	    .style("left", parent[0][0].offsetLeft - 30 + "px")
	    .style("top", parent[0][0].offsetTop + 20 + "px")
	    .call(add_infotip);

	parent = d3.select("#controller").select('input');
	console.log(parent);
	d3.select("#controller").append("img")
		.data(["Start the animation or stop it (warning: will not freeze the animation)."])
	    .style("left", parent[0][0].offsetLeft - 30 + "px")
	    .style("top", parent[0][0].offsetTop + 15 + "px")
	    .call(add_infotip);
}

function infotip_update(contents) {
	infotip.style("visibility", "visible")
    	   .text(contents);
}

function infotip_move(x, y) {
	infotip.style("top" , (y - 10) + "px")
		.style("left", (x + 20) + "px");

	// if(x > 750)
	// 	infotip.style("left", (x + 30) + "px");
	// else
	// 	infotip.style("left", (x - 210) + "px");
}

function infotip_close() {
	infotip.style("visibility", "hidden");
}

function add_infotip(selection) {
  selection
	.attr("class", "infotip")
	.attr("src", "data/info.png")
    .attr("width", "20")
    .attr("height", "20")
	.style("position", "absolute")
	.style("z-index", "9")
	.on('mouseover', function (d) {
      infotip_update(d)
      infotip_move(event.pageX, event.pageY)})
    .on('mousemove', function (d) {
      infotip_move(event.pageX, event.pageY)})
    .on('mouseout', function (d) {
      infotip_close()});
}
