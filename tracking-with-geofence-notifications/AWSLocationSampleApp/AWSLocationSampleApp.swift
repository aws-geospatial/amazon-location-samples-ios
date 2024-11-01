import SwiftUI

@main
struct AWSLocationSampleApp: App {
    init() {
        // Check for "testing" launch argument
        if CommandLine.arguments.contains("testing") {
            // Clear UserDefaults
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()
        }
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            // Handle the response
        }
        
        // Set the notification center's delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    var body: some Scene {
        WindowGroup {
            TabsContentView()
        }
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    @MainActor static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Present the notification while the app is in the foreground
        completionHandler([.banner, .sound])
    }
}
