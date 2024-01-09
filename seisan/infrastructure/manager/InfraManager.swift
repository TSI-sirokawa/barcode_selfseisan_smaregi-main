//
//  InfraManager.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/02.
//

import Foundation
import Logging

/// 都度生成しないインフラインスタンスを管理するクラス
final class InfraManager: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// レシートプリンタ
    var eposPrinter: EPosPrinter {
        return _eposPrinter!
    }
    private var _eposPrinter: EPosPrinter?
    
    /// 音声説明管理
    let announceMgr: AnnounceManager
    
    /// カスタマーディスプレイAPIコントローラ
    private let customerDispAPICtrl: CustomerDisplayAPIController
    
    /// HTTPサーバ
    private var httpSrv: HTTPServer
    
    /// シングルトンインスタンス
    static var shared: InfraManager = .init()
    
    private init() {
        announceMgr = AnnounceManager()
        customerDispAPICtrl = CustomerDisplayAPIController(appState: AppState.shared, isEnable: false)
        httpSrv = HTTPServer()
        
        // HTTPサーバにAPIコントローラのハンドラを登録
        httpSrv.registerHandler(newHandlerMap: customerDispAPICtrl.getHandlerMap())
    }
    
    /// レシートプリンタ設定を更新する
    /// - Parameter setting: レシートプリンタ設定
    func updateEPosPrinter(setting: EPosPrinter.Setting) {
        if _eposPrinter != nil && _eposPrinter?.setting == setting {
            // 設定が変わらない場合は何もしない
            return
        }
        
        _eposPrinter?.close()
        _eposPrinter = nil
        
        _eposPrinter = EPosPrinter(setting: setting)
        _eposPrinter!.initialize()
    }
    
    /// カスタマーディスプレイの有効／無効を設定する
    /// - Parameter isEnable: true:有効、false:無効
    func setCustomerDisplayEnable(_ isEnable: Bool) {
        customerDispAPICtrl.setEnable(isEnable)
    }
    
    // HTTPサーバを起動／再起動（設定更新時）する
    func startHTTPServer(httpSrvSetting: HTTPServer.Setting, errorCallback :@escaping (Error) -> Void) {
        Task.detached {
            do {
                // HTTPサーバの待ち受けを開始
                // 　→HTTPサーバを停止するまでブロックする
                // 　→既に起動済みで設定変更がない場合は何もしないで直ぐに処理を返す
                try await self.httpSrv.start(setting: httpSrvSetting)
            } catch {
                self.log.error("start http server error: \(error)")
                
                // コールバック通知
                errorCallback(error)
            }
        }
    }
    
    /// HTTPサーバを停止する
    func stopHTTPServer() {
        do {
            try httpSrv.stop()
        } catch {
            log.error("\(type(of: self)): stop http server error: \(error)")
        }
    }
    
    /// HTTPサーバのヘルスチェックを行う
    func execHTTPServerHealthCheck() async throws {
        try await httpSrv.execHealthCheck()
    }
}

extension InfraManager {
    /// エラー
    enum RunError: Error {
        case healthcheck(String)
    }
}
