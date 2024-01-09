//
//  ReceiptBilling.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/03.
//

import Foundation

/// 領収書請求
final class ReceiptBilling: BillingProtocol, ObservableObject, CustomStringConvertible, Codable {
    /// 請求ローカルID
    /// ・デバッグ用途
    let localID: BillingLocalID
    /// 顧客
    var customer: Customer? {
        get {
            // 領収書請求時は顧客は無し
            return nil
        }
    }
    /// 請求金額
    let amount: BillingAmount
    
    var description: String {
        do {
            let jsonData = try JSONEncoder().encode(self)
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    init(billingAmount: BillingAmount) throws {
        self.localID = BillingLocalID()
        self.amount = billingAmount
    }
}
