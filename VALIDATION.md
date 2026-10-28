# Validation — 0.2.1

The first public release contains the pull-up gesture coordinator, configurable
SF Symbols, runtime indicator colors, and Classic/Alloy examples. Validation
uses Titanium SDK 13.4.1.GA and Xcode 27.1 beta (27A9269), with an iOS 26.0 minimum
deployment target.

## Native checks

`validation/NativeChecks.m` compiles the production UIKit coordinator and indicator
sources. The suite contains 40 checks covering:

- Reveal/fill thresholds, progress reversal, readiness, cancellation, and
  exactly-once release triggers.
- Release ordering: after a ready pull at 122 points, a UIKit spring-back update
  to 117 points before the release target must not cancel the trigger. Reversing
  to 117 points while still dragging must cancel it.
- Exclusion of far-from-bottom flings and post-release momentum.
- Short content, adjusted insets, enable/disable behavior, duplicate attachment
  rejection, idempotent detach, reattachment, and window-removal cleanup.
- SF Symbol sizing and all supported weights, input validation, intrinsic layout,
  and visible pixel differences between regular and bold symbols.
- Immediate color repaint while stationary/armed, restoring automatic colors,
  and light/dark trait changes without another progress update.

The 40-check suite passed on an iPhone 17 Pro / iOS 26.5 simulator. Rendered symbol
and color previews were also inspected. The checks synthesize recognizer states;
they are not physical-touch, haptic, or accessibility interaction proof.

To reproduce with a booted arm64 simulator:

```sh
DEVELOPER_DIR="<Xcode.app>/Contents/Developer" \
  ./validation/run-native-checks.sh <booted-simulator-UDID>
```

The runner writes `validation/native-checks.json`, `symbol-preview.png`, and
`color-preview.png`. These are generated outputs and are excluded from Git.

## Consumer examples

AlloyTestApp was built against app-local 0.2.1. The packaged Alloy example also
includes its own entry point and utility styles for a fresh application, without
PurgeTSS or unrelated native modules. JavaScript syntax, Alloy XML, and standalone
Alloy compilation are checked before publication.

Initial live Titanium simulator interaction demonstrated progress 1 and
trigger-controlled navigation pops. Physical-device gesture feel, near-threshold
releases, haptics, accessibility, and exhaustive runtime theme/icon changes remain
to be verified. TableView is the consumer integration target; ListView and
vertical ScrollView share the adapter but do not have separate interaction tests.

## Release artifact

The release ZIP is rebuilt from the exact source commit identified by
`iOS-v0.2.1`. Package checks cover ZIP integrity, the embedded manifest/version,
and the XCFramework's actual arm64 device and arm64/x86_64 simulator libraries.
The uploaded GitHub asset is compared with the local ZIP by SHA-256. Generated
binaries and build directories are not committed to the source repository.

No Lottie renderer/asset is bundled or runtime-tested. The custom indicator API
provides a Titanium view host and progress events for a separate renderer.
