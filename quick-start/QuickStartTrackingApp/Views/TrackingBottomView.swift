import SwiftUI

struct TrackingBottomView: View {
    @ObservedObject var trackingViewModel: TrackingViewModel
    var body: some View {
           Button(action: {
               Task {
                   if(trackingViewModel.trackingButtonText == NSLocalizedString("StartTrackingLabel", comment: "")) {
                       try await trackingViewModel.startTracking()
                   } else {
                       trackingViewModel.stopTracking()
                   }
               }
           }) {
               HStack {
                   Spacer()
                   Text("Tracking")
                       .foregroundColor(trackingViewModel.trackingButtonColor)
                       .background(.white)
                       .cornerRadius(15.0)
                   
                   Image(systemName: trackingViewModel.trackingButtonIcon)
                       .resizable()
                       .frame(width: 24, height: 24)
                       .padding(5)
                       .background(.white)
                       .foregroundColor(trackingViewModel.trackingButtonColor)

               }
           }
           .accessibility(identifier: "TrackingButton")
           .background(.white)
           .clipShape(RoundedRectangle(cornerRadius: 8))
           .padding(.trailing, 10)
           .padding(.bottom, 40)
           .frame(width: 130, alignment: .trailing)
           .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
       }
}
