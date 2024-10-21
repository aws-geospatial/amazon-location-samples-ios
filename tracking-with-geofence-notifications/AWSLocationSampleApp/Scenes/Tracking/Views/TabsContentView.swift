import SwiftUI
import AmazonLocationiOSTrackingSDK

struct TabsContentView: View {
    @State private var selectedTab = "Config"
    @ObservedObject var authViewModel = AuthViewModel(apiKey: Config.apiKey, apiKeyRegion: Config.apiKeyRegion, identityPoolId: Config.identityPoolId, mapName: Config.mapName, trackerName: Config.trackerName, geofenceCollectionArn: Config.geofenceARN, websocketUrl: Config.websocketUrl)
    var body: some View {
        TabView(selection: $selectedTab) {
            AWSConnectionView(authViewModel: authViewModel)
                .tabItem {
                    Label("Config", systemImage: "gear")
                }
                .tag("Config")
            TrackingView(authViewModel: authViewModel)
                .tabItem {
                    Label("Tracking", systemImage: "location.fill")
                }
                .tag("Tracking")
        }
        .onAppear() {
            if !authViewModel.identityPoolId.isEmpty {
                Task {
                    try await authViewModel.authWithCognito(identityPoolId: authViewModel.identityPoolId)
                    if UserDefaultsHelper.get(for: Bool.self, key: .trackingActive) ?? false {
                        DispatchQueue.main.async {
                            selectedTab = "Tracking"
                        }
                        try await authViewModel.resumeTracking()
                    }
                    else {
                        DispatchQueue.main.async {
                            selectedTab = "Config"
                        }
                    }
                }
            }
        }
    }
}
