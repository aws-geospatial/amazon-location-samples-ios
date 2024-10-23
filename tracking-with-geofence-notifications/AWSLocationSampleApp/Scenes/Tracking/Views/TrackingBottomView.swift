import SwiftUI

struct TrackingBottomView: View {
    @ObservedObject var authViewModel: AuthViewModel
    var body: some View {
           HStack {
               Text("Tracking points")
                   .frame(maxWidth: .infinity, alignment: .leading)
                   .foregroundColor(Color.primary)

               Button(action: {
                   if(authViewModel.trackingButtonText == "Start Tracking") {
                       Task {
                           try await authViewModel.startTracking()
                       }
                   } else {
                       authViewModel.stopTracking()
                   }
               }) {
                   Text(authViewModel.trackingButtonText)
                       .font(.headline)
                       .foregroundColor(.white)
                       .padding()
                       .background(authViewModel.trackingButtonColor)
                       .cornerRadius(15.0)
               }
               .accessibility(identifier: "TrackingButton")
           }
           .frame(maxWidth: 400)
           .padding()
           .overlay(
               RoundedRectangle(cornerRadius: 10)
                   .stroke(Color.blue, lineWidth: 2)
           )
           .clipShape(RoundedRectangle(cornerRadius: 10))
           .background(Color(UIColor.systemBackground)) // Use system background color for adaptability
           .edgesIgnoringSafeArea(.bottom)
       }
}
