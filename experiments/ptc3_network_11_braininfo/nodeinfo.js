// Form Brain Image
// var brainImage = new Image();
// 	brainImage.src = "../../data/BrainImages/L-LOC.png";

// Form Tooltip
var tooltip = d3.select("body")
	.append("div")
	.style("position", "absolute")
	.style("z-index", "10")
	.style("visibility", "hidden")
	.style("background-color", "transparent")
	// .style("border", "2px solid black")
	// .style("border-radius", "20")
	.style("padding", "2")
	.attr("enabled", null);

// var brainImage = tooltip.append("svg:image")
// 	.attr("xlink:href", "../../data/BrainImages/L-LOC.png")
// 	.attr("width", 240)
// 	.attr("height", 160);
var info = [];

d3.csv("../../data/BrainImages/brain_areas.csv", function(data) {
	info = data;
});

// d3.csv("../../data/BrainImages/brain_areas.csv", function(data) {info = data})
// 	.row(function(d) { return {
// 		__key__: d.Area

// 	}});

function tooltip_update(area) {
	var contents = "<img class='tooltip_img' src='../../data/BrainImages/" + area + ".png'>"
	portion = area.substring(2);

	// Search for the info about this area (this could be done much faster with a key
		// but I don't know how that is done.

	for(i = 0; i < info.length; i++) {
		if(portion == info[i].Area) {
			title = "<span class='tooltip_title'>" + info[i].Description + "</span><br />";
			func  = "<span class='tooltip_function'>" + info[i].Function + "</span><br />";
		}
	}

	contents = title + func + contents;

	// brainImage.src = "../../data/BrainImages/" + area + ".png";
	// brainImage.attr("xlink:href", "../../data/BrainImages/" + area + ".png")

	tooltip.style("visibility", "visible")
    	   .html(contents);
}

function tooltip_move(x, y) {
	// tooltip.style("top" , (y - 10) + "px")
	// 	   .style("left", (x + 20) + "px");

	tooltip.style("top" , (y - 60) + "px")

	if(x < 500)
		tooltip.style("left", (x + 30) + "px");
	else
		tooltip.style("left", (x - 210) + "px");
}

function tooltip_close() {
	tooltip.style("visibility", "hidden");
}

function add_tooltip(selection) {
  selection.on('mouseover', function (d) {
              tooltip_update(d.category)
              tooltip_move(event.pageX, event.pageY)})
            .on('mousemove', function (d) {
              tooltip_move(event.pageX, event.pageY)})
            .on('mouseout', function (d) {
              tooltip_close()});
}
