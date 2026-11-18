#!/bin/bash
# Signs SevenSeas.app with entitlements.plist and zips SevenSeas.tipa, the same file as SevenSeas.ipa, and
# SHA256SUMS, as Caz, Speaka and Octopus do. Run it after building for device into build/DerivedData
# (see .github/workflows/main.yml). Needs macOS with Xcode and ldid (brew install ldid).
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/DerivedData/Build/Products/Release-iphoneos/SevenSeas.app"
[ -d "$APP" ] || { echo "SevenSeas.app not found at $APP"; exit 1; }

# A device build carries Xcode's signature; TrollStore wants ldid's, so the old one goes first.
rm -rf "$APP/_CodeSignature" "$APP/embedded.mobileprovision"
ldid -Sentitlements.plist "$APP/SevenSeas"
chmod 755 "$APP/SevenSeas"

rm -rf build/package build/SevenSeas.tipa build/SevenSeas.ipa
mkdir -p build/package/Payload
cp -R "$APP" build/package/Payload/
(cd build/package && zip -qry ../SevenSeas.tipa Payload)
cp build/SevenSeas.tipa build/SevenSeas.ipa   # the same file; some tools only open .ipa
(cd build && shasum -a 256 SevenSeas.tipa SevenSeas.ipa > SHA256SUMS)
echo "Built build/SevenSeas.tipa and build/SevenSeas.ipa ($(du -h build/SevenSeas.tipa | cut -f1))"
