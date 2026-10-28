# TiDragToDismiss

`ti.dragtodismiss` **0.2.1** · Titanium SDK 13.4.1+ · **iOS 26+** · UIKit · MIT

Pull upward near the bottom of an existing Titanium TableView, fill the indicator,
and release to emit `trigger`. Your controller owns navigation and chooses whether
to pop, close, or perform another action. The module never closes a window itself.

The default presentation follows the pull-up interaction in Kavsoft's
ThreadsDismiss sample: a 55-point circular indicator reveals over the
first 50 points of bottom overscroll; two arcs fill, the chevron turns toward the
back direction, the circle fills at the threshold, and selection haptics mark
readiness. It is an independent UIKit implementation; no supplied Swift source
is bundled or linked. No SwiftUI or third-party runtime dependency is required.

## Installation

Download `ti.dragtodismiss-iphone-0.2.1.zip` from the
[0.2.1 release](https://github.com/designbymind/TiDragToDismiss/releases/tag/iOS-v0.2.1).
Extract it into your Titanium application root; the ZIP creates
`modules/iphone/ti.dragtodismiss/0.2.1/`. Add the module entry shown below and use
an iOS minimum deployment target of 26.0 or later. Clean/rebuild the application
when replacing an existing native module installation.

For a fresh Alloy app, see the [complete Alloy example](https://github.com/designbymind/TiDragToDismiss/blob/iOS-v0.2.1/example/alloy/README.md).
For a Classic app, use [example/app.js](https://github.com/designbymind/TiDragToDismiss/blob/iOS-v0.2.1/example/app.js). The examples have no
other native module or PurgeTSS dependency.

## Quick start

Add `<module platform="iphone" version="0.2.1">ti.dragtodismiss</module>`
to `tiapp.xml` and use an app with an iOS deployment target of at least 26.0.

```js
var DragToDismiss = require('ti.dragtodismiss');
var gesture;
function onOpen() {
    gesture = DragToDismiss.createGesture({
        scrollView: $.table,
        threshold: 120,
        revealDistance: 1, // Begin filling immediately past the bottom edge.
        icon: { systemImage: 'chevron.down' }
    });
    gesture.addEventListener('progress', onProgress);
    gesture.addEventListener('trigger', onTrigger);
}
function onProgress(event) {
    $.progressBar.value = event.progress;
}
function onTrigger() {
    // For a child window in a NavigationWindow:
    navigation.closeWindow($.window);
    // For a standalone/modal window, use its normal close method instead.
}
function onClose() {
    if (!gesture) return;
    gesture.removeEventListener('progress', onProgress);
    gesture.removeEventListener('trigger', onTrigger);
    gesture.detach();
    gesture = null;
}
```

Wire `onOpen` / `onClose` to your Window events and supply your application's
NavigationWindow reference in the example above. Create the gesture in the window's `open` handler, after the native scrolling view
is attached. Keep the returned proxy in controller scope until cleanup. Only one
gesture may attach to a given native scroll view. A detached gesture is terminal;
create a fresh gesture when opening another screen.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `scrollView` | required | Existing Titanium TableView; ListView and vertical ScrollView use the same underlying UIScrollView adapter but need their own interaction testing. |
| `threshold` | `120` | Actual overscroll in points needed to arm; finite and greater than `revealDistance`. Finger travel is longer because UIKit applies rubber-banding. |
| `revealDistance` | `50` | Initial pull distance used to reveal the indicator before the ring starts filling; at least 1. |
| `activationDistance` | `threshold * 1.2` | Maximum distance above the bottom where a drag may begin. Use `0` to require starting at the bottom. |
| `icon` | default chevron | `{ systemImage: 'arrow.uturn.backward', size: 24, weight: 'bold' }`, local image path, or Titanium Blob. `null` restores the default. Remote URLs are rejected. |
| `rotatesIcon` | `true` | Rotate the icon through 90 degrees with progress. Set false for an already oriented back arrow. |
| `indicatorColor` | semantic label color | Native ring/fill and template symbol color; filled-state symbol uses semantic background color. Local image colors/alpha are preserved. |
| `indicatorSize` | `55` | Indicator diameter in points; at least 20. |
| `bottomSpacing` | `12` | Additional spacing above the scroll view's adjusted bottom inset / safe area. |
| `haptics` | `true` | Selection feedback each time an active pull crosses into ready. |
| `enabled` | `true` | Enable or suspend gesture behavior. |
| `indicatorView` | none | Unattached Titanium View replacing the built-in ring/icon, mounted in the indicator's square bounds. Keep the view's dimensions equal to `indicatorSize`. |

Set options at creation. `gesture.enabled`, `gesture.icon`, and `gesture.indicatorColor` also support runtime
updates. `gesture.progress` and `gesture.attached` are read-only.

## Runtime indicator color

```js
gesture.indicatorColor = '#007AFF';
// Return to the automatic system label color (adapts to light/dark appearance):
gesture.indicatorColor = null;
```

As of 0.2.1, creation options and runtime assignments use the same native setter.
A color assignment repaints the current ring, fill, and unarmed template symbol
immediately, including while stationary. Read `gesture.indicatorColor` to get the
assigned value (`null` for automatic). At full progress, the symbol retains its
semantic background-color tint against the colored fill. Local image colors are
preserved; custom `indicatorView` and Alloy footer colors are owned by your views.

If you assign an explicit color for each appearance, update it from
`Ti.App.iOS`'s `traitcollectionchange` event and remove that listener on close.
The AlloyTestApp SF Symbol example demonstrates that pattern. Automatic color
requires no JavaScript appearance listener.

## SF Symbol size and weight

```js
var gesture = DragToDismiss.createGesture({
    scrollView: $.table,
    icon: { systemImage: 'arrow.uturn.backward', size: 24, weight: 'bold' },
    rotatesIcon: false
});

// The same options work when replacing an icon at runtime:
gesture.icon = { systemImage: 'chevron.down', size: 28, weight: 'semibold' };
```

`size` is UIKit's symbol point size (a finite number >= 1), rather than a forced
square bitmap dimension. Explicitly sized symbols use their configured glyph
bounds, so they are not shrunk into the default icon box. Increase `indicatorSize`
if you choose a large symbol and want more room inside the ring.

Supported weights: `ultraLight`, `thin`, `light`, `regular`, `medium`, `semibold`,
`bold`, `heavy`, and `black` (case-insensitive). Size and weight are independently
optional. Omitting size retains the existing indicator-relative icon box;
omitting weight retains the system weight. Invalid values throw an argument
error. Local image/Blob rendering and `icon: null` keep their existing behavior.

## Events

`progress`: `{ progress, distance, ready, dragging, eligible }`

- `progress` is clamped to **0–1**. It matches ring fill:
  `clamp((distance - revealDistance) / (threshold - revealDistance), 0, 1)`.
- Progress moves in both directions with the finger and recedes to zero during
  bounce-back after an incomplete pull. It remains zero during the initial reveal.
- `distance` is bottom overscroll in points; it can exceed `threshold`.
- `ready` is true at 1. Dragging down below 1 disarms the gesture.
- `eligible` records whether the current drag started near the bottom.
- Events follow native geometry changes; expect frequent callbacks and keep
  JavaScript work small. Changes in dragging/eligibility also emit an event.

`trigger`: `{ progress: 1, distance, threshold }`

Fires once per qualifying release. Crossing 1 while still holding does not fire.
Cancellation, releases below 1, and flings that began far above the bottom do not
fire. Deceleration cannot increase progress or cause a trigger.

As of 0.1.1, the release decision uses the last finger-driven progress sample.
Geometry updates after the pan enters its ended/cancelled state cannot replace
that sample before the release target runs. This prevents UIKit spring-back from
cancelling a release that was displayed as ready. Deliberate reversal below the
threshold while the finger is still dragging continues to disarm immediately.
The Alloy footer uses the event's `ready` field for its release prompt.

## Footer ProgressBar example

The [Alloy demo](https://github.com/designbymind/TiDragToDismiss/blob/iOS-v0.2.1/example/alloy/README.md) includes six variations: default ring,
SF Symbol, local image, custom percentage view, short table, and a TableView
footer ProgressBar with a label underneath. Its controller updates both header
and footer from `event.progress` and uses native `event.ready` for the release
prompt. The built-in ring is replaced with an empty indicator in the footer
variation so the footer is the pull indicator.

Configure the footer through `footerOptions` in the example's
`app/controllers/dragtodismiss/index.js`:

```js
{
    pullText: 'Pull up to go back',
    releaseText: 'Release to go back',
    labelFade: true,
    labelTravel: 8,
    progressBar: { tintColor: '#007AFF', trackTintColor: '#E5E5EA' },
    label: { color: '#333333', font: { fontSize: 14 }, textAlign: 'center' },
    view: { height: 96 }
}
```

Label opacity follows progress from 0 to 1, and its position rises by
`labelTravel` points. Both effects reverse when pulling back. `labelFade: false`
and `labelTravel: 0` disable the respective effects. Styles and layout defaults
are in the footer's Alloy XML/TSS; these options belong to the example component,
not to the native gesture factory. The module's default `revealDistance` is 50;
the examples use 1 point for an earlier start.

## Custom indicators and Lottie

Pass an unattached animation view as `indicatorView`; map `event.progress` onto its
progress/frame setter. This scrubs forward and backward instead of starting a
loop. For a renderer with `N` frames, the frame is
`Math.round(event.progress * (N - 1))`.

Airbnb Lottie iOS exposes [`LottieAnimationView.currentProgress`](https://github.com/airbnb/lottie-ios/blob/master/Sources/Public/Animation/LottieAnimationView.swift) for this purpose.

A Titanium Lottie wrapper must expose progress or frame seeking for JavaScript to
drive it. This module does **not** bundle a Lottie renderer, claim compatibility
with an untested wrapper, or load `.json` / `.lottie` files itself. The Alloy demo
uses a percentage view to exercise the custom indicator path without adding a
dependency. A Lottie-specific adapter can be added once a renderer and animation
asset are selected.

## Lifecycle and interaction

The coordinator adds a target to the existing pan recognizer and observes scroll
geometry. It does not replace the scroll delegate, add a competing recognizer,
modify rows, change content insets, or intercept touches. Insets and short content
are included in the bottom-boundary calculation. Attachment enables `bounces`
and `alwaysBounceVertical` so short tables can pull; disabling/detaching restores
the values captured at attachment. Avoid changing those properties independently
while attached.

Call `detach()` on close. Cleanup is idempotent and also occurs if the indicator's
host leaves its window. Remove JavaScript listeners and release controller-owned
views/references as usual. Custom indicator interaction is disabled by its native
container. The default animation respects Reduce Motion; retain the standard
Back button as the accessible alternative to the gesture.

## Examples and validation

- `example/app.js`: standalone Classic TableView and trigger-controlled close.
- `example/alloy/`: matching Alloy component sources, also integrated into
  AlloyTestApp under **Components → Drag to Dismiss**; the packaged copy also
  includes a starter controller and the small set of styles it needs.
- `validation/NativeChecks.m`: deterministic UIKit coordinator checks using
  synthesized recognizer states. These are not real touch or haptic validation.
- `VALIDATION.md`: toolchain, binary/package checks, consumer results, and remaining
  device interaction checks.

Build with a compatible installed Xcode and an explicit module directory:

```sh
DEVELOPER_DIR="<Xcode.app>/Contents/Developer" ti build -p ios --build-only \
  --project-dir ios --sdk 13.4.1.GA --no-prompt --no-banner
```

The ZIP is kept at `ios/dist/ti.dragtodismiss-iphone-0.2.1.zip`.
The distribution contains arm64 device and arm64/x86_64 simulator libraries.
See [VALIDATION.md](https://github.com/designbymind/TiDragToDismiss/blob/iOS-v0.2.1/VALIDATION.md) for evidence and remaining device checks, and
[CHANGELOG.md](https://github.com/designbymind/TiDragToDismiss/blob/iOS-v0.2.1/CHANGELOG.md) for the first public release contents.
