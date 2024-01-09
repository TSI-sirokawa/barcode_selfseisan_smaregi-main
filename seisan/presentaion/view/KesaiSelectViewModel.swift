//
//  KesaiSelectViewModel.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/22.
//

import Foundation
import Logging

/// 決済方法選択画面ビューモデル
final class KesaiSelectViewModel: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState: AppState = AppState.shared
    /// アプリ設定取得サービス
    private let appSetGetSvc: AppSettingGetService = AppSettingGetService.shared
    /// 顧客
    @Published var customer: Customer?
    /// 請求金額[円]
    @Published var billingAmount: Int = 0
    /// 仮販売配列
    @Published var tempTranses: [TemporaryTransaction] = []
    /// インジケータ表示が有効かどうか
    @Published var isIndicatorActive = false
    /// 入金確定時に外部システムとの連携エラーが発生したことを示すダイアログ表示を制御するフラグ
    @Published var isErrExternalAlertActive = false
    /// 外部システムとの連携エラー発生ダイアログに表示するエラーメッセージ
    @Published var errExternalAlertMsg = ""
    
    init() {
        let billing = self.appState.getMustBilling()
        
        billingAmount = billing.amount.value
        customer = billing.customer
        
        if appState.getSeisanType() == .PatientCardSeisan {
            // 診察券精算の場合、請求内訳を表示
            let patientCardBilling = appState.getMustBilling() as! PatientCardBilling
            tempTranses = patientCardBilling.tempTranses
        }
    }
    
    /// 現金決済を選択する
    func selectCashKesai() {
        log.debug("\(type(of: self)): cash is selected")
        KesaiSelectUseCase().selectCashKesai()
        
        isIndicatorActive = true
        
        Task {
            defer {
                DispatchQueue.main.async {
                    self.isIndicatorActive = false
                }
            }
            
            if appState.getSeisanType() == .PatientCardSeisan && appSetGetSvc.getMustAppSetting().isUseReceiptPrinter {
                // 診察券精算、かつ、レシートプリンタを使用する場合
                
                // 仮販売追加項目のバックグラウンド取得完了まで待つ
                if !waitTempTransAddItem() {
                    return
                }
            }
            
            DispatchQueue.main.async {
                // 現金決済画面に遷移
                self.appState.selectCashKesaiScreen()
            }
        }
    }
    
    /// クレジット決済を選択する
    func selectCreditKesai() {
        log.debug("\(type(of: self)): credit is selected")
        KesaiSelectUseCase().selectCreditKesai()
        
        isIndicatorActive = true
        
        Task {
            defer {
                DispatchQueue.main.async {
                    self.isIndicatorActive = false
                }
            }
            
            if appState.getSeisanType() == .PatientCardSeisan && appSetGetSvc.getMustAppSetting().isUseReceiptPrinter {
                // 診察券精算、かつ、レシートプリンタを使用する場合
                
                // 仮販売追加項目のバックグラウンド取得完了まで待つ
                if !waitTempTransAddItem() {
                    return
                }
            }
            
            DispatchQueue.main.async {
                // クレジット決済画面に遷移
                self.appState.selectCreditKesaiScreen()
            }
            
        }
    }
    
    /// 決済方法選択をキャンセルする
    func cancel() {
        log.debug("\(type(of: self)): cancel")
        KesaiSelectUseCase().cancel()
        
        // 前画面に遷移
        appState.prevScreen()
    }
    
    /// 仮販売追加項目のバックグラウンド取得完了まで待つ
    /// - Returns: true:取得成功、false:取得失敗
    private func waitTempTransAddItem() -> Bool {
        // 仮販売追加項目取得サービスを取得し、各種帳票の印刷を並列に行う
        // ・診療費請求書兼領収書
        // ・診療費明細書
        // ・処方箋引換券
        let tempTransAddItemBGGetSvc = AppState.shared.getMustTempTransAddItemBackgroundGetService()
        
        // 仮販売追加項目のバックグラウンド取得が完了するまで待つ
        while true {
            do {
                let addItems = try tempTransAddItemBGGetSvc.getResult()
                if addItems != nil {
                    log.info("\(type(of: self)): add items ok")
                    break
                }
                
                // 10ミリ秒間隔で監視
                Thread.sleep(forTimeInterval: 0.01)
            } catch {
                DispatchQueue.main.async {
                    self.errExternalAlertMsg = "仮販売データ取得時にエラーが発生しました。\(error)"
                    self.isErrExternalAlertActive = true
                }
                return false
            }
        }
        
        return true
    }
}
