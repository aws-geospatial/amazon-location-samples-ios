import SwiftUI
import AmazonLocationiOSTrackingSDK
import AmazonLocationiOSAuthSDK

struct TrackingView: View {
    @ObservedObject var authViewModel: AuthViewModel
    var body: some View {
        ZStack(alignment: .bottom) {
            if authViewModel.clientIntialised {
               let mapView = MapView(authViewModel: authViewModel)
                mapView
                    .onAppear() {
                        let regionName = AmazonLocationRegion.toRegionString(identityPoolId: authViewModel.identityPoolId)
                        let styleName = "Standard"
                        let colorScheme = "Light"
                        let styleURL = URL(string: "https://maps.geo.\(regionName).amazonaws.com/v2/styles/\(styleName)/descriptor?key=\(authViewModel.apiKey)&color-scheme=\(colorScheme)")
                        mapView.mlnMapView?.styleURL = styleURL
                    }
                TrackingBottomView(authViewModel: authViewModel)
            }
            else {
                Text(NSLocalizedString("EnterConfiguration", comment: ""))
            }
        }
    }
}
