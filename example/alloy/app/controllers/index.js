var component = null;

function openExamples() {
    if (component) return;
    component = Alloy.createController('dragtodismiss/index', {
        onClose: function () { component = null; }
    });
}
$.index.open();
