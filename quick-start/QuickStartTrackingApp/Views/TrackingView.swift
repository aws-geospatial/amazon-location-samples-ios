import SwiftUI

struct TrackingView: View {
    @ObservedObject var trackingViewModel: TrackingViewModel
    var body: some View {
        ZStack(alignment: .bottom) {
            if trackingViewModel.mapSigningIntialised {
                MapView(trackingViewModel: trackingViewModel)
                VStack {
                    UserLocationView(trackingViewModel: trackingViewModel)
                    CenterAddressView(trackingViewModel: trackingViewModel)
                    TrackingBottomView(trackingViewModel: trackingViewModel)
                }
            }
            else {
                Text("Loading...") 
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

