//
//  RoutingViewModel.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/04/23.
//

import Foundation
import Logging

/// ルーティングビューモデル
final class RoutingViewModel: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState = AppState.shared
    /// アプリ設定取得サービス
    private let appSetGetSvc = AppSettingGetService.shared
    /// インフラ管理
    private let infraMgr = InfraManager.shared
    
    /// 待機画面の表示通知
    func notifStanbyScreenDisplay() {
        // アプリケーション動作の初期化処理を行う
        
        if !appSetGetSvc.isAppSettingOK() {
            // アプリ設定が完了していない場合はアプリ動作は行えない
            return
        }
        
        // インフラ層インスタンスを更新
        if appSetGetSvc.getMustAppSetting().isUseReceiptPrinter {
            // レシートプリンタを使用する場合
            infraMgr.updateEPosPrinter(setting: appSetGetSvc.getMustAppSetting().eposPrinterSetting!)
        }
        
        // アプリ状態を更新
        var seisanType = SeisanType.ReceiptSeisan
        switch appSetGetSvc.getMustAppSetting().barcodeType {
        case .ReceiptBarcord:
            seisanType = .ReceiptSeisan
        case .PatientCardBarcord:
            seisanType = .PatientCardSeisan
        }
        appState.setBehavior(
            seisanType: seisanType,
            isCashUse: appSetGetSvc.getMustAppSetting().isCashUse(),
            isCreditUse: appSetGetSvc.getMustAppSetting().isCreditUse())
        
        // 精算毎の情報をクリア
        appState.clearSeisanVariables()
        
        // レシート印刷サービスを生成
        if appSetGetSvc.getMustAppSetting().isUseReceiptPrinter {
            // レシートプリンタを使用する場合
            appState.getReceiptPrintService()?.close()
            let receiptPrintService = ReceiptPrintService(receiptPrint: infraMgr.eposPrinter)
            appState.setReceiptPrintService(receiptPrintService: receiptPrintService)
        }
        
        // カスタマーディスプレイの有効／無効を反映
        infraMgr.setCustomerDisplayEnable(appSetGetSvc.getMustAppSetting().customerDisplaySetting.isEnable)
        
        // HTTPサーバの起動／再起動（設定変更時）／停止を行う
        if let httpServerSetting = appSetGetSvc.getMustAppSetting().httpServerSetting {
            infraMgr.startHTTPServer(
                httpSrvSetting: httpServerSetting,
                errorCallback: { error in
                    // HTTPサーバ起動エラーコールバック
                    // ここでは何もしない
                }
            )
        } else {
            infraMgr.stopHTTPServer()
        }
    }
    
    /// 決済方法選択画面の表示通知
    func notifKesaiSelectDisplay() {
        if let receiptPrintService = appState.getReceiptPrintService() {
            receiptPrintService.connect()
        }
    }
}
