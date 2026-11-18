import SwiftUI
import UserNotifications

@main
struct SevenSeasApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var updater = Updater()

    init() {
        // Banners while SevenSeas is open, and a tap on an update notification opens the update window.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(updater)
                .preferredColorScheme(.dark)
        }
        // Settings > Update notifications: iOS wakes SevenSeas in the background when it chooses.
        .backgroundTask(.appRefresh(UpdateNotifications.taskID)) {
            await UpdateNotifications.backgroundCheck()
        }
    }
}
