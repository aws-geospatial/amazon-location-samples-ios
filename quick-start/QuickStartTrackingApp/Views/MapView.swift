import SwiftUI
import MapLibre

struct MapView: UIViewRepresentable {
    var onMapViewAvailable: ((MLNMapView) -> Void)?
    var mlnMapView: MLNMapView?
    var trackingViewModel: TrackingViewModel
    
    func makeCoordinator() -> MapView.Coordinator {
        return Coordinator(self, trackingViewModel: trackingViewModel)
    }
    
    func makeUIView(context: Context) -> MLNMapView {
        let styleURL = URL(string: "https://maps.geo.\(trackingViewModel.region).amazonaws.com/maps/v0/maps/\(trackingViewModel.mapName)/style-descriptor")
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setZoomLevel(15, animated: true)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        context.coordinator.mlnMapView = mapView
        mapView.delegate = context.coordinator

        mapView.logoView.isHidden = true
        context.coordinator.addCenterMarker()
        
        onMapViewAvailable?(mapView)
        trackingViewModel.mlnMapView = mapView
        return mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate, MapViewDelegate {
        var control: MapView
        var mlnMapView: MLNMapView?
        var trackingViewModel: TrackingViewModel
        var centerMarker: MLNPointAnnotation?
        
        public init(_ control: MapView, trackingViewModel: TrackingViewModel) {
            self.control = control
            self.trackingViewModel = trackingViewModel
            super.init()
            self.trackingViewModel.mapViewDelegate = self
        }

        func mapViewDidFinishRenderingMap(_ mapView: MLNMapView, fullyRendered: Bool) {
            if(fullyRendered) {
                mapView.accessibilityIdentifier = "MapView"
                mapView.isAccessibilityElement = false
            }
        }
        
        func addCenterMarker() {
            guard let mlnMapView = mlnMapView else {
                return
            }

            let centerCoordinate = mlnMapView.centerCoordinate
            let marker = MLNPointAnnotation()
            marker.coordinate = centerCoordinate
            marker.accessibilityLabel = "CenterMarker"
            mlnMapView.addAnnotation(marker)
            centerMarker = marker

            trackingViewModel.reverseGeocodeCenter(centerCoordinate: centerCoordinate, marker: marker)
        }
        
        func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
            if let marker = centerMarker {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    mapView.deselectAnnotation(marker, animated: false)
                    marker.coordinate = mapView.centerCoordinate
                    let centerCoordinate = mapView.centerCoordinate
                    self.trackingViewModel.reverseGeocodeCenter(centerCoordinate: centerCoordinate, marker: marker)
                }
            }
        }
        
        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            guard let pointAnnotation = annotation as? MLNPointAnnotation else {
                return nil
            }

            let reuseIdentifier: String
            var color: UIColor = .black
            if pointAnnotation.accessibilityLabel == "Tracking" {
                reuseIdentifier = "TrackingAnnotation"
                color = UIColor(red: 0.00784313725, green: 0.50588235294, blue: 0.58039215686, alpha: 1)
            } else if pointAnnotation.accessibilityLabel == "LocationChange" {
                reuseIdentifier = "LocationChange"
                color = .gray
            } else {
                reuseIdentifier = "DefaultAnnotationView"
            }

            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

            if annotationView == nil {
                if reuseIdentifier != "DefaultAnnotationView" {
                    annotationView = MLNAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                    //If point annotation is an uploaded Tracking point the radius is 20 and color is blue, otherwise radius is 10 and color is gray
                    let radius = pointAnnotation.accessibilityLabel == "Tracking" ? 20:10
                    annotationView?.frame = CGRect(x: 0, y: 0, width: radius, height: radius)
                    annotationView?.backgroundColor = color
                    annotationView?.layer.cornerRadius = 10
                    
                    if pointAnnotation.accessibilityLabel == "Tracking" {
                        annotationView?.layer.borderColor = UIColor.white.cgColor
                        annotationView?.layer.borderWidth = 2.0
                        annotationView?.layer.shadowColor = UIColor.black.cgColor
                        annotationView?.layer.shadowOffset = CGSize(width: 0, height: 2)
                        annotationView?.layer.shadowRadius = 3
                        annotationView?.layer.shadowOpacity = 0.2
                        annotationView?.clipsToBounds = false
                    }
                }
                else {
                    return nil
                }
            }

            return annotationView
        }
        
        func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
            if (userLocation?.location) != nil {
                if trackingViewModel.trackingActive {
                    let point = MLNPointAnnotation()
                    point.coordinate = (userLocation?.location!.coordinate)!
                    point.accessibilityLabel = "LocationChange"
                    mapView.addAnnotation(point)
                    Task {
                        do {
                            try await trackingViewModel.getTrackingPoints()
                        }
                        catch {
                            trackingViewModel.showErrorAlertPopup(title: "Error", message: "Error in get tracking points: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        
        func checkIfTrackingAnnotationExists(on mapView: MLNMapView, at coordinates: CLLocationCoordinate2D) -> Bool {
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

            let uniqueCoordinates = newTrackingPoints.filter { coordinate in
                !checkIfTrackingAnnotationExists(on: mapView, at: coordinate)
            }

            let points = uniqueCoordinates.map { coordinate -> MLNPointAnnotation in
                let point = MLNPointAnnotation()
                point.coordinate = coordinate
                point.accessibilityLabel = "Tracking"
                return point
            }
            mapView.addAnnotations(points)
        }
    }
}

protocol MapViewDelegate: AnyObject {
    func drawTrackingPoints(trackingPoints: [CLLocationCoordinate2D]?)
}
