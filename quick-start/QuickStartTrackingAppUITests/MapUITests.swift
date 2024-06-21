import XCTest
import CoreLocation
 
final class MapUITests : UITests {
    
    func testMapAndTrackingButton() throws {
        launchApp()
        
        let mapView = app.otherElements["MapView"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 10), "Map view did load in time")
        
        let trackingButton = app.buttons["TrackingButton"]
        XCTAssertTrue(trackingButton.exists, "Tracking button did load")
    }
    
    func testTracking() throws {
        XCUIDevice.shared.location = XCUILocation(location:  CLLocation(latitude: 33.930338, longitude: -118.368004))
        launchApp()
        
        sleep(3)
        app.buttons["TrackingButton"].tap()
        
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 33.930338, longitude: -118.368004))
        sleep(3)
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 33.933171, longitude: -118.356971))
        sleep(3)
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 33.929322, longitude: -118.342870))
        sleep(3)
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 33.935338, longitude: -118.368004))
        sleep(3)

        let mapView = app.otherElements["MapView"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 10), "Map view did load in time")
        
        let annotationImage = app.descendants(matching: .any).matching(identifier: "TrackingAnnotation1").firstMatch
        if(annotationImage.waitForExistence(timeout: 10)) {
            XCTAssertTrue(annotationImage.exists, "Tracking points found")
        }
    }
    
    func testLocateMeButton() throws {
        launchApp()
        XCUIDevice.shared.location = XCUILocation(location:  CLLocation(latitude: 33.930338, longitude: -118.368004))
        sleep(5)
        let locateMeButton = app.buttons["LocateMeButton"]
        XCTAssertTrue(locateMeButton.exists, "Locate Me button did load")
        locateMeButton.tap()
        
        let mapView = app.otherElements["MapView"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 10), "Map view did load in time")
        
        let annotationImage = app.descendants(matching: .any).matching(identifier: "userLocationAnnotation").firstMatch
        if(annotationImage.waitForExistence(timeout: 10)) {
            XCTAssertTrue(annotationImage.exists, "User location annotation found")
        }

    }
    
    func testReverseGeocoding() throws {
        launchApp()
        XCUIDevice.shared.location = XCUILocation(location:  CLLocation(latitude: 33.930338, longitude: -118.368004))
        sleep(5)
        let addressLabel = app.staticTexts["CenterAddressLabel"]
        
        XCTAssertTrue(addressLabel.exists, "CenterAddressLabel did load")
        XCTAssertNotNil(addressLabel.value,  "CenterAddressLabel has value")
    }
    
    
}
