//
//  CashTransactionProtocol.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/26.
//

import Foundation

/// 現金取引プロトコル
protocol CashTransactionProtocol {
    /// 取引を開始する
    /// - Parameter billing: 請求
    /// - Returns: 取引ID
    func startTransaction(billing: BillingProtocol) async throws -> String
    
    /// 取引状態を取得する
    /// - Parameter transactionID: 取引ID
    /// - Returns: 現金取引状態
    func getTransaction(transactionID: String) async throws -> CashTransctionState
    
    /// 指定金額の払出しが可能かどうか
    /// - Parameter amount: 払い出したい金額[円] 
    /// - Returns: true:払い出し可、false:払い出し不可
    func canPayoutChange(amount: Int) async throws -> Bool
    
    /// 入金完了を要求する
    func fixDeposit() async throws
    
    /// 取引をキャンセルする
    func cancelTransaction() async throws
    
    /// 機器の状態を取得する
    /// - Returns: 機器の状態
    func getMachineStatus() async throws -> MachineState 
}
