import SwiftUI
import MapLibre
import UIKit
import AmazonLocationiOSAuthSDK
import AWSIoT
import AWSIoTEvents
import AWSCognitoIdentity
import AwsCommonRuntimeKit
import AWSLocation

struct MapView: UIViewRepresentable {
    var onMapViewAvailable: ((MLNMapView) -> Void)?
    var mlnMapView: MLNMapView?
    var authViewModel: AuthViewModel
    func makeCoordinator() -> MapView.Coordinator {
        return Coordinator(self, authViewModel: authViewModel)
    }
    
    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero)
        let regionName = authViewModel.apiKeyRegion
        let styleName = "Standard"
        let colorScheme = "Light"  // You can change this to Dark if needed
        if let styleURL = URL(string: "https://maps.geo.\(regionName).amazonaws.com/v2/styles/\(styleName)/descriptor?key=\(authViewModel.apiKey)&color-scheme=\(colorScheme)") {
            DispatchQueue.main.async {
                mapView.styleURL = styleURL
            }
        }
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setZoomLevel(15, animated: true)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        context.coordinator.mlnMapView = mapView
        mapView.delegate = context.coordinator
        
        let locateMeButton = UIButton(type: .system)
        locateMeButton.setImage(UIImage(systemName: "scope"), for: .normal)
        locateMeButton.backgroundColor = .white
        locateMeButton.tintColor = .blue
        locateMeButton.frame = CGRect(x: mapView.frame.width - 70, y: mapView.frame.height - 150, width: 50, height: 50)
        locateMeButton.layer.cornerRadius = 8
        locateMeButton.layer.shadowColor = UIColor.black.cgColor
        locateMeButton.layer.shadowOpacity = 0.3
        locateMeButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        locateMeButton.layer.shadowRadius = 3
        locateMeButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        locateMeButton.addTarget(context.coordinator, action: #selector(Coordinator.locateMeButtonTapped), for: .touchUpInside)
        locateMeButton.accessibilityIdentifier = "LocateMeButton"
        
        mapView.addSubview(locateMeButton)
        
        onMapViewAvailable?(mapView)
        return mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate, MapViewDelegate {
        var control: MapView
        var mlnMapView: MLNMapView?
        var authViewModel: AuthViewModel
        
        public init(_ control: MapView, authViewModel: AuthViewModel) {
            self.control = control

            self.authViewModel = authViewModel
            super.init()
            self.authViewModel.delegate = self
        }
        
        func mapViewDidFinishRenderingMap(_ mapView: MLNMapView, fullyRendered: Bool) {
            if(fullyRendered) {
                mapView.accessibilityIdentifier = "MapView"
                mapView.isAccessibilityElement = false
            }
        }
        
        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            // Check if the annotation is an MLNPointAnnotation
            guard let pointAnnotation = annotation as? MLNPointAnnotation else {
                return nil
            }

            let reuseIdentifier: String
            let color: UIColor
            if pointAnnotation.accessibilityLabel == "Tracking" {
                reuseIdentifier = "blueDot"
                color = UIColor(red: 0.00784313725, green: 0.50588235294, blue: 0.58039215686, alpha: 1)
            } else if pointAnnotation.accessibilityLabel == "LocationChange" {
                reuseIdentifier = "grayDot"
                color = .gray
            } else {
                // Default case
                reuseIdentifier = "defaultDot"
                color = .black
            }

            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

            if annotationView == nil {
                annotationView = MLNAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                let radius = pointAnnotation.accessibilityLabel == "Tracking" ? 20:10
                annotationView?.frame = CGRect(x: 0, y: 0, width: radius, height: radius) // Adjusted size for border and shadow visibility
                annotationView?.backgroundColor = color
                
                // Make it a circle
                annotationView?.layer.cornerRadius = 10 // Adjusted for the new size
                
                if pointAnnotation.accessibilityLabel == "Tracking" {
                    // Add white border
                    annotationView?.layer.borderColor = UIColor.white.cgColor
                    annotationView?.layer.borderWidth = 2.0 // Adjust the border width as needed
                    
                    // Add bottom shadow
                    annotationView?.layer.shadowColor = UIColor.black.cgColor
                    annotationView?.layer.shadowOffset = CGSize(width: 0, height: 2) // Shadow direction
                    annotationView?.layer.shadowRadius = 3 // Shadow blur
                    annotationView?.layer.shadowOpacity = 0.2 // Shadow transparency
                    annotationView?.clipsToBounds = false // Important to see the shadow
                }
            }

            return annotationView
        }
        
        func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
            if (userLocation?.location) != nil {
                if UserDefaultsHelper.get(for: Bool.self, key: .trackingActive) ?? false {
                    let point = MLNPointAnnotation()
                    point.coordinate = (userLocation?.location!.coordinate)!
                    point.accessibilityLabel = "LocationChange"
                    mapView.addAnnotation(point)
                    Task {
                        try await authViewModel.getTrackingPoints()
                        try await authViewModel.batchEvaluateGeofences()
                    }
                    authViewModel.currentLocation = userLocation?.location
                }
            }
        }
        
        func checkIfTrackingAnnotationExists(on mapView: MLNMapView, at coordinates: CLLocationCoordinate2D) -> Bool {
            // Find the first annotation that matches the coordinates
            let existingAnnotation = mapView.annotations?.first(where: { annotation in
                guard let annotation = annotation as? MLNPointAnnotation else { return false }
                return annotation.coordinate.latitude == coordinates.latitude &&
                annotation.coordinate.longitude == coordinates.longitude && annotation.accessibilityLabel == "Tracking" })
            return existingAnnotation != nil
        }
        
        public func drawTrackingPoints(trackingPoints: [CLLocationCoordinate2D]?) {
            guard let mapView = mlnMapView, let newTrackingPoints = trackingPoints, !newTrackingPoints.isEmpty else {
                return
            }
            
            // Filter out coordinates where an annotation already exists
            let uniqueCoordinates = newTrackingPoints.filter { coordinate in
                !checkIfTrackingAnnotationExists(on: mapView, at: coordinate)
            }

            // Map the filtered coordinates to new MLNPointAnnotation objects
            let points = uniqueCoordinates.map { coordinate -> MLNPointAnnotation in
                let point = MLNPointAnnotation()
                point.coordinate = coordinate
                point.accessibilityLabel = "Tracking"
                return point
            }
            
            // Add point annotations to the map
            mapView.addAnnotations(points)
        }
        
        public func displayGeofences(geofences: [LocationClientTypes.ListGeofenceResponseEntry]) {
            for geofence in geofences {
                guard let mapView = mlnMapView, let geometry = geofence.geometry, let polygon = geometry.polygon, !polygon.isEmpty else {
                    continue
                }
                
                // Assuming the first polygon is the one we want to display
                // AWSLocationGeofenceGeometry's polygon is an array of arrays of CLLocationDegrees (longitude, latitude)
                let outerRing = polygon[0] // Get the first ring of the polygon
                
                var coordinates = outerRing.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0] ) }
                
                    let polygonFeature = MLNPolygonFeature(coordinates: &coordinates, count: UInt(coordinates.count))
                    let sourceIdentifier = "geofence-source-\(geofence.geofenceId ?? UUID().uuidString)"
                    let source = MLNShapeSource(identifier: sourceIdentifier, shape: polygonFeature, options: nil)
                    mapView.style?.addSource(source)
                    
                    let layerIdentifier = "geofence-layer-\(geofence.geofenceId ?? UUID().uuidString)"
                    let layer = MLNFillStyleLayer(identifier: layerIdentifier, source: source)
                    layer.fillColor = NSExpression(forConstantValue: UIColor.blue.withAlphaComponent(0.5))
                    layer.fillOutlineColor = NSExpression(forConstantValue: UIColor.blue)
                    mapView.style?.addLayer(layer)
            }
        }
        
        @objc func locateMeButtonTapped() {
            guard let mapView = mlnMapView, let userLocation = mlnMapView!.userLocation?.coordinate else {
                print("User location is not available.")
                return
            }
            
            mapView.setCenter(userLocation, zoomLevel: 15, animated: true)
        }
    }
}

protocol MapViewDelegate: AnyObject {
    func drawTrackingPoints(trackingPoints: [CLLocationCoordinate2D]?)
    func displayGeofences(geofences: [LocationClientTypes.ListGeofenceResponseEntry])
}
