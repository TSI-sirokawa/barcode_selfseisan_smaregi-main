//
//  UserDefaultsRepository.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/18.
//

import Foundation
import Logging

final class UserDefaultsRepository: AppSettingRepositoryProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    func load<T: Any>(key: String) -> T? {
        let value = UserDefaults.standard.object(forKey: key)
        if value == nil {
            return nil
        }
        return value as? T
    }
    
    func save<T: Any>(key: String, value: T) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    /// UserDefaultsに保存した設定値を全て削除する
    /// 　→本関数はアプリケーションでは使用されないが、デバッグ用途に実装を残しておく
    static func removeAll() {
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
    }
}
