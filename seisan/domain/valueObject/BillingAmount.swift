//
//  BillingAmount.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/09/13.
//

import Foundation

/// 請求金額
final class BillingAmount: Amount {
    override init(_ value: Int, isMinusAllow: Bool) throws {
        try super.init(value, isMinusAllow: isMinusAllow)
    }
    
    override init(_ value: String, isMinusAllow: Bool) throws {
        try super.init(value, isMinusAllow: isMinusAllow)
    }
    
    override init(_ value: Amount) {
        super.init(value)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    /// 入金かどうか
    /// - Returns: true: 入金、false:返金
    func isPayment() -> Bool {
        // 金額がプラスの場合は入金。マイナスの場合は返金
        return value > 0
    }
}
