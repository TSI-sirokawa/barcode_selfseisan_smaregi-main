//
//  BillingLocalID.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/20.
//

import Foundation

/// 請求ローカルID
final class BillingLocalID: CustomStringConvertible, Codable {
    let value: String
    
    init() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        value = dateFormatter.string(from: .now)
    }
    
    var description: String {
        return value
    }
}
