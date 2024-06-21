import Foundation

enum Config {
    static let region = Bundle.main.object(forInfoDictionaryKey: "Region") as! String
    static let mapName = Bundle.main.object(forInfoDictionaryKey: "MapName") as! String
    static let indexName = Bundle.main.object(forInfoDictionaryKey: "IndexName") as! String
    static let identityPoolId = Bundle.main.object(forInfoDictionaryKey: "IdentityPoolId") as! String
    static let trackerName = Bundle.main.object(forInfoDictionaryKey: "TrackerName") as! String
}
