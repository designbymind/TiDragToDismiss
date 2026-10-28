var args = arguments[0] || {};
var DragToDismiss = require('ti.dragtodismiss');
var gesture = null;
var customIndicator = null;
var footer = null;
var rows = [];
var disposed = false;
var closing = false;
var light = Ti.UI.userInterfaceStyle === 1;
$.window.backgroundColor = $.table.backgroundColor = light ? '#FFFFFF' : '#000000';
$.status.color = $.instructions.color = light ? '#333333' : '#DDDDDD';
$.table.separatorColor = light ? '#DDDDDD' : '#333333';
var names = ['Jenna', 'Emily', 'Grace', 'Kaviya', 'Sherry'];
var count = args.mode === 4 ? 2 : 15;
for (var i = 0; i < count; i++) {
	var row = Alloy.createController('dragtodismiss/reply', {
		name: names[i % names.length] + ' · Reply ' + (i + 1),
		message: i === count - 1 ? 'You reached the final reply. Pull up and keep holding to fill the indicator. Move back down to cancel, or release when it is full to go back.' : 'This is an ordinary Titanium TableView row. Keep scrolling to reach the final reply and try the pull-up gesture.'
	});
	rows.push(row);
}
$.table.data = rows.map(function (controller) { return controller.getView(); });
if (args.mode === 5) {
	footer = Alloy.createController('dragtodismiss/footer', args.footer || {});
	$.table.footerView = footer.getView();
	$.instructions.text = 'Scroll to the footer, then pull up to fill its ProgressBar. Release when the label says “Release to go back”, or pull back down to cancel.';
}

function attachGesture() {
	if (disposed || gesture) return;
	// Begin filling almost immediately after reaching the bottom edge.
	var options = { scrollView: $.table, threshold: 120, revealDistance: 1 };
	if (args.mode === 1) { options.icon = { systemImage: 'arrow.uturn.backward', size: 24, weight: 'bold' }; options.rotatesIcon = false; }
	if (args.mode === 2) { options.icon = '/images/dragtodismiss/back.png'; options.rotatesIcon = false; }
	if (args.mode === 3) {
		customIndicator = Alloy.createController('dragtodismiss/indicator');
		options.indicatorView = customIndicator.getView();
	}
	if (footer) {
		// An empty custom indicator leaves the TableView footer as the pull indicator.
		options.indicatorView = Ti.UI.createView({ width: 55, height: 55, touchEnabled: false });
	}
	gesture = DragToDismiss.createGesture(options);
	gesture.addEventListener('progress', onProgress);
	gesture.addEventListener('trigger', onTrigger);
	if (args.mode === 1) {
		// This assignment exercises the runtime setter, rather than a creation option.
		updateIndicatorColor();
		Ti.App.iOS.addEventListener('traitcollectionchange', updateIndicatorColor);
	}
	$.progressBar.show();
	if (footer) footer.showProgress();
}
/** Recolor the SF Symbol example when switching between light and dark mode. */
function updateIndicatorColor() {
	if (disposed || closing || !gesture) return;
	gesture.indicatorColor = Ti.UI.userInterfaceStyle === 1 ? '#007AFF' : '#64D2FF';
}
/** Progress reverses continuously while pulling back or returning after release. */
function onProgress(event) {
	if (disposed || closing) return;
	$.progressBar.value = event.progress;
	$.status.text = event.ready ? 'Release to go back' : Math.round(event.progress * 100) + '% · Pull up to fill, down to cancel';
	if (customIndicator) customIndicator.setProgress(event.progress);
	if (footer) footer.setProgress(event.progress, event.ready);
}
function onTrigger() {
	if (disposed || closing) return;
	closing = true;
	Ti.API.info('[TiDragToDismiss] trigger: popping the thread');
	args.navigation.closeWindow($.window);
}
function toggleEnabled() {
	if (!gesture || disposed || closing) return;
	gesture.enabled = !gesture.enabled;
	$.toggle.title = gesture.enabled ? 'Disable' : 'Enable';
	$.status.text = gesture.enabled ? 'Scroll to the bottom, then pull up' : 'Drag to dismiss disabled';
}
/** Keep a visible touch check alongside the scroll gesture. */
function rowTapped(event) {
	if (!disposed && !closing) $.status.text = 'Reply tapped · row ' + (event.index + 1);
}
function onClosed() { dispose(); }
function dispose() {
	if (disposed) return;
	disposed = true;
	if (args.mode === 1) Ti.App.iOS.removeEventListener('traitcollectionchange', updateIndicatorColor);
	if (gesture) {
		gesture.removeEventListener('progress', onProgress);
		gesture.removeEventListener('trigger', onTrigger);
		gesture.detach();
		gesture = null;
	}
	rows.forEach(function (row) { row.destroy(); row.off(); });
	rows = [];
	if (customIndicator) { customIndicator.destroy(); customIndicator.off(); customIndicator = null; }
	if (footer) { footer.destroy(); footer.off(); footer = null; }
	$.destroy();
	$.off();
	var onClose = args.onClose;
	args = DragToDismiss = null;
	if (onClose) onClose();
}
exports.dispose = dispose;
