/** A custom view can consume the same progress values as a Lottie animation. */
exports.setProgress = function (progress) {
	$.percent.text = Math.round(progress * 100) + '%';
	$.indicator.opacity = 0.45 + progress * 0.55;
};
