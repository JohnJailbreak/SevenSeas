# Updates

SevenSeas checks GitHub for a newer release, shows its changelog and hands it to TrollStore. This is Octopus's updater
(`Octopus/App/Updater.swift`), which is Speaka's and Caz's, which follow Dopamine's. Dopamine is MIT licensed; see
[NOTICE](../NOTICE.md).

| Where | What it does |
|---|---|
| `Model/Updater.swift` | Checking, release selection, version comparison, the TrollStore hand-off, stored preferences |
| `Model/UpdateNotifications.swift` | The background check and the notification, with its delegate |
| `Views/UpdateViews.swift` | `UpdateLinkButton` and the changelog window |

## What the person sees

1. **Update Available** appears on the main screen, in the slot Dopamine uses for the same row, 20 pt above the big
   button. A paused hotspot is more urgent, so while sharing is paused the "Upstream Wi-Fi Lost" notice takes that slot
   and the update waits.
2. Tapping it opens the **changelog**: every release newer than this app, newest first, each with its name in bold
   18 pt and its notes at 16 pt, under the same fade mask Dopamine uses. It is drawn in the window frame with no card
   behind it, only the dimmed backdrop.
3. **Update** hands the release's `.tipa` link to TrollStore, which downloads and installs it.
4. **Settings → Update Notifications** turns on a notification when a release appears, and **Check for Updates** runs a
   check now, with a line underneath saying what it found or when the last check was.

## How checking works

The release list comes from `https://api.github.com/repos/JohnJailbreak/SevenSeas/releases`, unauthenticated, which
GitHub limits to 60 requests an hour per address. Three things keep SevenSeas well inside that:

- The answer's **ETag** is sent back as `If-None-Match`. An unchanged list returns 304, which GitHub does not count,
  and the copy held in memory is used.
- One check per launch, unless something asks for a fresh one.
- Coming back to the front re-checks, but not if an answer arrived in the last 20 seconds.

Drafts and pre-releases are skipped. A release counts only if its tag contains numbers (`v1.0.7` → `[1, 0, 7]`), and
versions compare element by element, so `1.0.10` is newer than `1.0.9` and `[1, 0]` equals `[1, 0, 0]`. The release
offered is the newest one carrying a `.tipa`, or an `.ipa` if it has no `.tipa`, and only if it is newer than
`CFBundleShortVersionString`. A failure is reported in words the person can act on: offline, GitHub didn't answer,
GitHub couldn't be reached, or the hourly limit with the time it resets.

Because CI sets the version to `1.0.<run number>`, a build made locally reports `1.0` and will offer any published
release as an update. That is correct, not a bug.

## Notifications

Two things can find a release, and each release is announced once, by whichever finds it first:

- the background check, when iOS chooses to run it, which it will not do if Background App Refresh is off for
  SevenSeas, if Low Power Mode is on, or once the app has been swiped away; and
- a check every two minutes while the app is open.

A release counts as announced only once iOS has accepted the request, so one found while notifications are off is
announced when they come back on. Turning the switch on asks iOS for permission first and stays off if refused, with a
line pointing at Settings → Notifications. Turning notifications off in iOS Settings turns the switch off the next time
SevenSeas comes to the front. Tapping a notification opens the changelog, including when the tap launched the app.

`project.yml` carries the two keys this needs: `BGTaskSchedulerPermittedIdentifiers` (`sevenseas.update-check`) and
`UIBackgroundModes: fetch`.

## What differs from Octopus

Octopus downloads the `.tipa` itself, writes it outside its own data folder and has its **root helper** run TrollStore's
installer on the local file, showing a progress circle while it does. SevenSeas has no root helper and no entitlements,
so `Updater.install()` opens `apple-magnifier://install?url=…` and TrollStore does the downloading. Consequences:

- There is no download progress screen, because SevenSeas never downloads the file.
- If TrollStore is not installed, the releases page opens instead.
- `install()` is the one place to change when a privileged helper exists: download the asset, then have the helper run
  the installer, and bring back Octopus's `DownloadView`.

## Not verified

The check, the parsing and the version comparison are ordinary code and are covered by Octopus's own tests, which were
read while porting but not ported (this repository has no test target). **Nothing in this flow has been run on a
device from this repository.** In particular the TrollStore hand-off, the background wake-up and the notification
permission flow have not been exercised here.
