//
//  PatientBarcodeFinalizeViewModel.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/03/14.
//

import Foundation
import Logging
import AudioToolbox

final class PatientNoSeisanFinalizeViewModel: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState: AppState = AppState.shared
    /// アプリ設定取得サービス
    private let appSetGetSvc: AppSettingGetService = AppSettingGetService.shared
    /// 画面表示ステータス
    @Published private(set) var viewStatus = ViewStatusType.`init` {
        didSet {
            self.transitionScreen()
        }
    }
    
    /// エラー表示ダイアログ表示を制御するフラグ
    @Published var isErrAlertActive = false
    /// エラー表示ダイアログに表示するエラーメッセージ
    @Published var errAlertMsg = ""
    /// エラー表示ダイアログ表示中に定期的にサウンドを鳴らすためのタイマー
    @Published var errSoundTimer: Timer?
    
    
    /// 印刷エラー発生時による印刷停止中を示すフラグ
    private var isPrintErrPause = false
    /// 印刷エラー発生時に印刷を諦める場合に立てるフラグ
    private var isGiveupPrint = false
    /// 印刷リトライを要求するフラグ
    private var isPrintRetry = false
    /// 印刷エラー表示ダイアログ表示を制御するフラグ
    @Published var isPrintErrAlertActive = false
    /// 印刷エラー表示ダイアログに表示するエラーメッセージ
    @Published var printErrAlertMsg = ""
    /// 印刷エラー表示ダイアログ表示中に定期的にサウンドを鳴らすためのタイマー
    @Published var printErrSoundTimer: Timer?
    
    init() {
        finalize()
    }
    
    /// 取引終了処理を実行する
    private func finalize() {
        log.debug("\(type(of: self)): finalize. billing=\(appState.getBilling())")
        
        Task {
            do {
                // 患者番号請求モデルを取得
                let billing = appState.getBilling()
                let patientNoBilling = billing as! PatientNoBilling
                
                // 各種インフラを生成
                let smaregiRepo = SmaregiPlatformRepository(setting: appSetGetSvc.getMustAppSetting().smaregiSetting!)
                let tempTransPrintDataRepo = TSISmaregiMedicalRepository(setting: appSetGetSvc.getMustAppSetting().tsiSmaregiMedicalSetting!)
                let orcaRepo = ORCARepository(setting: appSetGetSvc.getMustAppSetting().orcaSetting!)
                
                // 印刷機能については、印刷シーケンスをアプリ層で実装しているため、アプリ層から取得
                let receptPrintSvc = AppState.shared.getMustReceiptPrintService()
                
                // 取引終了処理サービスを実行
                try await PatientSeisanFinalizeService(
                    patientNoBilling: patientNoBilling,
                    kesaiResult: appState.getKesaiResult(),
                    transResultRepo: smaregiRepo,
                    tempTransRepo: smaregiRepo,
                    tempTransAddItemRepo: tempTransPrintDataRepo,
                    receiptPrint: receptPrintSvc,
                    shunoRepo: orcaRepo).exec()
            } catch {
                log.error("\(type(of: self)): error has occurred: \(error)")
                updateViewStatus(.error(message: "\(error)"))
                return
            }
            
            // 印刷リトライ用ループ
            // ・印刷に失敗した場合は再印刷を行うためのダイアログを表示する
            while(true) {
                if isGiveupPrint {
                    // 印刷を諦める
                    return
                }
                
                if isPrintErrPause {
                    // 印刷エラー発生による停止中
                    if isPrintRetry {
                        isPrintRetry = false
                        isPrintErrPause = false
                        
                        // 印刷リトライ要求
                        await AppState.shared.getMustReceiptPrintService().restart()
                    }
                    
                    do {
                        try await Task.sleep(for: .milliseconds(100))
                    } catch {}
                    continue
                }
                
                do {
                    try await AppState.shared.getMustReceiptPrintService().wait()
                    break
                } catch {
                    log.error("\(type(of: self)): print error: \(error)")
                    isPrintErrPause = true
                    updateViewStatus(.printError(message: ""))
                }
            }
            
            // 完了
            updateViewStatus(.completed)
        }
    }
    
    func errorOK() {
        log.debug("\(type(of: self)): error ok. curr=\(viewStatus)")
        
        errSoundTimer?.invalidate()
        errSoundTimer = nil
        
        updateViewStatus(.completed)
    }
    
    /// 印刷を諦める（印刷エラー発生時）
    func giveupPrint() {
        log.debug("\(type(of: self)): giveup print. curr=\(viewStatus)")
        
        printErrSoundTimer?.invalidate()
        printErrSoundTimer = nil
        
        isGiveupPrint = true
        
        updateViewStatus(.completed)
    }
    
    /// 印刷を再開する（印刷エラー発生時）
    func retryPrint() {
        log.debug("\(type(of: self)): retry print. curr=\(viewStatus)")
        
        printErrSoundTimer?.invalidate()
        printErrSoundTimer = nil
        
        isPrintRetry = true
    }
    
    private func updateViewStatus(_ newStatus: ViewStatusType) {
        DispatchQueue.main.async {
            if self.viewStatus != newStatus {
                self.log.info("\(type(of: self)): update state. prev=\(self.viewStatus), new=\(newStatus)")
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
            log.error("\(type(of: self)): error has occurred: \(message)")
            
            errAlertMsg = message
            isErrAlertActive = true
            
            // まずは即時に警告音を鳴らし、その後は一定間隔で警告音を鳴らす
            AudioServicesPlaySystemSound(SystemSoundID(1005))
            errSoundTimer = Timer.scheduledTimer(
                withTimeInterval: 10,
                repeats: true,
                block: { timer in
                    AudioServicesPlaySystemSound(SystemSoundID(1005))
                })
        case .printError(let message):
            log.error("\(type(of: self)): print error has occurred: \(message)")
            
            printErrAlertMsg = message
            isPrintErrAlertActive = true
            
            // まずは即時に警告音を鳴らし、その後は一定間隔で警告音を鳴らす
            AudioServicesPlaySystemSound(SystemSoundID(1005))
            printErrSoundTimer = Timer.scheduledTimer(
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
        case .completed:
            // 次画面に遷移
            appState.nextScreen()
        default:
            break
        }
    }
}

extension PatientNoSeisanFinalizeViewModel {
    /// 取引終了処理画面表示ステータス種別
    enum ViewStatusType: Equatable {
        ///  初期化中
        case `init`
        /// 決済完了
        case completed
        /// 決済エラー中
        case error(message: String)
        /// 印刷エラー発生
        case printError(message: String)
    }
}
