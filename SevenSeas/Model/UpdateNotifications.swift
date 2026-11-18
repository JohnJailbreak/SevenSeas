//
//  UpdateNotifications.swift
//  SevenSeas
//
//  Settings > Update notifications: a notification when a new release is ready. Octopus's, which is Speaka's without
//  its launchd checker; SevenSeas is only an app.
//

import BackgroundTasks
import Foundation
import UserNotifications

/// Two ways a release is found, one rule: each release is announced once, whichever finds it first
/// (`UpdatePrefs.notifiedVersion`).
/// - The background check, when iOS chooses to run it: often hours apart, and never once SevenSeas was swiped away or
///   while Background App Refresh is off.
/// - While SevenSeas is open: every 2 minutes, and each time it comes to the front (`Updater.watch`).
///
/// A release is announced only while iOS allows SevenSeas' notifications, and counts as announced only once iOS has
/// accepted the request, so a release found while they're off is announced when they're back on. Tapping the
/// notification opens the update window.
enum UpdateNotifications {
    /// Listed in Info.plist under BGTaskSchedulerPermittedIdentifiers (project.yml).
    static let taskID = "sevenseas.update-check"
    /// While SevenSeas is open (`Updater.watch`). Each check is conditional, so an unchanged list costs nothing
    /// against GitHub's hourly limit.
    static let interval: TimeInterval = 120
    /// What SevenSeas asks iOS for in the background. iOS takes it as "not before", and decides.
    static let backgroundInterval: TimeInterval = 15 * 60

    /// Turning it on asks iOS for permission to notify first; if that's refused, it stays off. `completion` gets
    /// whether it ended up on, on the main thread.
    static func setEnabled(_ on: Bool, completion: @escaping (Bool) -> Void) {
        guard on else {
            UpdatePrefs.notificationsEnabled = false
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskID)
            DispatchQueue.main.async { completion(false) }
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                UpdatePrefs.notificationsEnabled = granted
                if granted { UpdateNotifications.schedule() }
                completion(granted)
            }
        }
    }

    /// iOS shows SevenSeas' notifications: authorized, provisional or ephemeral.
    static func shows(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    /// When SevenSeas comes to the front: notifications turned off in iOS Settings turn the switch off too.
    static func syncPermission() {
        guard UpdatePrefs.notificationsEnabled else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let allowed = UpdateNotifications.shows(settings.authorizationStatus)
            DispatchQueue.main.async {
                if !allowed { UpdatePrefs.notificationsEnabled = false }
            }
        }
    }

    /// Asks iOS to wake SevenSeas in the background in 15 minutes, or when it allows. If Background App Refresh is off
    /// for SevenSeas, or Low Power Mode is on, iOS refuses and only the checks while the app is open remain.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: backgroundInterval)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Refused for now; the next time SevenSeas goes to the background asks again.
        }
    }

    /// The background wake-up: the next one is asked for first, so one failed check doesn't end the chain.
    static func backgroundCheck() async {
        guard UpdatePrefs.notificationsEnabled else { return }
        schedule()
        await check()
    }

    /// One check: the newest release that carries the app, if it's newer than this app and wasn't announced, and only
    /// while iOS allows SevenSeas' notifications.
    static func check() async {
        let releases: [AppRelease]? = await withCheckedContinuation { continuation in
            Updater.fetchReleases { result in continuation.resume(returning: try? result.get()) }
        }
        guard let releases else { return }
        let app = Updater.versionParts(AppInfo.version)
        guard let newest = Updater.select(from: releases, app: app).available,
              UpdatePrefs.notifiedVersion != newest.name else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard shows(settings.authorizationStatus) else { return }   // kept for when they're allowed
        let content = UNMutableNotificationContent()
        content.title = "SevenSeas \(newest.name) is ready"
        content.body = "Tap to update."
        content.sound = .default
        let note = UNNotificationRequest(identifier: "update-\(newest.name)", content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(note)
            UpdatePrefs.notifiedVersion = newest.name   // only once iOS has accepted it
        } catch {
            // Not now: the next check tries again.
        }
    }
}

/// SevenSeas' notifications show as banners while it is open, and tapping an update notification opens the update
/// window. Installed at launch (`SevenSeasApp`), so a tap that launches the app isn't missed.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    static let openUpdate = Notification.Name("sevenseas.open-update")
    /// A tap that came before the main screen was up (it launched the app); the main screen takes it when it appears.
    static var openRequested = false

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier.hasPrefix("update-") {
            DispatchQueue.main.async {
                NotificationDelegate.openRequested = true
                NotificationCenter.default.post(name: NotificationDelegate.openUpdate, object: nil)
            }
        }
        completionHandler()
    }
}
