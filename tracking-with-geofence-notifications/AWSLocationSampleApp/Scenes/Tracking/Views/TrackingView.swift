import SwiftUI
import AmazonLocationiOSTrackingSDK

struct TrackingView: View {
    @ObservedObject var authViewModel: AuthViewModel
    var body: some View {
        ZStack(alignment: .bottom) {
            if authViewModel.clientIntialised {
                MapView(authViewModel: authViewModel)
                TrackingBottomView(authViewModel: authViewModel)
            }
            else {
                Text(NSLocalizedString("EnterConfiguration", comment: ""))
            }
        }
    }
}
