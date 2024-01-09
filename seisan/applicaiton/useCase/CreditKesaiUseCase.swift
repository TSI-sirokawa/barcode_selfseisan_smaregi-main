//
//  CreditKesaiUseCase.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/10.
//

import Foundation
import Logging

class CreditKesaiUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState: AppState = AppState.shared
    
    /// クレジット決済完了時に呼び出す
    func completeKesai() {
        log.trace("\(type(of: self)): complete")
        
        let billing = appState.getMustBilling()
        
        // 決済結果を生成
        let kesaiResult = KesaiResult(
            kesaiMethod: .credit,
            deposit: billing.amount,
            depositCash: Amount.Zero,
            change: Amount.Zero,
            depositCredit: billing.amount)
        appState.setKesaiResult(kesaiResult: kesaiResult)
    }
    
    /// クレジット決済キャンセル完了時に呼び出す
    func cancelledKesai() {
        log.trace("\(type(of: self)): cancelled")
    }
    
    /// クレジット決済失敗時に呼び出す
    /// - Parameter message: エラーメッセージ
    func errorKesai(message: String) {
        log.trace("\(type(of: self)): error")
    }
    
    /// エラー発生時の取引継続選択時に呼び出す
    func restoreKesai() {
        log.trace("\(type(of: self)): restore")
    }
    
    /// エラー発生時の取引キャンセル選択時に呼び出す
    func errorCancelKesai() {
        log.trace("\(type(of: self)): error cancel")
    }
    
}
