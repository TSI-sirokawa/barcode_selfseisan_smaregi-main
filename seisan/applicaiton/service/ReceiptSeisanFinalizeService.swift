//
//  ReceiptSeisanFinalizeService.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/28.
//

import Foundation
import Logging

/// 領収書精算取引終了サービス
final class ReceiptSeisanFinalizeService {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    let receiptBilling: ReceiptBilling
    let kesaiResult: KesaiResult
    let repo: TransactionResultRepositoryProtocol
    
    init(receiptBilling: ReceiptBilling,
         kesaiResult: KesaiResult,
         repo: TransactionResultRepositoryProtocol) {
        self.receiptBilling = receiptBilling
        self.kesaiResult = kesaiResult
        self.repo = repo
    }
    
    /// 取引結果を登録する
    func exec() async throws {
        // 取引結果を生成
        let transResult = TransactionResult(
            subtotal: receiptBilling.amount,
            total: receiptBilling.amount,
            memo: nil,
            storeID: nil,
            customerID: nil,
            kesaiMethod: kesaiResult.kesaiMethod,
            deposit: kesaiResult.deposit,
            depositCash: kesaiResult.depositCash,
            change: kesaiResult.change,
            depositCredit: kesaiResult.depositCredit,
            details: [
                TransactionDetail(
                    transactionDetailID: "1",           // 取引明細ID：1(固定)
                    transactionDetailDivision: "1",     // 取引明細区分：1:通常(固定)
                    productId: nil,                     // 商品ID：スマレジ通信設定値を使用
                    productCode: nil,                   // 商品コード：
                    salesPrice: receiptBilling.amount,  // 販売単価：N円
                    unitDiscountPrice: Amount.Zero,     // 販売単価の値引き金額：領収書精算の場合、値引きはないため０円固定
                    quantity: "1",                      // 数量：1(固定)
                    unitDiscountSum: receiptBilling.amount)   // 値引き前計 - 単品値引き計：領収書精算の場合、値引きはないため販売単価と同じ
            ])
        
        // 取引結果を登録
        let transID = try await repo.registerTransaction(result: transResult)
        log.info("\(type(of: self)): upload transaction result ok. result=\(transResult), transID=\(transID)")
        return
    }
}
