# SevenSeas

Wi-Fi to Wi-Fi hotspot for a jailbroken iPhone (Dopamine, rootless). This repository holds the **frontend**: all ten screens, built on Dopamine's interface, running on simulated data. Nothing here touches the radio yet.

The screens: Home (ready, sharing, upstream lost), Starting Hotspot (the log), Select Security, Settings, Theme, Devices, Status and About. The ten Morning Haze backgrounds and the Lighthouse Beam icon are included.

## Builds

Every push, on any branch, runs `.github/workflows/build.yml` on a macOS runner and produces `SevenSeas.ipa` and `SevenSeas.tipa` (the same file, signed with the entitlements in `entitlements.plist` via `ldid`).

* **Any commit:** open the run under the **Actions** tab, then **Artifacts** at the bottom.
* **Default branch:** the run also publishes a **Release** named `1.0.<run number>` with both files and `SHA256SUMS`. The notes are the first line of each commit message in the push.

The version is `1.0` plus the run number; the build number is the run number. Change the `1.0` in `project.yml` (`MARKETING_VERSION`).

If a build fails, the run prints the compiler errors in the **Show compiler errors** step and uploads the full `build.log`.

## Installing

Open `SevenSeas.tipa` (or the `.ipa`) in TrollStore on the phone.

## Layout

```
.github/workflows/build.yml   CI: XcodeGen, xcodebuild, ldid, release
project.yml                   XcodeGen project (bundle id, version, iOS 16.0+)
entitlements.plist            applied by ldid after the build
SevenSeas/
  App/        entry point, app info and license text
  Model/      AppModel (all state), settings, devices, theme table
  Support/    layout maths from Dopamine, colours, animation curves, blur
  Views/      main screen: header, menu, expanding button, log, picker
  Panels/     Settings, Devices, Status and their pushed pages
  Resources/  asset catalog: icon, 10 backgrounds, thumbnails, wordmark
```

## Connecting the real service

`SevenSeas/Model/AppModel.swift` is the only place that simulates behaviour. The views read its published properties and call a handful of methods:

| What | Where |
| --- | --- |
| Start sequence and its log lines | `runStartSequence` |
| Stop | `stopSharing` |
| Upstream lost and regained | `applyUpstreamSimulation`, `simulateUpstreamLoss` |
| Connected devices | `devices`, `liveDevices` |
| Upstream name, band, signal, data used | `upstreamName`, `upstreamBand`, `signal`, `dataUsed` |
| Saved settings | `settings` (stored in `UserDefaults`) |

The **Preview controls** group at the bottom of Settings can be deleted once the service is real.

## Customising

* Bundle id: `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml`.
* Name under the wordmark: `AppInfo.author`.
* Themes: `Model/Theme.swift` (Dopamine's `Themes.plist` fields) plus a matching `Backgrounds` and `Thumbs` image set.
* Entitlements: `entitlements.plist`.

## Credits

The interface follows [Dopamine](https://github.com/opa334/Dopamine) by Lars Fröder (opa334), MIT licensed, and reuses its loading arc image. See `NOTICE.md`. The wordmark and the WPA labels are rendered from the Fonarto typeface by LOCOMOTYPE; only the rendered images are in this repository.
