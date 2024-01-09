//
//  AppSettingRepositoryFactory.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/29.
//

import Foundation
import Logging

final class AppSettingRepositoryFactory {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    static func create() -> AppSettingRepositoryProtocol {
        return UserDefaultsRepository()
    }
}
