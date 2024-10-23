import Foundation
import SwiftUI
import AmazonLocationiOSAuthSDK
import AmazonLocationiOSTrackingSDK
import CoreLocation
import MapLibre
import AWSIoT
import AWSIoTEvents
import AWSCognitoIdentity
import AwsCommonRuntimeKit
import AWSLocation

final class AuthViewModel : ObservableObject {
    @Published var trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
    @Published var trackingButtonColor = Color.blue
    @Published var apiKey : String
    @Published var apiKeyRegion : String
    @Published var identityPoolId : String
    @Published var trackerName : String
    @Published var geofenceCollectionArn : String
    @Published var websocketUrl : String
    @Published var showAlert = false
    @Published var alertTitle = "Title"
    @Published var alertMessage = "Message"
    @Published var showingCognitoConfiguration = false
    
    @Published var timeFilter = false
    @Published var distanceFilter = false
    @Published var accuracyFilter = false
    
    @Published var timeInterval: Double = 30
    @Published var distanceInterval: Double = 30
    
    @Published var clientIntialised: Bool = false
    
    var loginDelegate: LoginViewModelOutputDelegate?
    var client:LocationTracker!
    var currentLocation: CLLocation!
    
    var authHelper: AuthHelper
    var credentialsProvider: LocationCredentialsProvider?
    
    var mqttClient: Mqtt5Client?
    var mqttIoTContext: MqttIoTContext?
    let backgroundQueue = DispatchQueue(label: "background_queue",
                                        qos: .background)
    
    func populateFilterValues() {
        guard let config = client?.getTrackerConfig() else {
            return
        }
        let filters = config.locationFilters
        timeFilter = filters.contains { $0 is TimeLocationFilter }
        distanceFilter = filters.contains { $0 is DistanceLocationFilter }
        accuracyFilter = filters.contains { $0 is AccuracyLocationFilter }
        
        timeInterval = config.trackingTimeInterval
        distanceInterval = config.trackingDistanceInterval
    }
    
    init(apiKey: String, apiKeyRegion: String, identityPoolId: String, trackerName: String, geofenceCollectionArn: String, websocketUrl: String) {
        self.apiKey = apiKey
        self.apiKeyRegion = apiKeyRegion
        self.identityPoolId = identityPoolId
        self.trackerName = trackerName
        self.geofenceCollectionArn = geofenceCollectionArn
        self.websocketUrl = websocketUrl
        self.authHelper = AuthHelper()
    }
    
    func authWithCognito(identityPoolId: String?) async throws {
        
        guard let identityPoolId = identityPoolId?.trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            DispatchQueue.main.async {
                let model = AlertModel(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("NotAllFieldsAreConfigured", comment: ""), okButton: NSLocalizedString("Ok", comment: ""))
                self.loginDelegate?.showAlert(model)
            }
            return
        }
        credentialsProvider = try await authHelper.authenticateWithCognitoIdentityPool(identityPoolId: identityPoolId)
        let idInput = GetIdInput(identityPoolId: identityPoolId)
        let region = AmazonLocationRegion.toRegionString(identityPoolId: identityPoolId)
        let cognitoIdentityClient = try AWSCognitoIdentity.CognitoIdentityClient(region: region)
        identityId = try await cognitoIdentityClient.getId(input: idInput).identityId
        
