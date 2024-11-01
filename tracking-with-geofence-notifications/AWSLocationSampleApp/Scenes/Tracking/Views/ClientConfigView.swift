import SwiftUI

struct ClientConfigView: View {
    @Binding var isPresented: Bool
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Text("API Key")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                TextField("API Key", text: $authViewModel.apiKey)
                    .accessibility(identifier: "ApiKey")
                
                Text("API Key Region")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                TextField("API Key Region", text: $authViewModel.apiKeyRegion)
                    .accessibility(identifier: "ApiKeyRegion")
                
                Text("Identity Pool ID")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                TextField("Identity Pool ID", text: $authViewModel.identityPoolId)
                    .accessibility(identifier: "IdentityPoolID")
                
                Text("Tracker Name")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                TextField("Tracker Name", text: $authViewModel.trackerName).accessibility(identifier: "TrackerName")
                
                Text("Websocket URL")
                    .fontWeight(.bold)
                TextField("Websocket URL", text: $authViewModel.websocketUrl).accessibility(identifier: "WebsocketURL")
                
                Text("Geofence Collection ARN")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                TextField("Geofence Collection ARN", text: $authViewModel.geofenceCollectionArn).accessibility(identifier: "GeofenceCollectionARN")
                
                Button("Save Configuration") {
                    if authViewModel.identityPoolId.isEmpty || authViewModel.trackerName.isEmpty || authViewModel.websocketUrl.isEmpty || authViewModel.geofenceCollectionArn.isEmpty {
                        errorMessage = NSLocalizedString("FillAllFields", comment: "")
                        showError = true
                    }
                    else {
                        authViewModel.saveCognitoConfiguration()
                        isPresented = false
                    }
                }.accessibility(identifier: "SaveConfiguration")
                Text(errorMessage)
            }
            .navigationBarTitle(NSLocalizedString("SaveCognitoConfiguration", comment: ""), displayMode: .inline)
                       .navigationBarItems(trailing: Button(action: {
                           isPresented = false
                       }) {
                           Text(NSLocalizedString("Cancel", comment: "")).bold()
                       })
        }
    }
}
