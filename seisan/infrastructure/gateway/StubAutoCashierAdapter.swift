//
//  DummyAutoCashierAdapter.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/06.
//

import Foundation

/// 自動つり銭機スタブ
final class StubAutoCashierAdapter: CashTransactionProtocol {
    private var billingAmount: BillingAmount?
    private var isFixDeposit = false
    private var isCancel = false
    private var getTransCallCount = 0
    
    /// 投入金額
    private var deposit = 0
    /// 投入タイマー
    private var depositTimer: Timer?
    /// 出金タイマー
    private var waitPulloOutTimer: Timer?
    /// 出金抜き取りが終了したかどうか
    private var isPullOutEnd = false
    
    /// キャンセル出金モード
    private var isWaitPullOutMode = true
    /// おつり不足モード
    private var isNoChangeMode = false
    
    func startTransaction(billing: BillingProtocol) async throws -> String {
        billingAmount = billing.amount
        DispatchQueue.main.async {
            self.depositTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in  self.onDepositTimerTimeup(timer: timer) })
        }
        return "test"
    }
    
    /// 投入タイマーのコールバックメソッド
    private func onDepositTimerTimeup(timer: Timer) {
        var newDeposit = 0
        if deposit < billingAmount!.value {
            newDeposit = deposit + (billingAmount!.value/2)
        } else if isWaitPullOutMode && deposit < billingAmount!.value + 500 {
            // 投入金額を請求金額より500円多くする
            newDeposit = deposit + 500
        } else {
            timer.invalidate()
            return
        }
        
        deposit = newDeposit
    }
    
    func getTransaction(transactionID: String) async throws -> CashTransctionState {
        
        try await Task.sleep(until: .now + .seconds(0.5), clock: .continuous)
        
        defer {
            getTransCallCount += 1
        }
        
        if isFixDeposit {
            // 投入完了
            if deposit > billingAmount!.value && !isPullOutEnd {
                // 投入金額が請求金額より多い場合は、まず「つり銭抜き取り待ち」を返し、
                // しばらくしてから「時引キャンセル」を返す
                
                if waitPulloOutTimer == nil {
                    DispatchQueue.main.sync {
                        waitPulloOutTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { timer in  self.onWaitPullOutTimerTimeup(timer: timer) })
                    }
                }
                
                return CashTransctionState(transactionID: "test",
                                           transactionStatus: .waitPullOut, // つり銭抜き取り待ち
                                           total: billingAmount?.value ?? 0,
                                           deposit: deposit,
                                           change: deposit - (billingAmount?.value ?? 0),
                                           isCanPayoutChange: true,
                                           dispensedCash: deposit,
                                           fixDeposit: false,
                                           seqNo: 1,
                                           startDate: "")
            }
            
            return CashTransctionState(transactionID: "test",
                                       transactionStatus: .finish, // 取引完了
                                       total: billingAmount?.value ?? 0,
                                       deposit: deposit,
                                       change: deposit - (billingAmount?.value ?? 0),
                                       isCanPayoutChange: true,
                                       dispensedCash: deposit,
                                       fixDeposit: true,
                                       seqNo: 1,
                                       startDate: "")
        }

        if isCancel {
            // キャンセル
            if deposit > billingAmount!.value && !isPullOutEnd {
                // 投入金額が請求金額より多い場合は、まず「つり銭抜き取り待ち」を返し、
                // しばらくしてから「時引キャンセル」を返す
                
                if waitPulloOutTimer == nil {
                    DispatchQueue.main.sync {
                        waitPulloOutTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { timer in  self.onWaitPullOutTimerTimeup(timer: timer) })
                    }
                }
                
                return CashTransctionState(transactionID: "test",
                                           transactionStatus: .waitPullOut, // つり銭抜き取り待ち
                                           total: billingAmount?.value ?? 0,
                                           deposit: deposit,
                                           change: deposit - (billingAmount?.value ?? 0),
                                           isCanPayoutChange: true,
                                           dispensedCash: deposit,
                                           fixDeposit: false,
                                           seqNo: 1,
                                           startDate: "")
            }
            
            return CashTransctionState(transactionID: "test",
                                       transactionStatus: .cancel, // 取引キャンセル
                                       total: billingAmount?.value ?? 0,
                                       deposit: deposit,
                                       change: deposit - (billingAmount?.value ?? 0),
                                       isCanPayoutChange: true,
                                       dispensedCash: deposit,
                                       fixDeposit: false,
                                       seqNo: 1,
                                       startDate: "")
        }
        
        if getTransCallCount == 0 {
            return CashTransctionState(transactionID: "test",
                                       transactionStatus: .beginDeposit,
                                       total: billingAmount?.value ?? 0,
                                       deposit: deposit,
                                       change: deposit - (billingAmount?.value ?? 0),
                                       isCanPayoutChange: true,
                                       dispensedCash: deposit,
                                       fixDeposit: false,
                                       seqNo: 1,
                                       startDate: "")
        }
        
        return CashTransctionState(transactionID: "test",
                                   transactionStatus: .beginDeposit,
                                   total: billingAmount?.value ?? 0,
                                   deposit: deposit,
                                   change: deposit - (billingAmount?.value ?? 0),
                                   isCanPayoutChange: true,
                                   dispensedCash: deposit,
                                   fixDeposit: true,
                                   seqNo: 1,
                                   startDate: "")
    }
    
    /// つり銭抜き取り待ちタイマーのコールバックメソッド
    private func onWaitPullOutTimerTimeup(timer: Timer) {
        timer.invalidate()
        isPullOutEnd = true
    }
    
    func canPayoutChange(amount: Int) async throws -> Bool {
        if isNoChangeMode {
            // おつり不足モード
            return false
        }
        return true
    }
    
    func fixDeposit() async throws {
        isFixDeposit = true
    }
    
    func cancelTransaction() async throws {
        isCancel = true
    }
    
    func getMachineStatus() async throws -> MachineState {
        return MachineState(
            bill: Bill(errorCode: 0, setInfo: 0),
            coin: Bill(errorCode: 0, setInfo: 0),
            cashStatus: CashState(the1: "", the5: "", the10: "", the50: "", the100: "", the500: "", the1000: "", the2000: "", the5000: "", the10000: "", billReject: "", cassete: "", overflow: ""),
            cashWrapStatus: CashWrapState(the1: "", the5: "", the10: "", the50: "", the100: "", the500: "", reject: false, opened: false),
            seqNo: 0);
    }
}
