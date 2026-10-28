# Alloy example

Use a fresh Alloy application with Titanium SDK 13.4.1 or later and an iOS
minimum deployment target of 26.0 or later.

1. Copy this directory's `app/` contents into the new application's `app/`.
2. Extract `ti.dragtodismiss-iphone-0.2.1.zip` into the application root. Its
   archive layout creates `modules/iphone/ti.dragtodismiss/0.2.1/`.
3. Add `<module platform="iphone" version="0.2.1">ti.dragtodismiss</module>`
   inside the application's `<modules>` element in `tiapp.xml`.
4. Set `<min-ios-ver>26.0</min-ios-ver>` inside `<ios>` and build for iOS.
5. Tap **Open Drag to Dismiss examples**, then select a variation.

This example includes its utility styles in `app/styles/app.tss`; it does not
require PurgeTSS or any other native module. For an existing application, merge
those styles and the `dragtodismiss/` controllers/views/styles rather than
replacing the application's entry point or global stylesheet.

## Variations

- Default ring and rotating arrow.
- SF Symbol at 24 points / bold, with runtime color updates for light/dark mode.
- Local image icon.
- Custom percentage indicator driven by the progress event.
- Short TableView that still supports pulling past the bottom.
- TableView footer ProgressBar and label, with reversible fade/translation.

The examples use `revealDistance: 1` so filling starts immediately after the
bottom edge. The module's default remains 50 points; `threshold` is 120 points.

## Configure the footer

Edit `footerOptions` in `app/controllers/dragtodismiss/index.js`:

```js
var footerOptions = {
    pullText: 'Pull up to go back',
    releaseText: 'Release to go back',
    labelFade: true,
    labelTravel: 8,
    progressBar: { tintColor: '#007AFF', trackTintColor: '#E5E5EA' },
    label: { color: '#333333', font: { fontSize: 14 }, textAlign: 'center' },
    view: { height: 96 }
};
```

The label sits below the ProgressBar. At progress 0 it is transparent and 8
points below its resting position; at 1 it is visible and reads the release
prompt. Reversing the drag reverses the presentation and restores the pull
prompt using native `event.ready`. Set `labelFade: false` or `labelTravel: 0`
to disable the respective effect. Layout defaults live in `footer.tss`.

The controller owns navigation and closes the child window only on `trigger`.
On close it removes listeners, detaches the native gesture, and releases its
child controllers. Haptics and gesture feel should also be checked on a device.
