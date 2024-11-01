import SwiftUI

struct TrackingView: View {
    @ObservedObject var trackingViewModel: TrackingViewModel
    var body: some View {
        ZStack(alignment: .bottom) {
            MapView(trackingViewModel: trackingViewModel)
            VStack {
                UserLocationView(trackingViewModel: trackingViewModel)
                CenterAddressView(trackingViewModel: trackingViewModel)
                TrackingBottomView(trackingViewModel: trackingViewModel)
            }
        }
        .alert(isPresented: $trackingViewModel.showAlert) {
            Alert(
                title: Text(trackingViewModel.alertTitle),
                message: Text(trackingViewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear() {
            Task {
                do {
                    try await trackingViewModel.initializeGeoPlacesClient()
                }
                catch {
                    trackingViewModel.showErrorAlertPopup(title: "Error", message: "Error in authentication with API key: \(error.localizedDescription)")
                }
            }

            if !trackingViewModel.identityPoolId.isEmpty {
                Task {
                    do {
                        try await trackingViewModel.authWithCognito(identityPoolId: trackingViewModel.identityPoolId)
                    }
                    catch {
                        trackingViewModel.showErrorAlertPopup(title: "Error", message: "Error in authentication with cognito: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

