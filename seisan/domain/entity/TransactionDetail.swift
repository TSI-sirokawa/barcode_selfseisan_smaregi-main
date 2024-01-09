//
//  TransactionDetail.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/06.
//

import Foundation

/// 取引明細
final class TransactionDetail: CustomStringConvertible, Codable {
    /// 取引明細ID
    let transactionDetailID: TransactionDetailID
    /// 取引明細区分
    let transactionDetailDivision: String
    /// 商品ID
    /// ・以下のケースでは使用しないのでnil許容とする
    /// 　・領収書精算時の取引結果登録時（スマレジ設定値を使用する）
    let productId: String?
    /// 商品コード
    /// ・以下のケースでは使用しないのでnil許容とする
    /// 　・領収書精算時の取引結果登録時
    /// 　・診察券精算時の取引結果登録時
    let productCode: String?
    /// 販売単価
    let salesPrice: Amount
    /// 販売単価の値引き金額
    let unitDiscountPrice: Amount
    ///  数量
    let quantity: String
    /// 値引き前計 - 単品値引き計
    let unitDiscountSum: Amount
    
    init(transactionDetailID: String,
         transactionDetailDivision: String,
         productId: String?,
         productCode: String?,
         salesPrice: Amount,
         unitDiscountPrice: Amount,
         quantity: String,
         unitDiscountSum: Amount) {
        self.transactionDetailID = TransactionDetailID(transactionDetailID)
        self.transactionDetailDivision = transactionDetailDivision
        self.productId = productId
        self.productCode = productCode
        self.salesPrice = salesPrice
        self.unitDiscountPrice = unitDiscountPrice
        self.quantity = quantity
        self.unitDiscountSum = unitDiscountSum
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
