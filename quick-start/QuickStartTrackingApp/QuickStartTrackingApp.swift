import SwiftUI

@main
struct QuickStartTrackingAppApp: App {
    init() {
        // Check for "testing" launch argument
        if CommandLine.arguments.contains("testing") {
            // Clear UserDefaults
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()
        }
    }
    @ObservedObject var trackingViewModel = TrackingViewModel(region: Config.region, mapName: Config.mapName, indexName: Config.indexName, identityPoolId: Config.identityPoolId, trackerName: Config.trackerName)
    var body: some Scene {
        WindowGroup {
            TrackingView(trackingViewModel: trackingViewModel)
        }
    }
}