        DispatchQueue.main.async {
            self.initializeClient()
            self.populateFilterValues()
        }
    }
    
    func initializeClient() {
        client = LocationTracker(provider: credentialsProvider!, trackerName: trackerName)
        clientIntialised = true
    }
    
    func setClientConfig(timeFilter: Bool, distanceFilter: Bool, accuracyFilter: Bool, timeInterval: Double? = nil, distanceInterval: Double? = nil) {
        var filters: [LocationFilter]? = []
        if timeFilter {
            filters!.append(TimeLocationFilter())
        }
        if distanceFilter {
            filters!.append(DistanceLocationFilter())
        }
        if accuracyFilter {
            filters!.append(AccuracyLocationFilter())
        }
        
        if filters!.isEmpty {
            filters = nil
        }
        
        let config = LocationTrackerConfig(locationFilters: filters, trackingDistanceInterval: distanceInterval, trackingTimeInterval: timeInterval)
        
        client.setTrackerConfig(config: config)
    }
    
    func showLocationDeniedRationale() {
        DispatchQueue.main.async {
            self.alertTitle = NSLocalizedString("locationManagerAlertTitle", comment: "")
            self.alertMessage = NSLocalizedString("locationManagerAlertText", comment: "")
            self.showAlert = true
        }
    }
    
    func startTracking() async throws {
        do {
            print("Tracking Started...")
            if(client == nil)
            {
                try await authWithCognito(identityPoolId: identityPoolId)
            }
            try await fetchGeofenceList()
            try client.startBackgroundTracking(mode: .Active)
            subscribeToAWSNotifications()
            DispatchQueue.main.async {
                self.trackingButtonText = NSLocalizedString("StopTrackingLabel", comment: "")
                self.trackingButtonColor = .red
            }
            UserDefaultsHelper.save(value: true, key: .trackingActive)
        } catch TrackingLocationError.permissionDenied {
            showLocationDeniedRationale()
        } catch {
            print("error in tracking \(error)")
        }
    }
    
    func resumeTracking() async throws {
        do {
            print("Tracking Resumed...")
            if(client == nil)
            {
                try await authWithCognito(identityPoolId: identityPoolId)
            }
            try client.resumeBackgroundTracking(mode: .Active)
            subscribeToAWSNotifications()
            DispatchQueue.main.async {
                self.trackingButtonText = NSLocalizedString("StopTrackingLabel", comment: "")
                self.trackingButtonColor = .red
            }
            UserDefaultsHelper.save(value: true, key: .trackingActive)
        } catch TrackingLocationError.permissionDenied {
            showLocationDeniedRationale()
        } catch {
            print("error in tracking")
        }
    }
    
    func stopTracking() {
        print("Tracking Stopped...")
        client.stopBackgroundTracking()
        unsubscribeFromAWSNotifications()
        trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
        trackingButtonColor = .blue
        UserDefaultsHelper.save(value: false, key: .trackingActive)
    }
    
    var delegate: MapViewDelegate?
    var lastGetTrackingTime: Date?
    
    func getTrackingPoints(nextToken: String? = nil) async throws {
        do {
            guard UserDefaultsHelper.get(for: Bool.self, key: .trackingActive) ?? false else {
                return
            }
            let startTime: Date = Date().addingTimeInterval(-86400)
            var endTime: Date = Date()
            if lastGetTrackingTime != nil {
                endTime = lastGetTrackingTime!
            }
            let response = try await client?.getTrackerDeviceLocation(nextToken: nextToken, startTime: startTime, endTime: endTime)
            if let response = response {
                lastGetTrackingTime = Date()
                let positions = response.devicePositions!.sorted { (position1, position2) -> Bool in
                    let timestamp1 = position1.sampleTime ?? Date()
                    let timestamp2 = position2.sampleTime ?? Date()
                    
                    return timestamp1 > timestamp2
                }
                let trackingPoints = positions.compactMap { position -> CLLocationCoordinate2D? in
                    guard let latitude = position.position?[1], let longitude = position.position?[0] else {
                        return nil
                    }
                    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                }
                DispatchQueue.main.async {
                    self.delegate?.drawTrackingPoints( trackingPoints: trackingPoints)
                }
                // If nextToken is not nil, recursively call to get more data
                if let nextToken = response.nextToken {
                    try await getTrackingPoints(nextToken: nextToken)
                }
            }
        }
        catch {
            print("Error getting tracking locations: \(error)")
        }
    }
    
    func batchEvaluateGeofences() async throws {
        guard lastGetTrackingTime != nil, currentLocation != nil else {
            return
        }
        guard let geofenceCollectionName = getGeofenceCollectionName(geofenceCollectionArn: geofenceCollectionArn) else { return }
        let deviceUpdate = DevicePositionUpdate()
        deviceUpdate.deviceId = client.getDeviceId()
        deviceUpdate.position = [currentLocation.coordinate.longitude, currentLocation.coordinate.latitude]
        deviceUpdate.sampleTime = lastGetTrackingTime
        
        let request = BatchEvaluateGeofencesRequest(collectionName: geofenceCollectionName, devicePositionUpdates: [deviceUpdate])
        print("device Id: \(String(describing: deviceUpdate.deviceId))")
        let response = try await client?.batchEvaluateGeofences(request: request)
        if response?.errors == nil || response?.errors?.count == 0 {
            print("batchEvaluateGeofences success")
            
        }
        else if let error = response?.errors?[0] {
            print("batchEvaluateGeofences error \(error)")
        }
    }
    
    func fetchGeofenceList() async throws {
        guard let geofenceCollectionName = getGeofenceCollectionName(geofenceCollectionArn: geofenceCollectionArn) else { return }
        let locationClient = authHelper.getLocationClient()?.locationClient
        let input = ListGeofencesInput(collectionName: geofenceCollectionName)
        let response = try await locationClient?.listGeofences(input: input)
        DispatchQueue.main.async {
            if let geofences = response?.entries {
                self.delegate?.displayGeofences(geofences: geofences)
            }
        }
    }
    
    func getGeofenceCollectionName(geofenceCollectionArn: String) -> String? {
        let components = geofenceCollectionArn.split(separator: ":")
        
        if let lastComponent = components.last {
            let nameComponents = lastComponent.split(separator: "/")
            if nameComponents.count > 1, let collectionNameSubstring = nameComponents.last {
                let collectionName = String(collectionNameSubstring)
                return collectionName
            } else {
                print("Collection name could not be extracted")
            }
        } else {
            print("Invalid ARN format")
        }
        return nil
    }
    
    func configureCognito() {
        showingCognitoConfiguration = true
    }
    
    func saveCognitoConfiguration() {
        UserDefaultsHelper.save(value: apiKey, key: .apiKey)
        UserDefaultsHelper.save(value: apiKeyRegion, key: .apiKeyRegion)
        UserDefaultsHelper.save(value: identityPoolId, key: .identityPoolID)
        UserDefaultsHelper.save(value: trackerName, key: .trackerName)
        UserDefaultsHelper.save(value: geofenceCollectionArn, key: .geofenceCollectionArn)
        UserDefaultsHelper.save(value: websocketUrl, key: .websocketUrl)
        
        applyConfiguration()
    }
    
    func applyConfiguration() {
        Task {
            try await authWithCognito(identityPoolId: identityPoolId)
        }
    }
    
    
    func localizedDateString(from jsonStringDate: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        guard let date = isoFormatter.date(from: jsonStringDate) else {
            fatalError("Invalid date format")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale.current
        
        return dateFormatter.string(from: date)
    }
    
    func createClient(clientOptions: MqttClientOptions, iotContext: MqttIoTContext) throws -> Mqtt5Client {
        let clientOptionsWithCallbacks = MqttClientOptions(
            hostName: clientOptions.hostName,
            port: clientOptions.port,
            bootstrap: clientOptions.bootstrap,
            socketOptions: clientOptions.socketOptions,
            tlsCtx: clientOptions.tlsCtx,
            onWebsocketTransform: iotContext.onWebSocketHandshake,
            httpProxyOptions: clientOptions.httpProxyOptions,
            connectOptions: clientOptions.connectOptions,
            sessionBehavior: clientOptions.sessionBehavior,
            extendedValidationAndFlowControlOptions: clientOptions.extendedValidationAndFlowControlOptions,
            offlineQueueBehavior: clientOptions.offlineQueueBehavior,
            retryJitterMode: clientOptions.retryJitterMode,
            minReconnectDelay: clientOptions.minReconnectDelay,
            maxReconnectDelay: clientOptions.maxReconnectDelay,
            minConnectedTimeToResetReconnectDelay: clientOptions.minConnectedTimeToResetReconnectDelay,
            pingTimeout: clientOptions.pingTimeout,
            connackTimeout: clientOptions.connackTimeout,
            ackTimeout: clientOptions.ackTimeout,
            topicAliasingOptions: clientOptions.topicAliasingOptions,
            onPublishReceivedFn: iotContext.onPublishReceived,
            onLifecycleEventStoppedFn: iotContext.onLifecycleEventStopped,
            onLifecycleEventAttemptingConnectFn: iotContext.onLifecycleEventAttemptingConnect,
            onLifecycleEventConnectionSuccessFn: iotContext.onLifecycleEventConnectionSuccess,
            onLifecycleEventConnectionFailureFn: iotContext.onLifecycleEventConnectionFailure,
            onLifecycleEventDisconnectionFn: iotContext.onLifecycleEventDisconnection)
        
        let mqtt5Client = try Mqtt5Client(clientOptions: clientOptionsWithCallbacks)
        return mqtt5Client
    }
    
    private func subscribeToAWSNotifications() {
        backgroundQueue.async {
            do {
                self.createIoTClientIfNeeded()
                if self.mqttClient != nil {
                    try self.connectClient(client: self.mqttClient!, iotContext: self.mqttIoTContext!)
                }
            }
            catch {
                print(error)
            }
        }
    }
    var identityId: String? = nil
    private func createIoTClientIfNeeded() {
        let region = credentialsProvider!.getRegion()
        
        guard let region = region,
              mqttClient == nil else {
            return
        }
        do {
            if let identityId = identityId, let deviceId = client.getDeviceId() {
                mqttIoTContext = MqttIoTContext(onPublishReceived: { payloadData in
                    if let payload = payloadData.publishPacket.payload {
                        guard let model = try? JSONDecoder().decode(TrackingEventModel.self, from: payload) else { return }
                        
                        let eventText: String
                        switch model.trackerEventType {
                        case .enter:
                            eventText = NSLocalizedString("GeofenceEnterEvent", comment: "")
                        case .exit:
                            eventText = NSLocalizedString("GeofenceExitEvent", comment: "")
                        }
                        DispatchQueue.main.async {
                            let title = String(format: NSLocalizedString("GeofenceNotificationTitle", comment: ""), eventText)
                            let description = String(format: NSLocalizedString("GeofenceNotificationDescription", comment: ""),  model.geofenceId, eventText, self.localizedDateString(from: model.eventTime))
                            NotificationManager.scheduleNotification(title: title, body: description)
                        }
                    } }, topicName: "\(deviceId)/tracker", cognitoCredentialsProvider: credentialsProvider!.getCognitoProvider()!, region: region)
                let ConnectPacket = MqttConnectOptions(keepAliveInterval: 60000, clientId: identityId)
                let tlsOptions = TLSContextOptions.makeDefault()
                let tlsContext = try TLSContext(options: tlsOptions, mode: .client)
                let elg = try EventLoopGroup()
                let resolver = try HostResolver.makeDefault(eventLoopGroup: elg,
                                                            maxHosts: 8,
                                                            maxTTL: 30)
                let bootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: resolver)
                let clientOptions = MqttClientOptions(
                    hostName: websocketUrl,
                    port: UInt32(443),
                    bootstrap: bootstrap,
                    tlsCtx: tlsContext,
                    connectOptions: ConnectPacket,
                    connackTimeout: TimeInterval(10))
                mqttClient = try createClient(clientOptions: clientOptions, iotContext: mqttIoTContext!)
                mqttIoTContext?.client = mqttClient
            }
        }
        catch {
            mqttIoTContext?.printView("Failed to setup client.")
        }
    }
    
    func connectClient(client: Mqtt5Client, iotContext: MqttIoTContext) throws {
        try client.start()
        if iotContext.semaphoreConnectionSuccess.wait(timeout: .now() + 5) == .timedOut {
            print("Connection Success Timed out after 5 seconds")
        }
    }
    
    func stopClient(client: Mqtt5Client, iotContext: MqttIoTContext) {
        backgroundQueue.async {
            do {
                try client.stop()
                if iotContext.semaphoreStopped.wait(timeout: .now() + 5) == .timedOut {
                    print("Stop timed out after 5 seconds")
                }
            }
            catch {
                print("Failed to stop client: \(error.localizedDescription)")
            }
        }
    }
    
    private func unsubscribeFromAWSNotifications() {
        guard mqttClient != nil else {
            return
        }
        stopClient(client: mqttClient!, iotContext: mqttIoTContext!)
    }
    
}
