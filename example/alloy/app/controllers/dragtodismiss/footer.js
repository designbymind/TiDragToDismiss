var args = arguments[0] || {};
var pullText = args.pullText !== undefined ? args.pullText : 'Pull up to go back';
var releaseText = args.releaseText !== undefined ? args.releaseText : 'Release to go back';
var labelFade = args.labelFade !== false;
var labelTravel = typeof args.labelTravel === 'number' && isFinite(args.labelTravel) ? args.labelTravel : 8;

// Styles live in footer.tss; callers may override native view properties here.
$.footer.applyProperties(args.view || {});
$.progressBar.applyProperties(args.progressBar || {});
$.progressBar.applyProperties({ min: 0, max: 1, value: 0 });
$.label.color = Ti.UI.userInterfaceStyle === 1 ? '#333333' : '#DDDDDD';
$.label.applyProperties(args.label || {});
var labelOpacity = typeof $.label.opacity === 'number' ? $.label.opacity : 1;
var labelTransform = (args.label && args.label.transform) || Ti.UI.createMatrix2D();

/** Keep the footer in sync while pulling up, reversing, or bouncing back. */
function setProgress(progress, ready) {
	progress = Math.max(0, Math.min(1, progress));
	// Native readiness is the same state used by the release decision.
	ready = ready === undefined ? progress >= 1 : !!ready;
	$.progressBar.value = progress;
	$.label.applyProperties({
		text: ready ? releaseText : pullText,
		opacity: labelOpacity * (labelFade ? progress : 1),
		transform: labelTransform.translate(0, labelTravel * (1 - progress))
	});
}
exports.setProgress = setProgress;
setProgress(0);

exports.showProgress = function () { $.progressBar.show(); };
