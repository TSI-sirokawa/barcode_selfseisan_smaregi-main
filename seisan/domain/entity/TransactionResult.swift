//
//  TransactionResult.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/28.
//

import Foundation

/// 取引結果
final class TransactionResult: CustomStringConvertible, Codable {
    /// 小計
    let subtotal: Amount
    /// 合計
    let total: Amount
    /// メモ
    let memo: String?
    /// 店舗ID
    let storeID: String?
    /// 会員ID
    let customerID: String?
    /// 決済方法
    let kesaiMethod: KesaiMethodType
    /// 預かり金
    let deposit: Amount
    /// 預かり金現金
    let depositCash: Amount
    /// つり銭
    let change: Amount
    /// 預かり金クレジット
    let depositCredit: Amount
    /// 取引明細
    let details: [TransactionDetail]
    
    init(subtotal: Amount,
         total: Amount,
         memo: String?,
         storeID: String?,
         customerID: String?,
         kesaiMethod: KesaiMethodType,
         deposit: Amount,
         depositCash: Amount,
         change: Amount,
         depositCredit: Amount,
         details: [TransactionDetail]) {
        self.subtotal = subtotal
        self.total = total
        self.memo = memo
        self.storeID = storeID
        self.customerID = customerID
        self.kesaiMethod = kesaiMethod
        self.deposit = deposit
        self.depositCash = depositCash
        self.change = change
        self.depositCredit = depositCredit
        self.details = details
    }
    
    var description: String {
        do {
            let jsonData = try JSONEncoder().encode(self)
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
