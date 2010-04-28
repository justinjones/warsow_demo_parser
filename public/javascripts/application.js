$(document).ready(function() {
	$('.corner-bottom').corner({
			  tl: false,
			  tr: false,
			  bl: { radius: 16 },
			  br: { radius: 16 },
			  antiAlias: true,
			  autoPad: true,
			  validTags: ["ul"] });
			
	$('.corner').corner({
	});
});