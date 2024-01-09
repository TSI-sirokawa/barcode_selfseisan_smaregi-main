//
//  AppSettingBarcodeType.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/03/14.
//

import Foundation

extension AppSetting {
    /// バーコード種別
    enum BarcodeType: String, CaseIterable, Codable {
        /// 領収書バーコード
        case ReceiptBarcord
        /// 診察券バーコード`
        case PatientCardBarcord
        
        var description: String {
            switch self {
            case .ReceiptBarcord:
                return "領収書バーコード"
            case .PatientCardBarcord:
                return "診察券バーコード"
            }
        }
        
        static func parse(str: String?, defaultValue: BarcodeType) -> BarcodeType {
            guard let str = str else {
                return defaultValue
            }
            
            let ret = BarcodeType(rawValue: str) ?? defaultValue
            return ret
        }
    }
}
