var DragToDismiss = require('ti.dragtodismiss');
var window = Ti.UI.createWindow({ title: 'Pull up to close' });
var rows = Array.from({ length: 20 }, function (_, index) {
    return Ti.UI.createTableViewRow({
        title: index === 19 ? 'Pull up here, then release when full' : 'Reply ' + (index + 1),
        height: 70
    });
});
var status = Ti.UI.createLabel({ top: 8, left: 20, right: 20, height: 30, textAlign: 'center', text: 'Scroll to the bottom, then pull up' });
var progress = Ti.UI.createProgressBar({ top: 44, left: 20, right: 20, height: 16, min: 0, max: 1, value: 0 });
var table = Ti.UI.createTableView({ top: 76, data: rows });
var gesture = null;
window.add(status);
window.add(progress);
window.add(table);

function applyAppearance() {
    var light = Ti.UI.userInterfaceStyle === 1;
    window.backgroundColor = table.backgroundColor = light ? '#FFFFFF' : '#000000';
    status.color = light ? '#111111' : '#EEEEEE';
    rows.forEach(function (row) { row.color = status.color; });
    // indicatorColor supports runtime assignments in 0.2.1.
    if (gesture) gesture.indicatorColor = light ? '#007AFF' : '#64D2FF';
}
function onOpen() {
    gesture = DragToDismiss.createGesture({
        scrollView: table,
        threshold: 120,
        revealDistance: 1,
        icon: { systemImage: 'arrow.uturn.backward', size: 24, weight: 'bold' },
        rotatesIcon: false
    });
    gesture.addEventListener('progress', onProgress);
    gesture.addEventListener('trigger', onTrigger);
    Ti.App.iOS.addEventListener('traitcollectionchange', applyAppearance);
    applyAppearance();
    progress.show();
}
function onProgress(event) {
    progress.value = event.progress;
    status.text = event.ready ? 'Release to go back' : 'Pull up to go back';
}
function onTrigger() { window.close(); }
function onClose() {
    Ti.App.iOS.removeEventListener('traitcollectionchange', applyAppearance);
    window.removeEventListener('open', onOpen);
    window.removeEventListener('close', onClose);
    if (gesture) {
        gesture.removeEventListener('progress', onProgress);
        gesture.removeEventListener('trigger', onTrigger);
        gesture.detach();
        gesture = null;
    }
}
applyAppearance();
window.addEventListener('open', onOpen);
window.addEventListener('close', onClose);
window.open();
