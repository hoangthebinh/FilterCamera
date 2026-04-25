//
//  UserDefaultHelper.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import Foundation

public enum UserDefaultKey: String {
    case isOnboarded
}

final class UserDefaultHelper {
    // MARK: - Save
    static func save<T>(value: T, key: UserDefaultKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    // MARK: - Get
    static func get<T>(for key: UserDefaultKey) -> T? {
        return UserDefaults.standard.object(forKey: key.rawValue) as? T
    }

    // MARK: - Get with default
    static func get<T>(for key: UserDefaultKey, default defaultValue: T) -> T {
        return UserDefaults.standard.object(forKey: key.rawValue) as? T ?? defaultValue
    }
}
