//
//  SettingViewModel.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/18.
//

import Foundation
import Combine
import Logging

final class SettingViewModel: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// 設定対象の画面ID
    enum SettingViewID {
        case Barcode
        case PatientCardSeisan
        case MIUProgram
        case AutoCashier
        case Credit
        case Smaregi
        case TSISmaregiMedical
        case ReceiptPrint
        case ORCA
        case View
        case CustomerDisplay
        case HTTPServer
        case Log
    }
    
    /// インフラ管理
    private let infraMgr = InfraManager.shared
    
    @Published var settingView = SettingViewID.Barcode // 設定画面を開いた時の初期画面表示を変更する場合は、ここを変更する
    @Published var appSettingState: AppSettingState = AppSettingStateService.shared.load()
    @Published var isTestExecuting = false
    @Published var isAlertActive = false
    @Published var alertMessage: String = ""
    
    /// ネストされたObservableプロトコルを実装したクラスのPublishをView側で拾うためのメンバ変数定義
    private var cancellable: AnyCancellable?
    
    init() {
        /// ネストされたsObservableプロトコルを実装したクラスのPublishをView側で拾うための処理
        cancellable = appSettingState.objectWillChange.sink {
            self.objectWillChange.send()
        }
    }
    
    /// 画面表示
    func onApear() {
        // 設定状態のバリデーション
        appSettingState.validate()
    }
    
    /// アプリ設定状態を保存する
    func saveAppSettingState() {
        log.debug("\(type(of: self)): save setting state start")
        
        // 設定状態のバリデーション
        appSettingState.validate()
        
        let (anyLogSetting, fileLogSetting) = appSettingState.logSettingState.getSetting()
        LoggerManger.shared.updateLogSetting(logSetting: anyLogSetting, fileLogSetting: fileLogSetting)
        
        do {
            // 設定状態は誤りがあってもそのまま保存
            try AppSettingStateService.shared.save(appSettingState)
            log.info("\(type(of: self)): save setting state ok")
        } catch {
            log.error("\(type(of: self)): save setting state error: \(error)")
            alertMessage = "設定の保存に失敗しました。\n\(error)"
            isAlertActive = true
        }
        
        // アプリ設定を更新
        AppSettingGetService.shared.update(appSettingState.isAppSettingOK(), appSettingState.getAppSetting())
        log.info("\(type(of: self)): update app setting ok. isAppSettingOK=\(appSettingState.isAppSettingOK())")
        
        // カスタマーディスプレイの有効／無効を反映
        // 　→カスタマーディスプレイは設定画面表示中であってもブラウザで開いて確認することを想定
        infraMgr.setCustomerDisplayEnable(appSettingState.customerDisplaySettingState.isEnable)
    }
    
    /// MIU連携プログラム通信テストを実行する
    func execMIUProgramCommTest() {
        log.debug("\(type(of: self)): miu program comm test start")
        
        isTestExecuting = true
        Task {
            defer { isTestExecuting = false }
            
            do {
                try await MIUProgramTestUseCase(state: appSettingState.miuProgramSettingState).exec()
                log.debug("\(type(of: self)): miu program comm test ok")
                
                saveAppSettingState()
            } catch {
                log.error("\(type(of: self)): error has occurred: \(error)")
                saveAppSettingState()
                alertMessage = "MIU連携プログラム通信テストに失敗しました。設定を確認してください。\n\(error)"
                isAlertActive = true
            }
        }
    }
    
    /// つり銭機通信テストを実行する
    func execAutoCashierCommTest() {
        log.debug("\(type(of: self)): auto cashier comm test start")
        
        isTestExecuting = true
        Task {
            defer { isTestExecuting = false }
            
            do {
                switch appSettingState.selectedAutoCashierState.selectedType {
                case .GrolyR08:
                    try await GrolyR08CommTestUseCase(state: appSettingState.grolyR08SettingState).exec()
                case .Groly300:
                    try await Groly300CommTestUseCase(state: appSettingState.groly300SettingState).exec()
                case .NoUse:
                    // 使用しない
                    log.info("\(type(of: self)): no use")
                }
                log.debug("\(type(of: self)): auto cashier comm test ok. type=\(appSettingState.selectedAutoCashierState.selectedType)")
                
                saveAppSettingState()
            } catch {
                log.error("\(type(of: self)): error has occurred: \(error)")
                saveAppSettingState()
                alertMessage = "スマレジ通信テストに失敗しました。設定を確認してください。\n\(error)"
                isAlertActive = true
            }
        }
    }
    
    /// STORESログイン結果OKを通知する
    func noticeSTORESLoginOK() {
        STORESLoginUseCase(result: true, state: appSettingState.creditSettingState).exec()
        log.info("\(type(of: self)): STORES login ok")
        
        saveAppSettingState()
    }
    
    /// STORESログイン結果NGを通知する
    func noticeSTORESLoginNG(error: Error) {
        STORESLoginUseCase(result: false, state: appSettingState.creditSettingState).exec()
        log.error("\(type(of: self)): STORES login ng: \(error)")
        
        saveAppSettingState()
        
        alertMessage = "STORESログインに失敗しました。\(error)"
        isAlertActive = true
    }
    
    /// STORESログアウト結果OKを通知する
    func noticeSTORESLogoutOK() {
        STORESLogoutUseCase(state: appSettingState.creditSettingState).exec()
        log.info("\(type(of: self)): STORES logout ok")
        
        saveAppSettingState()
        
        alertMessage = "STORESログアウトに成功しました。"
        isAlertActive = true
    }
    
    /// スマレジ通信テストを実行する
    func execSmaregiCommTest() {
        log.info("\(type(of: self)): smaregi comm test start")
        
        guard let _ = appSettingState.smaregiSettingState.getSettingForCommTest() else  {
            return
        }
        
        isTestExecuting = true
        Task {
            do {
                defer { isTestExecuting = false }
                
                try await SmaregiCommTestUseCase(state: appSettingState.smaregiSettingState).exec()
                log.info("\(type(of: self)): smaregi comm test ok")
                
                saveAppSettingState()
            } catch {
                log.error("\(type(of: self)): smaregi comm test error: \(error)")
                saveAppSettingState()
                alertMessage = "スマレジ通信テストに失敗しました。設定を確認してください。\n\(error)"
                isAlertActive = true
            }
        }
    }
    
    /// TSIクラウドスマレジForMedical取引履歴+α通信テストを実行する
    func execTSISmaregiMedicalCommTest() {
        log.info("\(type(of: self)): tsi smaregi for medical test start")
        
        guard let _ = appSettingState.tsiSmaregiMedicalSettingState.getSetting() else  {
            return
        }
        
        isTestExecuting = true
        Task {
            defer { isTestExecuting = false }
            
            do {
                try await TSISmaregiMedicalCommTestUseCase(state: appSettingState.tsiSmaregiMedicalSettingState).exec()
                log.info("\(type(of: self)): tsi smaregi for medical test ok")
                
                saveAppSettingState()
            } catch {
                log.error("\(type(of: self)): tsi smaregi for medical test error: \(error)")
                saveAppSettingState()
                alertMessage = "通信テストに失敗しました。設定を確認してください。\n\(error)"
                isAlertActive = true
            }
        }
    }
    
    /// レシート印刷テストを実行する
    func execReceiptPrintTest() {
        log.info("\(type(of: self)): receipt print test start")
        
        guard let _ = appSettingState.receiptPrinterSettingState.getSetting() else  {
            return
        }
        
        isTestExecuting = true
        Task {
            defer { isTestExecuting = false }
            
            do {
                try await ReceiptPrintTestUseCase(state: appSettingState.receiptPrinterSettingState).exec()
                log.info("\(type(of: self)): receipt print test ok")
                
                saveAppSettingState()
            } catch {
                log.error("\(type(of: self)): receipt print error: \(error)")
                saveAppSettingState()
                alertMessage = "通信テストに失敗しました。設定を確認してください。\n\(error)"
                isAlertActive = true
            }
        }
    }
    
    /// ORCA通信テストを実行する
    func execORCACommTest() {
        log.info("\(type(of: self)): orca test start")
        
        guard let _ = appSettingState.orcaSettingState.getSettingForCommTest() else  {
            return
        }
        
        isTestExecuting = true
        Task {
            defer { isTestExecuting = false }
            
            do {
                try await ORCACommTestUseCase(state: appSettingState.orcaSettingState).exec()
                log.info("\(type(of: self)): orca test ok")
                
                saveAppSettingState()
            } catch {
                log.error("\(type(of: self)): orca test error: \(error)")
                saveAppSettingState()
                alertMessage = "通信テストに失敗しました。設定を確認してください。\n\(error)"
                isAlertActive = true
            }
        }
    }
    
    /// WiFiのIPアドレスを通知する
    /// - Parameters:
    ///   - ipAddr: WiFiのIPアドレス
    func notifyWiFiIPAddr(ipAddr: String) {
        // カスタマーディスプレイ設定状態に通知
        appSettingState.customerDisplaySettingState.notifyWiFiIPAddrAndPort(
            ipAddr: ipAddr,
            port: appSettingState.httpServerSettingState.listenPort)
        
        // HTTPサーバ設定状態に通知
        appSettingState.httpServerSettingState.notifyWiFiListenIPAddr(ipAddr: ipAddr)
    }
    
    /// WiFiのIPアドレス取得失敗を通知する
    func notifyWiFiIPAddrNG() {
        // カスタマーディスプレイ設定状態に通知
        appSettingState.customerDisplaySettingState.notifyWiFiIPAddrNG()
        
        // HTTPサーバ設定状態に通知
        appSettingState.httpServerSettingState.notifyWiFiListenIPAddrNG()
    }
    
    /// HTTPサーバ通信テストを実行する
    @MainActor
    func execHTTPServerCommTest() {
        log.info("\(type(of: self)): http server test start")
        
        isTestExecuting = true
        Task {
            defer { isTestExecuting = false }
            
            do {
                try await infraMgr.execHTTPServerHealthCheck()
                log.info("\(type(of: self)): http server test ok")
                
                appSettingState.httpServerSettingState.setCommTestOK()
                
                saveAppSettingState()
            } catch {
                log.error("\(type(of: self)): http server test error: \(error)")
                
                appSettingState.httpServerSettingState.setCommTestNG()
                
                saveAppSettingState()
                alertMessage = "通信テストに失敗しました。設定を確認してください。\n\(error)"
                isAlertActive = true
            }
        }
    }
}
