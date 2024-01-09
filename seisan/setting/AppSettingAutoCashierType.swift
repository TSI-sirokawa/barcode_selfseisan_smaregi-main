//
//  AppSettingAutoCashierType.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/25.
//

import Foundation

extension AppSetting {
    /// 自動つり銭機種別
    enum AutoCashierType: String, CaseIterable, Codable {
        case GrolyR08
        case Groly300
        /// 使わない
        case NoUse
        
        var description: String {
            switch self {
            case .GrolyR08:
                return "グローリーR08"
            case .Groly300:
                return "グローリー300"
            case .NoUse:
                return "使用しない"
            }
        }
        
        static func parse(str: String?, defaultValue: AutoCashierType) -> AutoCashierType {
            guard let str = str else {
                return defaultValue
            }
            
            let ret = AutoCashierType(rawValue: str) ?? defaultValue
            return ret
        }
    }
}
