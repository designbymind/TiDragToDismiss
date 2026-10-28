var args = arguments[0] || {};
var light = Ti.UI.userInterfaceStyle === 1;
$.name.text = args.name;
$.message.text = args.message;
$.name.color = $.message.color = light ? '#111111' : '#EEEEEE';
