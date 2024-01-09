//
//  Amount.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/10.
//

import Foundation

/// 金額
class Amount: CustomStringConvertible, Codable, Equatable {
    let value: Int
    
    /// 0円
    static let Zero = Amount(value: 0, local: true)
    
    init(_ value: Int, isMinusAllow: Bool) throws {
        try Amount.checkValue(value, isMinusAllow)
        self.value = value
    }
    
    init(_ value: String, isMinusAllow: Bool) throws {
        guard let intValue = Int(value) else {
            throw ModelError.argument("value is invalid. value=\(value)")
        }
        
        try Amount.checkValue(intValue, isMinusAllow)
        self.value = intValue
    }
    
    init(_ amount: Amount) {
        self.value = amount.value
    }
    
    private init(value: Int, local: Bool) {
        self.value = value
    }
    
    private static func checkValue(_ value: Int, _ isMinusAllow: Bool) throws {
        if !isMinusAllow && value < 0 {
            throw ModelError.argument("value is invalid. value=\(value)")
        }
    }
    
    var description: String {
        return "\(value)"
    }
    
    static func == (lhs: Amount, rhs: Amount) -> Bool {
        return lhs.value == rhs.value
    }
}
