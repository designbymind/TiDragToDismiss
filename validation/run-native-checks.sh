#!/bin/bash
set -euo pipefail
: "${DEVELOPER_DIR:?Set DEVELOPER_DIR to the selected Xcode Contents/Developer path}"
: "${1:?Pass a booted simulator UDID}"
DTD_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DTD_APP="$DTD_ROOT/validation/build/NativeChecks.app"
DTD_SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
mkdir -p "$DTD_APP"
python3 - "$DTD_APP/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], 'wb') as file:
    plistlib.dump({
        'CFBundleIdentifier': 'com.designbymind.DTDNativeChecks',
        'CFBundleExecutable': 'NativeChecks', 'CFBundleName': 'NativeChecks',
        'CFBundlePackageType': 'APPL', 'CFBundleVersion': '1',
        'CFBundleShortVersionString': '1.0', 'MinimumOSVersion': '26.0',
        'LSRequiresIPhoneOS': True, 'UILaunchScreen': {},
        'UIApplicationSceneManifest': {'UIApplicationSupportsMultipleScenes': False}
    }, file)
PY
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules \
  -fmodules-cache-path="$DTD_ROOT/validation/build/ModuleCache" \
  -target arm64-apple-ios26.0-simulator -isysroot "$DTD_SDK" \
  -I "$DTD_ROOT/ios/Classes" -framework UIKit -framework Foundation -framework QuartzCore \
  "$DTD_ROOT/validation/NativeChecks.m" "$DTD_ROOT/ios/Classes/DTDCoordinator.m" \
  "$DTD_ROOT/ios/Classes/DTDIndicatorView.m" -o "$DTD_APP/NativeChecks"
codesign --force --sign - "$DTD_APP"
xcrun simctl install "$1" "$DTD_APP"
xcrun simctl terminate "$1" com.designbymind.DTDNativeChecks >/dev/null 2>&1 || true
DTD_DATA="$(xcrun simctl get_app_container "$1" com.designbymind.DTDNativeChecks data)"
python3 - "$DTD_DATA/Documents/checks.json" <<'PY_CLEAR'
import pathlib, sys
pathlib.Path(sys.argv[1]).unlink(missing_ok=True)
PY_CLEAR
xcrun simctl launch "$1" com.designbymind.DTDNativeChecks
python3 - "$DTD_DATA/Documents/checks.json" "$DTD_ROOT/validation/native-checks.json" <<'PY'
import json, pathlib, sys, time
source, target = map(pathlib.Path, sys.argv[1:])
for _ in range(40):
    if source.exists():
        data = json.loads(source.read_text())
        target.write_text(json.dumps(data, indent=2) + '\n')
        preview = source.with_name('symbol-preview.png')
        if preview.exists():
            target.with_name('symbol-preview.png').write_bytes(preview.read_bytes())
        color_preview = source.with_name('color-preview.png')
        if color_preview.exists():
            target.with_name('color-preview.png').write_bytes(color_preview.read_bytes())
        failures = [item for item in data if not item['passed']]
        print(f"{len(data) - len(failures)}/{len(data)} native coordinator checks passed")
        if failures:
            print(json.dumps(failures, indent=2))
            sys.exit(1)
        break
    time.sleep(0.25)
else:
    raise SystemExit('Native checks did not write results; inspect simulator logs')
PY
