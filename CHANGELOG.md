# Changelog

## 0.2.1 — First public release

- Pull upward near the bottom of a Titanium TableView and release when armed to
  emit `trigger`; the application owns the pop/close action.
- Reversible progress events, cancellation, configurable threshold/reveal distance,
  short-content support, animated ring/arrow, and optional haptics.
- Local image icons and SF Symbols with optional point size and weight.
- Runtime `icon`, `enabled`, and `indicatorColor` updates. `indicatorColor: null`
  uses automatic light/dark color; assignments repaint immediately.
- Release decisions preserve the last finger-driven ready state, preventing
  spring-back from cancelling an already armed release.
- Classic and Alloy examples, including a configurable footer ProgressBar/label
  with reversible fade and upward movement.
- Custom Titanium indicator views and progress-driven animation integration.
  A Lottie renderer/asset is not bundled.

Requires iOS 26+ and Titanium SDK 13.4.1+. iOS only.

## Development history

Versions 0.1.0 through 0.2.0 were local development builds; this repository's first
published release is 0.2.1. Native simulator checks and rendering previews are
separate from physical-device gesture/haptic validation.
