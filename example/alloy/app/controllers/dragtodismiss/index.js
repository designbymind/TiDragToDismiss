var args = arguments[0] || {};
var closed = false;
var closing = false;
var detail = null;
var light = Ti.UI.userInterfaceStyle === 1;
// Footer example configuration. Other ProgressBar / Label properties can be added here.
var footerOptions = {
	pullText: 'Pull up to go back',
	releaseText: 'Release to go back',
	labelFade: true,
	labelTravel: 8, // Points below its resting position at progress 0; use 0 for no movement.
	progressBar: { tintColor: '#007AFF', trackTintColor: light ? '#E5E5EA' : '#38383A' },
	label: { color: light ? '#333333' : '#DDDDDD', font: { fontSize: 14 }, textAlign: 'center' }
};
$.window.backgroundColor = $.examples.backgroundColor = light ? '#FFFFFF' : '#000000';
$.intro.color = light ? '#333333' : '#DDDDDD';
$.examples.sections[0].rows.forEach(function (row) {
	row.color = light ? '#111111' : '#EEEEEE';
});

/** Open one TableView variation in this component's navigation stack. */
function openExample(event) {
	if (closed || closing || detail) return;
	detail = Alloy.createController('dragtodismiss/thread', {
		mode: event.index,
		footer: footerOptions,
		navigation: $.navigation,
		onClose: function () {
			detail = null;
		}
	});
	$.navigation.openWindow(detail.getView());
}
function closeProject() {
	if (closed || closing) return;
	closing = true;
	$.navigation.close();
}
/** Release the component and notify the Components menu once. */
function onProjectClosed(event) {
	if (event.source !== $.navigation || closed) return;
	closed = true;
	if (detail) detail.dispose();
	detail = null;
	$.destroy();
	$.off();
	var onClose = args.onClose;
	args = null;
	if (onClose) onClose();
}
$.navigation.open();
