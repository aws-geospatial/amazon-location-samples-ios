import SwiftUI
import AmazonLocationiOSAuthSDK
import AmazonLocationiOSTrackingSDK
import MapLibre
import AWSLocation
import os.log

final class TrackingViewModel : ObservableObject {
    @Published var trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
    @Published var trackingButtonColor = Color.blue
    @Published var trackingButtonIcon = "play.circle"
    @Published var region : String
    @Published var mapName : String
    @Published var indexName : String
    @Published var identityPoolId : String
    @Published var trackerName : String
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var centerLabel = ""
    @Published var mapSigningIntialised: Bool = false

    var clientIntialised: Bool
    var client: LocationTracker!
    var authHelper: AuthHelper
    var credentialsProvider: LocationCredentialsProvider?
    var mlnMapView: MLNMapView?
    var mapViewDelegate: MapViewDelegate?
    var lastGetTrackingTime: Date?
    var trackingActive: Bool
    var signingDelegate: MLNOfflineStorageDelegate?
    
    init(region: String, mapName: String, indexName: String, identityPoolId: String, trackerName: String) {
        self.region = region
        self.mapName = mapName
        self.indexName = indexName
        self.identityPoolId = identityPoolId
        self.trackerName = trackerName
        self.authHelper = AuthHelper()
        self.trackingActive = false
        self.clientIntialised = false
    }
    
    func authWithCognito(identityPoolId: String?) async throws {
        guard let identityPoolId = identityPoolId?.trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            alertTitle = NSLocalizedString("Error", comment: "")
            alertMessage = NSLocalizedString("NotAllFieldsAreConfigured", comment: "")
            showAlert = true
            return
        }
        credentialsProvider = try await authHelper.authenticateWithCognitoIdentityPool(identityPoolId: identityPoolId)
        mapViewSigning()
    }
    
    func mapViewSigning() {
        DispatchQueue.main.async { [self] in
            signingDelegate = AWSSignatureV4Delegate(credentialsProvider: credentialsProvider!)
            MLNOfflineStorage.shared.delegate = self.signingDelegate
            mapSigningIntialised = true
        }
    }
    
    func initializeClient() {
        client = LocationTracker(provider: credentialsProvider!, trackerName: trackerName)
        clientIntialised = true
    }
    
    func locateMe() {
        guard let mapView = mlnMapView, let userLocation = mlnMapView!.userLocation?.coordinate else {
            print("User location is not available.")
            return
        }
        mapView.setCenter(userLocation, zoomLevel: 15, animated: true)
        mapView.userTrackingMode = .follow
    }
    

    func reverseGeocodeCenter(centerCoordinate: CLLocationCoordinate2D, marker: MLNPointAnnotation) {
        let position = [centerCoordinate.longitude, centerCoordinate.latitude]
        searchPositionAPI(position: position, marker: marker)
    }
    
    func searchPositionAPI(position: [Double], marker: MLNPointAnnotation) {
        if let amazonClient = authHelper.getLocationClient() {
            Task {
                let searchRequest = SearchPlaceIndexForPositionInput(indexName: indexName, language: "en" , maxResults: 10, position: position)
                let searchResponse = try? await amazonClient.searchPosition(indexName: indexName, input: searchRequest)
                DispatchQueue.main.async {
                    self.centerLabel = searchResponse?.results?.first?.place?.label ?? ""
                    self.mlnMapView?.selectAnnotation(marker, animated: true, completionHandler: {})
                }
            }
        }
    }
    
    func showLocationDeniedRationale() {
        alertTitle = NSLocalizedString("locationManagerAlertTitle", comment: "")
        alertMessage = NSLocalizedString("locationManagerAlertText", comment: "")
        showAlert = true
    }
    
    func showErrorAlertPopup(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
        os_log("%@", type: .error, message)
    }
    
    // Required in info.plist: Privacy - Location When In Use Usage Description
    func startTracking() {
        do {
            print("Tracking Started...")
            if(client == nil) {
                initializeClient()
            }
            try client.startTracking()
            DispatchQueue.main.async { [self] in
                self.trackingButtonText = NSLocalizedString("StopTrackingLabel", comment: "")
                self.trackingButtonColor = .red
                self.trackingButtonIcon = "pause.circle"
                trackingActive = true
            }
        } catch TrackingLocationError.permissionDenied {
            showLocationDeniedRationale()
        } catch {
            showErrorAlertPopup(title: "Error", message: "Error in tracking: \(error.localizedDescription)")
        }
    }
    
    func stopTracking() {
        print("Tracking Stopped...")
        client.stopTracking()
        trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
        trackingButtonColor = .blue
        trackingButtonIcon = "play.circle"
        trackingActive = false
    }

    func getTrackingPoints(nextToken: String? = nil) async throws {
        guard trackingActive else {
            return
        }
        // Initialize startTime to 24 hours ago from the current date and time.
        let startTime: Date = Date().addingTimeInterval(-86400)
        var endTime: Date = Date()
        if lastGetTrackingTime != nil {
            endTime = lastGetTrackingTime!
        }
        let result = try await client?.getTrackerDeviceLocation(nextToken: nextToken, startTime: startTime, endTime: endTime)
        if let trackingData = result {
            
            lastGetTrackingTime = Date()
            let devicePositions = trackingData.devicePositions

            let positions = devicePositions!.sorted { (pos1: LocationClientTypes.DevicePosition, pos2: LocationClientTypes.DevicePosition) -> Bool in
                guard let date1 = pos1.sampleTime,
                      let date2 = pos2.sampleTime else {
                    return false
                }
                return date1 < date2
            }

            let trackingPoints = positions.compactMap { position -> CLLocationCoordinate2D? in
                guard let latitude = position.position!.last, let longitude = position.position!.first else {
                    return nil
                }
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            DispatchQueue.main.async {
                self.mapViewDelegate!.drawTrackingPoints( trackingPoints: trackingPoints)
            }
            if let nextToken = trackingData.nextToken {
                try await getTrackingPoints(nextToken: nextToken)
            }
        }
    }
}
