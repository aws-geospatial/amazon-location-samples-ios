import Foundation

enum Config {
    static let apiKey = Bundle.main.object(forInfoDictionaryKey: "ApiKey") as! String
    static let apiKeyRegion = Bundle.main.object(forInfoDictionaryKey: "ApiKeyRegion") as! String
    static let identityPoolId = Bundle.main.object(forInfoDictionaryKey: "IdentityPoolId") as! String
    static let trackerName = Bundle.main.object(forInfoDictionaryKey: "TrackerName") as! String
}
