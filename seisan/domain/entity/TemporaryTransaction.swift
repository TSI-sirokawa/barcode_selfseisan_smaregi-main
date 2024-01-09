//
//  TemporaryTransaction.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/20.
//

import Foundation

/// 仮販売
final class TemporaryTransaction: CustomStringConvertible, Codable {
    /// 仮販売取引ID
    let id: TemporaryTransactionID
    /// 取引日時
    let time: Date
    /// ステータス（0:通常／1:完了）
    private(set) var status: StatusType
    /// 合計金額
    let total: Amount
    /// メモ
    let memo: String
    /// 店舗ID
    let storeID: String
    /// 会員ID
    let customerID: String
    /// 取引明細
    let details: [TransactionDetail]
    
    init(id: String,
         time: Date,
         status: StatusType,
         total: String,
         memo: String,
         storeID: String,
         customerID: String,
         details: [TransactionDetail]) throws {
        self.id = TemporaryTransactionID(id)
        self.time = time
        self.status = status
        self.total = try Amount(total, isMinusAllow: true) // 請求金額のマイナス値は返金を示すのでマイナス値を許容する
        self.memo = memo
        self.storeID = storeID
        self.customerID = customerID
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
    
    /// ステータスを更新する
    /// - Parameter status:ステータス
    func updateStatus(_ status: StatusType) {
        self.status = status
    }
}

extension TemporaryTransaction {
    enum StatusType: Int, Codable {
        /// 通常
        case Normal = 0
        /// 完了
        case Complete = 1
    }
}
