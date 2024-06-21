import XCTest

private final class UITestBundle {}

class UITests: XCTestCase {
    var app: XCUIApplication!
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let sampleIdentityPoolID = Bundle(for: UITestBundle.self).object(forInfoDictionaryKey: "TestIdentityPoolId") as! String
    let sampleRegion = Bundle(for: UITestBundle.self).object(forInfoDictionaryKey: "TestRegion") as! String
    let sampleMapName = Bundle(for: UITestBundle.self).object(forInfoDictionaryKey: "TestMapName") as! String
    let sampleTrackerName = Bundle(for: UITestBundle.self).object(forInfoDictionaryKey: "TestTrackerName") as! String

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        springboard.resetAuthorizationStatus(for: .location)
        app.launchArguments = ["testing"]
    }
    
    func allowPermission() {
        let allowBtn = springboard.alerts.buttons.element(boundBy: 1)
        
        if allowBtn.waitForExistence(timeout: 5) {
            allowBtn.tap()
        }
    }
    
    func launchApp(withConfiguration: Bool = true) {
        if(withConfiguration) {
            app.launchArguments += ["-identityPoolID", sampleIdentityPoolID]
            app.launchArguments += ["-region", sampleRegion]
            app.launchArguments += ["-mapName", sampleMapName]
            app.launchArguments += ["-trackerName", sampleTrackerName]
        }
        app.launch()
        allowPermission()
        if(withConfiguration) {
            allowPermission()
        }
    }
}
