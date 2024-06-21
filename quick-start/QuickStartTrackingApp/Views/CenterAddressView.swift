import SwiftUI

struct CenterAddressView: View {
    @ObservedObject var trackingViewModel: TrackingViewModel
    var body: some View {
        Text(trackingViewModel.centerLabel)
            .font(.caption)
            .foregroundColor(.black)
            .padding(5)
            .frame(width: 300)
            .background(.white)
            .accessibilityIdentifier("CenterAddressLabel")
    }
}

