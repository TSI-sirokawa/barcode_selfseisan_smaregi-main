//
//  CashKesai.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/17.
//

import Foundation

/// 現金決済状態
final class CashKesaiState: CustomStringConvertible, Codable {
    /// 値が変更された場合に呼び出すクロージャ
    var didChange: ((_ state: CashKesaiState)->())?
    
    /// 請求
    private(set) var billing: CashKesaiBilling {
        didSet {
            updateAmount()
            didChange?(self)
        }
    }
    /// 預かり金額[円]
    private(set) var depositAmount: Int = 0 {
        didSet {
            updateAmount()
            didChange?(self)
        }
    }
    /// 不足金額[円]
    private(set) var minusAmount = 0
    /// おつり[円]
    private(set) var changeAmount = 0
    /// 現金決済ステータス
    private(set) var cashKesaiStatus: CashKesaiStatusType = .`init`{
        didSet {
            didChange?(self)
        }
    }
    /// 投入金額が足りているかどうか
    var isEnoughDeposit: Bool {
        return billing.amount.value - depositAmount <= 0
    }
    
    /// おつり払出し可否
    private(set) var canPayoutChange: Bool? {
        didSet {
            didChange?(self)
        }
    }
    
    var description: String {
        do {
            let jsonData = try JSONEncoder().encode(self)
            var ret = String(data: jsonData, encoding: .utf8) ?? ""
            // getプロパティはJSON化できないため、個別に追加
            ret += "\nisEnoughDeposit=\(isEnoughDeposit), canPayoutChange=\(String(describing: canPayoutChange))"
            return ret
        } catch {
            return ""
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case billing, depositAmount, minusAmount, changeAmount
        case cashKesaiStatus
    }
    
    /// コンストラクタ
    /// - Parameter billing: 請求
    init(billing: BillingProtocol) {
        self.billing = CashKesaiBilling(customer: billing.customer, billingAmount: billing.amount)
        self.updateAmount()
    }
    
    /// 投入金額[円]を更新する
    /// - Parameter newAmount: 投入金額[円]
    func updateDepositAmount(_ newAmount: Int) {
        depositAmount = newAmount
    }
    
    /// 現金決済ステータスを更新する
    /// - Parameter newStatus: 現金決済ステータス
    func updateStatus(_ newStatus: CashKesaiStatusType) {
        cashKesaiStatus = newStatus
    }
    
    
    /// おつり払出し可否を更新する
    /// - Parameter can: おつり払出し可否
    func updateCanPayoutChange(_ can: Bool) {
        canPayoutChange = can
    }
    
    /// 請求金額と投入金額から不足金額とおつりを計算する
    private func updateAmount() {
        minusAmount = calcMinusAmount(billingAmount: billing.amount, depositAmount: depositAmount)
        changeAmount = changeAmount(billingAmount: billing.amount, depositAmount: depositAmount)
    }
    
    /// 不足金額を計算する
    /// - Parameters:
    ///   - billingAmount: 請求金額
    ///   - depositAmount: 投入金額
    /// - Returns: 不足金額
    private func calcMinusAmount(billingAmount: BillingAmount, depositAmount: Int) -> Int {
        let minusAmount = depositAmount > billingAmount.value ? 0: billingAmount.value - depositAmount
        return minusAmount
    }
    
    /// おつりを計算する
    /// - Parameters:
    ///   - billingAmount: 請求金額
    ///   - depositAmount: 投入金額
    /// - Returns: おつり
    private func changeAmount(billingAmount: BillingAmount, depositAmount: Int) -> Int {
        let changeAmount = depositAmount > billingAmount.value ? abs(billingAmount.value - depositAmount): 0
        return changeAmount
    }
}

extension CashKesaiState {
    /// 現金決済請求
    ///・BillingProtocolは「Codableプロトコル」に対応できないため、対応するためのラッパークラス
    final class CashKesaiBilling: BillingProtocol, Codable {
        /// 顧客
        var customer: Customer? {
            return _customer
        }
        /// 請求金額
        var amount: BillingAmount {
            return _amount
        }
        
        private let _customer: Customer?
        private let _amount: BillingAmount
        
        init(customer: Customer?, billingAmount: BillingAmount) {
            self._customer = customer
            self._amount = billingAmount
        }
    }
}


extension CashKesaiState {
    /// 現金決済ステータス種別
    enum CashKesaiStatusType: Equatable, Codable {
        /// 初期化中
        case `init`
        /// 決済開始中
        case start
        /// 入金確定待機中
        case fixWait
        /// 入金中
        case payment
        /// 入金確定中
        case fix
        /// おつり払い出し中
        case change
        /// 決済完了
        case completed
        /// 入金キャンセル中
        case cancel
        /// 払い戻し中
        case refund
        /// 入金キャンセル完了
        case cancelled
        /// エラー発生中
        case error(message: String)
        /// エラー復帰完了
        case errorRestore
        /// エラー復帰完了
        case errorRestored
        /// エラーキャンセル完了
        case errorCancel
        /// エラーキャンセル完了
        case errorCancelled
    }
}
