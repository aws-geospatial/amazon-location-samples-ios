import SwiftUI
import AmazonLocationiOSAuthSDK
import AmazonLocationiOSTrackingSDK
import MapLibre
import SmithyHTTPAuthAPI
import AWSLocation
import AWSGeoPlaces
import os.log

final class TrackingViewModel : ObservableObject {
    @Published var trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
    @Published var trackingButtonColor = Color.blue
    @Published var trackingButtonIcon = "play.circle"
    @Published var apiKey : String
    @Published var apiKeyRegion : String
    @Published var identityPoolId : String
    @Published var trackerName : String
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var centerLabel = ""
    
    var clientIntialised: Bool
    var client: LocationTracker!
    var geoPlacesClient: GeoPlacesClient!
    var authHelper: AuthHelper!
    var mlnMapView: MLNMapView?
    var mapViewDelegate: MapViewDelegate?
    var lastGetTrackingTime: Date?
    var trackingActive: Bool
    
    init(apiKey: String, apiKeyRegion: String, identityPoolId: String, trackerName: String) {
        self.apiKey = apiKey
        self.apiKeyRegion = apiKeyRegion
        self.identityPoolId = identityPoolId
        self.trackerName = trackerName
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
        
        self.identityPoolId = identityPoolId
    }
    
    func initializeGeoPlacesClient() async throws {
        authHelper = try await AuthHelper.withApiKey(apiKey: apiKey, region: apiKeyRegion)
        geoPlacesClient = GeoPlacesClient(config: authHelper.getGeoPlacesClientConfig())
    }
    
    func initializeTracker() async throws {
        client = try await LocationTracker(identityPoolId: identityPoolId, trackerName: trackerName)
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
        // This gets called periodically, but the client is created as
        if (geoPlacesClient == nil) {
            return
        }

        do {
            Task {
                let searchRequest = ReverseGeocodeInput(language: "en", maxResults: 10, queryPosition: position, queryRadius: 100)
                let searchResponse = try await geoPlacesClient.reverseGeocode(input: searchRequest)
                DispatchQueue.main.async {
                    self.centerLabel = searchResponse.resultItems?.first?.address?.label ?? ""
                    self.mlnMapView?.selectAnnotation(marker, animated: true, completionHandler: {})
                }
            }
        }
        catch {
            showErrorAlertPopup(title: "Places location client", message: error.localizedDescription)
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
    func startTracking() async throws {
        do {
            print("Tracking Started...")
            if(client == nil) {
                try await initializeTracker()
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
            
            let positions = devicePositions!.sorted { (position1, position2) -> Bool in
                let timestamp1 = position1.sampleTime ?? Date()
                let timestamp2 = position2.sampleTime ?? Date()
                
                return timestamp1 > timestamp2
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
