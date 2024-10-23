import Foundation

extension String {
    static let errorUserDefaultsSave = "User Default save error:"
}

enum Config {
    static let apiKey = UserDefaultsHelper.get(for: String.self, key: .apiKey) ?? Bundle.main.object(forInfoDictionaryKey: "ApiKey") as? String ?? ""
    static let apiKeyRegion = UserDefaultsHelper.get(for: String.self, key: .apiKeyRegion) ?? Bundle.main.object(forInfoDictionaryKey: "ApiKeyRegion") as? String ?? ""
    static let identityPoolId = UserDefaultsHelper.get(for: String.self, key: .identityPoolID) ?? Bundle.main.object(forInfoDictionaryKey: "IdentityPoolId") as? String ?? ""
    static let mapName = UserDefaultsHelper.get(for: String.self, key: .mapName) ?? Bundle.main.object(forInfoDictionaryKey: "MapName") as? String ?? ""
    static let trackerName = UserDefaultsHelper.get(for: String.self, key: .trackerName) ?? Bundle.main.object(forInfoDictionaryKey: "TrackerName") as? String ?? ""
    static let geofenceARN = UserDefaultsHelper.get(for: String.self, key: .geofenceCollectionArn) ?? Bundle.main.object(forInfoDictionaryKey: "GeofenceARN") as? String ?? ""
    static let websocketUrl = UserDefaultsHelper.get(for: String.self, key: .websocketUrl) ?? Bundle.main.object(forInfoDictionaryKey: "WebsocketUrl") as? String ?? ""
}
