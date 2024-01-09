//
//  BillingProtocol.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/20.
//

import Foundation

/// 請求プロトコル
protocol BillingProtocol {
    /// 顧客
    var customer: Customer? { get }
    /// 請求金額
    var amount: BillingAmount { get }
}
