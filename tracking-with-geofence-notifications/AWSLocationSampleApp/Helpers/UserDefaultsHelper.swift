//
//  UserDefaultsHelper.swift
//  LocationServices
//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import Foundation

enum UserDefaultKeyType: String {
    case appState
    case apiKey
    case apiKeyRegion
    case identityPoolID
    case mapName
    case trackerName
    case websocketUrl
    case trackingActive
    case geofenceCollectionArn
}

enum AppState: Int {
case initial = 1
case prepareDefaultAWSConnect
case defaultAWSConnected
case prepareCustomAWSConnect
case customAWSConnected
case loggedIn
}

final class UserDefaultsHelper {
    static func save<T>(value:T , key: UserDefaultKeyType){
          UserDefaults.standard.set(value, forKey: key.rawValue)
          UserDefaults.standard.synchronize()
      }
    
    static func saveObject<T: Encodable>(value:T , key: UserDefaultKeyType){
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(value)
            UserDefaults.standard.set(data, forKey: key.rawValue)
            UserDefaults.standard.synchronize()
        } catch {
            print(.errorUserDefaultsSave + " \(T.self)")
        }
    }
      
      static func get<T>(for type:T.Type,key: UserDefaultKeyType) -> T? {
          
          if let value = UserDefaults.standard.value(forKey: key.rawValue) as? T {
              return value
          }
          return nil
      }
    
    static func getAppState() -> AppState {
        if let value = UserDefaults.standard.value(forKey: UserDefaultKeyType.appState.rawValue) as? Int {
            return AppState(rawValue: value) ?? AppState.initial
        }
        return AppState.initial
    }
    
    static func setAppState(state: AppState) {
        UserDefaults.standard.set(state.rawValue, forKey: UserDefaultKeyType.appState.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    static func getObject<T: Decodable>(value:T.Type , key: UserDefaultKeyType) -> T?{
        let decoder = JSONDecoder()
        do {
            if let value = UserDefaults.standard.value(forKey: key.rawValue) as? Data {
                let data = try decoder.decode(T.self, from: value)
                return data
            }
            return nil
            
        } catch {
            print(.errorUserDefaultsSave +  " \(T.self)")
            return nil
        }
    }
    
    static func removeObject(for key: UserDefaultKeyType) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }
}
