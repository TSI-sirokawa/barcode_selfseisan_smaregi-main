//
//  CashKesaiUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/17.
//

import Foundation
import Logging
import UIKit

/// 現金決済ユースケース
final class CashKesaiUseCase: KesaiUseCaseProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState: AppState = AppState.shared
    
    /// 請求
    private var billing: BillingProtocol
    /// 現金決済状態
    private var cashKesaiState: CashKesaiState
    /// 現金取引プロトコル
    private var cashTrans: CashTransactionProtocol
    /// 取引ID
    private var transactionID: String?
    /// 入金確定が要求されたかどうかを示すフラグ
    private var wantFix = false
    /// 入金キャンセルが要求されたかどうかを示すフラグ
    /// ・入金中のみ有効
    private var wantCancel = false
    /// エラー復帰が要求されたかどうかを示すフラグ
    /// ・エラー発生中のみ有効
    private var wantErrorRestore = false
    /// エラーキャンセルが要求されたかどうかを示すフラグ
    /// ・エラー発生中のみ有効
    private var wantErrorCancel = false
    
    /// コンストラクタ
    /// - Parameters:
    ///   - billing: 請求
    ///   - cashKesai: 現金決済情報
    ///   - cashTrans: 現金取引プロトコル
    init(billing: BillingProtocol, cashKesai: CashKesaiState, cashTrans: CashTransactionProtocol) {
        self.billing = billing
        self.cashKesaiState = cashKesai
        self.cashTrans = cashTrans
    }
    
    /// 決済を開始する（決済プロトコル実装）
    func start() {
        self.log.info("\(type(of: self)): start. billing=\(self.billing)")
        
        Task.detached {
            // 取引シーケンスを実行
            await self.execTransactionSequence()
        }
    }
    
    /// 入金を確定する
    func fix() {
        self.log.info("\(type(of: self)): fix request")
        // 取引シーケンスでの入金の確定処理を要求
        wantFix = true
    }
    
    /// 決済をキャンセルする
    /// ・入金中のみ有効
    func cancel() {
        self.log.info("\(type(of: self)): cancel request")
        // 取引シーケンス内でのキャンセル処理を要求
        wantCancel = true
    }
    
    /// 決済エラーから復帰する
    /// ・エラー発生中のみ有効
    func errorRestore() {
        self.log.info("\(type(of: self)): cancel restore request")
        // エラー処理シーケンスの即時終了を要求
        wantErrorRestore = true
    }
    
    /// エラーキャンセルを要求する
    /// ・エラー発生中のみ有効
    func errorCancel() {
        self.log.info("\(type(of: self)): error cancel request")
        // 取引エラーシーケンス内でのキャンセル処理を要求
        wantErrorCancel = true
    }
    
    /// 取引シーケンスを実行する
    private func execTransactionSequence() async {
        self.log.info("\(type(of: self)): transaction sequence start")
        
        // 取引開始要求
        do {
            cashKesaiState.updateStatus(.start)
            transactionID = try await cashTrans.startTransaction(billing: billing)
            
            self.log.info("\(type(of: self)): transaction start request ok. billing=\(self.billing), transactionID=\(String(describing: self.transactionID))")
        } catch {
            self.log.error("\(type(of: self)): transaction start request error. billing=\(self.billing): \(error)")
            await execErrorSequence(error)
            return
        }
        
        // 入金中
        // ・投入金額を上位モジュールに通知
        // ・入金完了要求、もしくはキャンセル要求を受けたらループ終了
        do {
            cashKesaiState.updateStatus(.payment)
            
            var exitLoop = false
            while !exitLoop {
                // 取引状態を取得し、現金決済状態の投入金額に反映
                let trans = try await cashTrans.getTransaction(transactionID: transactionID!)
                cashKesaiState.updateDepositAmount(trans.deposit)
                
                if cashKesaiState.isEnoughDeposit {
                    cashKesaiState.updateStatus(.fixWait)
                    
                    if let isCanPayoutChange = trans.isCanPayoutChange {
                        // おつり払出し可否を更新
                        cashKesaiState.updateCanPayoutChange(isCanPayoutChange)
                    }
                }
                
                if wantCancel || cashKesaiState.cashKesaiStatus == .fixWait && wantFix {
                    exitLoop = true
                }
            }
            
            self.log.info("\(type(of: self)): deposit finish. transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState)")
        } catch {
            self.log.error("\(type(of: self)): deposit error. transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState): \(error)")
            await execErrorSequence(error)
            return
        }
        wantFix = false
        
        if wantCancel {
            wantCancel = false
            self.log.info("\(type(of: self)): deposit cancel. transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState)")
            
            // 取引をキャンセル
            await execCancelSequence()
            return
        }
        
        // 入金確定要求
        do {
            cashKesaiState.updateStatus(.fix)
            
            try await cashTrans.fixDeposit()
            self.log.info("\(type(of: self)): fix request ok. transactionID=\(String(describing: self.transactionID))")
        } catch  {
            self.log.error("\(type(of: self)): fix request error. transactionID=\(String(describing: self.transactionID)): \(error)")
            await execErrorSequence(error)
            return
        }
        
        // 入金確定中
        do {
            var exitLoop = false
            while !exitLoop {
                let trans = try await cashTrans.getTransaction(transactionID: transactionID!)
                cashKesaiState.updateDepositAmount(trans.deposit)
                
                switch trans.transactionStatus {
                case .beginDeposit:
                    // 入金中
                    if trans.fixDeposit {
                        // 入金完了が確定
                        // ・入金完了は本フラグで判定
                        exitLoop = true
                    }
                case .dispenseChange, .waitPullOut, .finish:
                    // 出金中（つり銭出金中） / つり銭抜き取り待ち / 取引完了
                    exitLoop = true
                case .cancel, .timeout:
                    throw CashTransactionError.unexpected(message: "予期せぬエラーが発生しました (\(trans.transactionStatus))")
                case .abort:
                    throw CashTransactionError.unexpected(message: "取引が強制終了されました (\(trans.transactionStatus))")
                case .failure:
                    throw CashTransactionError.unexpected(message: "取引エラーが発生しました (\(trans.transactionStatus))")
                }
            }
            
            self.log.info("\(type(of: self)): fix ok. transactionID=\(String(describing: self.transactionID))")
        } catch  {
            self.log.error("\(type(of: self)): fix wait error. transactionID=\(String(describing: self.transactionID)): \(error)")
            await execErrorSequence(error)
            return
        }
        
        // おつり払い出し中
        //・おつりがない場合は直ぐに決済完了に遷移
        do {
            var isResultSet = false
            var exitLoop = false
            while !exitLoop {
                let trans = try await cashTrans.getTransaction(transactionID: transactionID!)
                
                if !isResultSet {
                    cashKesaiState.updateDepositAmount(trans.deposit)
                    
                    // 取引結果を生成
                    appState.setKesaiResult(kesaiResult: try createKesaiResult())
                    isResultSet = true
                }
                
                // 取引ステータスを確認
                switch trans.transactionStatus {
                case .dispenseChange, .waitPullOut:
                    // 出金中（つり銭出金中） ／ つり銭抜き取り待ち
                    self.cashKesaiState.updateStatus(.change)
                    break
                case .finish:
                    // 取引結果を生成
                    cashKesaiState.updateStatus(.completed)
                    exitLoop = true
                case .beginDeposit, .cancel, .timeout:
                    throw CashTransactionError.unexpected(message: "予期せぬエラーが発生しました (\(trans.transactionStatus))")
                case .abort:
                    throw CashTransactionError.unexpected(message: "取引が強制終了されました (\(trans.transactionStatus))")
                case .failure:
                    throw CashTransactionError.unexpected(message: "取引エラーが発生しました (\(trans.transactionStatus))")
                }
            }
            
            self.log.info("\(type(of: self)): dispense change ok. transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState)")
        } catch  {
            self.log.error("\(type(of: self)): dispense change error.  transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState): \(error)")
            await execErrorSequence(error)
            return
        }
        
        self.log.info("\(type(of: self)): transaction sequence complete. transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState)")
    }
    
    func createKesaiResult() throws -> KesaiResult {
        do {
            // 決済結果を生成
            let result = KesaiResult(
                kesaiMethod: .cash,
                deposit: try Amount(cashKesaiState.depositAmount, isMinusAllow: false),
                depositCash: try Amount(cashKesaiState.depositAmount, isMinusAllow: false),
                change: try Amount(cashKesaiState.changeAmount, isMinusAllow: false),
                depositCredit: Amount.Zero)
            return result
        } catch  {
            throw CashTransactionError.unexpected(message: "create transaction result error.  transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState): \(error)")
        }
    }
    
    /// 取引キャンセルシーケンスを実行する
    func execCancelSequence() async {
        self.log.info("\(type(of: self)): cancel transaciton sequence start. transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState)")
        
        cashKesaiState.updateStatus(.cancel)
        
        // 取引をキャンセル
        do {
            try await cashTrans.cancelTransaction()
            self.log.info("\(type(of: self)): cancel transaction request ok. transactionID=\(String(describing: self.transactionID))")
        } catch  {
            self.log.error("\(type(of: self)): cancel transaction request error. error=\(error) transactionID=\(String(describing: self.transactionID)): \(error)")
            await execErrorSequence(error)
            return
        }
        
        // 預かり金払い戻し中
        //・預かり金がない場合は直ぐに決済完了に遷移
        do {
            var exitLoop = false
            while !exitLoop {
                // 取引状態を取得し、現金決済状態に反映
                let trans = try await cashTrans.getTransaction(transactionID: transactionID!)
                cashKesaiState.updateDepositAmount(trans.deposit)
                
                // 取引ステータスを確認
                switch trans.transactionStatus {
                case .beginDeposit:
                    // キャンセル後に入金中になることがあるため無視
                    break
                case .dispenseChange, .waitPullOut:
                    // 出金中（つり銭出金中） / つり銭抜き取り待ち
                    self.cashKesaiState.updateStatus(.refund)
                case .cancel:
                    // キャンセル完了
                    self.cashKesaiState.updateStatus(.cancelled)
                    exitLoop = true
                case .timeout, .finish:
                    throw CashTransactionError.unexpected(message: "予期せぬエラーが発生しました (\(trans.transactionStatus))")
                case .abort:
                    throw CashTransactionError.unexpected(message: "取引が強制終了されました (\(trans.transactionStatus))")
                case .failure:
                    throw CashTransactionError.unexpected(message: "取引エラーが発生しました (\(trans.transactionStatus))")
                }
            }
            
            self.log.info("\(type(of: self)): refund ok. transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState)")
        } catch  {
            self.log.error("\(type(of: self)): refund error. error=\(error) transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState): \(error)")
            await execErrorSequence(error)
            return
        }
        
        self.log.info("\(type(of: self)): cancel transaciton sequence complete. transactionID=\(String(describing: self.transactionID))")
    }
    
    /// 取引エラーシーケンスを実行する
    func execErrorSequence(_ error: Error) async {
        self.log.info("\(type(of: self)): error transaciton sequence start. transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState)")
        
        cashKesaiState.updateStatus(.error(message: "\(createErrorMessage(error))"))
        
        // エラー復旧要求、もしくはエラーキャンセル要求が来るまで待つ
        var currTrans: CashTransctionState?
        var currMachineState: MachineState?
        var currTransErr: Error?
        var currMachineErr: Error?
        while !wantErrorRestore && !wantErrorCancel {
            if let transactionID = transactionID {
                // 取引状態を取得
                // ・デバッグ用途
                do {
                    let trans = try await cashTrans.getTransaction(transactionID: transactionID)
                    
                    var updated = false
                    if currTrans == nil || currTrans! != trans {
                        currTrans = trans
                        updated = true
                    }
                    
                    if updated {
                        self.log.debug("\(type(of: self)): transaction monitoring. transactionID=\(String(describing: self.transactionID)), transaction=\(trans)")
                    }
                } catch {
                    var updated = false
                    if currTransErr == nil || currTransErr!.localizedDescription != error.localizedDescription {
                        currTransErr = error
                        updated = true
                    }
                    
                    if updated {
                        self.log.warning("\(type(of: self)): transaction monitoring error. error=\(error) transactionID=\(String(describing: self.transactionID)): \(error)")
                    }
                }
            }
            
            // 機器の状態を取得
            // ・デバッグ用途
            do {
                let state = try await cashTrans.getMachineStatus()
                
                var updated = false
                if currMachineState == nil || currMachineState! != state {
                    currMachineState = state
                    updated = true
                }
                
                if updated {
                    self.log.debug("\(type(of: self)): machine monitoring. transactionID=\(String(describing: self.transactionID)), state=\(state)")
                }
            } catch {
                var updated = false
                if currMachineErr == nil || currMachineErr!.localizedDescription != error.localizedDescription {
                    currMachineErr = error
                    updated = true
                }
                
                if updated {
                    self.log.warning("\(type(of: self)): machine monitoring error. error=\(error) transactionID=\(String(describing: self.transactionID)): \(error)")
                }
            }
            
            try! await Task.sleep(until: .now + .seconds(1), clock: .continuous)
        }
        wantErrorRestore = false
        
        if wantErrorCancel {
            wantErrorCancel = false
            cashKesaiState.updateStatus(.errorCancel)
            
            do {
                try await cashTrans.cancelTransaction()
                self.log.info("\(type(of: self)): cancel transaction request ok. error=\(error) transactionID=\(String(describing: self.transactionID)), cashKesaiState=\(cashKesaiState)")
            } catch {
                self.log.warning("\(type(of: self)): cancel transaction request error. error=\(error) transactionID=\(String(describing: self.transactionID)): \(error)")
            }
            
            cashKesaiState.updateStatus(.errorCancelled)
        } else {
            cashKesaiState.updateStatus(.errorRestore)
            cashKesaiState.updateStatus(.errorRestored)
        }
        
        self.log.info("\(type(of: self)): error transaciton sequence complete. transactionID=\(String(describing: self.transactionID))")
        
    }
    
    /// エラーからエラメッセージを生成する
    /// - Parameter error: エラー
    /// - Returns: エラーメッセージ
    private func createErrorMessage(_ error: Error) -> String {
        if let te = error as? CashTransactionError {
            switch te {
            case .transaction(let message):
                return message
            case .unexpected(let message):
                return message
            }
        }
        return "\(error)"
    }
}
