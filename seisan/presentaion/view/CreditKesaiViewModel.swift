//
//  CreditKesaiViewModel.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/10/21.
//

import Foundation
import Logging
import AudioToolbox

final class CreditKesaiViewModel: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState: AppState = AppState.shared
    /// アプリ設定取得サービス
    private let appSetGetSvc: AppSettingGetService = AppSettingGetService.shared
    /// 待機画面表示ステータス
    @Published private(set) var viewStatus = ViewStatusType.`init` {
        didSet {
            DispatchQueue.main.async {
                self.transitionScreen()
            }
        }
    }
    /// エラー表示ダイアログ表示を制御するフラグ
    @Published var isErrAlertActive = false
    /// エラー表示ダイアログに表示するエラーメッセージ
    @Published var errAlertMsg = ""
    /// エラー表示ダイアログ表示中に定期的にサウンドを鳴らすためのタイマー
    @Published var errorSoundTimer: Timer?
    
    private let creditKesaiUseCase: CreditKesaiUseCase
    
    init() {
        viewStatus = .credit
        creditKesaiUseCase = CreditKesaiUseCase()
    }
    
    func getBilling() -> BillingProtocol {
        return appState.getMustBilling()
    }
    
    /// クレジット決済完了時に呼び出す
    func completeKesai() {
        log.debug("\(type(of: self)): complete. curr=\(viewStatus)")
        creditKesaiUseCase.completeKesai()
        updateViewStatus(.completed)
    }
    
    /// クレジット決済キャンセル完了時に呼び出す
    func cancelledKesai() {
        log.debug("\(type(of: self)): cancelled. curr=\(viewStatus)")
        creditKesaiUseCase.cancelledKesai()
        updateViewStatus(.cancelled)
    }
    
    /// クレジット決済失敗時に呼び出す
    /// - Parameter message: エラーメッセージ
    func errorKesai(message: String) {
        log.debug("\(type(of: self)): error. curr=\(viewStatus)")
        creditKesaiUseCase.errorCancelKesai()
        updateViewStatus(.error(message: message))
    }
    
    /// エラー発生時の取引継続選択時に呼び出す
    func restoreKesai() {
        log.debug("\(type(of: self)): restore. curr=\(viewStatus)")
        
        errorSoundTimer?.invalidate()
        errorSoundTimer = nil
        
        creditKesaiUseCase.restoreKesai()
        updateViewStatus(.errorRestore)
    }
    
    /// エラー発生時の取引キャンセル選択時に呼び出す
    func errorCancelKesai() {
        log.debug("\(type(of: self)): error cancel. curr=\(viewStatus)")
        
        errorSoundTimer?.invalidate()
        errorSoundTimer = nil
        
        creditKesaiUseCase.errorCancelKesai()
        updateViewStatus(.errorCancelled)
    }
    
    private func updateViewStatus(_ newStatus: ViewStatusType) {
        DispatchQueue.main.async {
            if self.viewStatus != newStatus {
                self.log.debug("\(type(of: self)): update state. prev=\(self.viewStatus), new=\(newStatus)")
            }
            
            self.viewStatus = newStatus
            self.checkError()
        }
    }
    
    private func checkError() {
        var isErrAlertActive = false
        var errAlertMsg = ""
        switch self.viewStatus {
        case .error(let message):
            errAlertMsg = message
            isErrAlertActive = true
            
            // まずは即時に警告音を鳴らし、その後は一定間隔で警告音を鳴らす
            AudioServicesPlaySystemSound(SystemSoundID(1005))
            errorSoundTimer = Timer.scheduledTimer(
                withTimeInterval: 10,
                repeats: true,
                block: { timer in
                    AudioServicesPlaySystemSound(SystemSoundID(1005))
                })
        default:
            break
        }
        self.isErrAlertActive = isErrAlertActive
        self.errAlertMsg = errAlertMsg
    }
    
    /// 画面表示ステータスに応じた画面遷移を行う
    private func transitionScreen() {
        
        switch viewStatus {
        case .credit:
            break
        case .completed:
            // 次画面に遷移
            appState.nextScreen()
        case .cancelled:
            // 前画面に遷移
            appState.prevScreen()
        case .error(message: _):
            break
        case .errorRestore:
            // エラーダイアログ表示→取引継続→エラーダイアログ表示→取引継続を隙間なく繰り返すと、
            // エラーダイアログが表示されない現象が発生するため、
            // 1秒経過後に取引を再開する
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (timer: Timer) -> Void in
                self.viewStatus = .errorRestored
            })
            break
        case .errorRestored:
            self.viewStatus = .credit
        case .errorCancel:
            break
        case .errorCancelled:
            // 待機画面に遷移
            appState.returnStanbyScreen()
        default:
            break
        }
    }
}

extension CreditKesaiViewModel {
    /// クレジット決済画面表示ステータス種別
    enum ViewStatusType: Equatable {
        ///  初期化中
        case `init`
        /// クレジット決済中
        case credit
        /// 決済完了
        case completed
        /// 決済キャンセル
        case cancelled
        /// 決済エラー中
        case error(message: String)
        /// エラー復帰中
        case errorRestore
        /// エラー復帰完了
        case errorRestored
        /// エラーキャンセル中
        case errorCancel
        /// エラーキャンセル完了
        case errorCancelled
    }
}
