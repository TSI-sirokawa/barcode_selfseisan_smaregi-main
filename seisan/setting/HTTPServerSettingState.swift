//
//  HTTPServerSettingState.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/09/25.
//

import Foundation

/// HTTPサーバ設定状態
final class HTTPServerSettingState: SettingCheckProtocol {
    /// インフラ管理
    private let infraMgr = InfraManager.shared
    
    ///  HTTPサーバが有効かどうか
    var isEnable: Bool {
        didSet {
            if isEnable != oldValue {
                validateSetting()
                clearTestResult()
            }
        }
    }
    
    /// 待ち受けポート番号
    var listenPort: UInt16 {
        didSet {
            if listenPort != oldValue {
                validateSetting()
                clearTestResult()
            }
        }
    }
    
    /// WiFiのIPアドレス
    /// 　→変化する可能性があるので表示のみに使用する
    var wifiIPAddr: String = ""
    
    /// 起動エラーメッセージ
    /// 　→画面遷移で起動するので表示のみに使用する
    var listenErrMsg: String = ""
    
    /// バリデーション結果
    var isEnableOK = false
    var isListenPortOK = false
    
    /// 通信確認結果
    var isCommTestExecuted: Bool
    var isCommTestOK: Bool
    var commTestMessage: String
    
    /// 通信設定が完了したかどうか
    var isCommSettingOK: Bool {
        get {
            return isEnable &&
            isListenPortOK
        }
    }
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        get {
            // 設定項目が増えた場合はここに項目をAND条件で追加
            return isEnable &&
            isListenPortOK
        }
    }
    /// テストが完了したかどうか
    var isTestOK: Bool {
        get {
            return isCommTestOK
        }
    }
    
    /// 設定内容を端的に説明するサマリ
    var shortSummary: String {
        let summary = "\(listenPort)"
        return summary
    }
    
    static let DEFAULT = HTTPServerSettingState(
        isEnable: false,
        listenPort: HTTPServer.Setting.LISTEN_PORT.defaultValue,
        isCommTestExecuted: false,
        isCommTestOK: false,
        commTestMessage: "")
    
    init(isEnable: Bool,
         listenPort: UInt16,
         isCommTestExecuted: Bool,
         isCommTestOK: Bool,
         commTestMessage: String) {
        self.isEnable = isEnable
        self.listenPort = listenPort
        self.isCommTestExecuted = isCommTestExecuted
        self.isCommTestOK = isCommTestOK
        self.commTestMessage = commTestMessage
        
        validateSetting()
    }
    
    func validateSetting() {
        // ポート番号
        do {
            try HTTPServer.Setting.LISTEN_PORT.validate(listenPort)
            isListenPortOK = true
        } catch {
            isListenPortOK = false
        }
    }
    
    func getSetting() -> HTTPServer.Setting {
        let setting = HTTPServer.Setting(
            listenIPAddr: "0.0.0.0",    // ワイルドカードアドレス固定
            listenPort: listenPort
        )
        return setting
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> HTTPServerSettingState {
        return HTTPServerSettingState(
            isEnable: repo.load(key: "HTTPServerSettingState.isEnable") ?? DEFAULT.isEnable,
            listenPort: repo.load(key: "HTTPServerSettingState.listenPort") ?? DEFAULT.listenPort,
            isCommTestExecuted: repo.load(key: "HTTPServerSettingState.isCommTestExecuted") ?? DEFAULT.isCommTestExecuted,
            isCommTestOK: repo.load(key: "HTTPServerSettingState.isCommTestOK") ?? DEFAULT.isCommTestOK,
            commTestMessage: repo.load(key: "HTTPServerSettingState.commTestMessage") ?? DEFAULT.commTestMessage)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: HTTPServerSettingState) {
        repo.save(key: "HTTPServerSettingState.isEnable", value: state.isEnable)
        repo.save(key: "HTTPServerSettingState.listenPort", value: state.listenPort)
        repo.save(key: "HTTPServerSettingState.isCommTestExecuted", value: state.isCommTestExecuted)
        repo.save(key: "HTTPServerSettingState.isCommTestOK", value: state.isCommTestOK)
        repo.save(key: "HTTPServerSettingState.commTestMessage", value: state.commTestMessage)
    }
    
    /// HTTPサーバを起動する
    func startHTTPServer() {
        // エラーメッセージを一旦クリア
        self.listenErrMsg = ""
        
        infraMgr.startHTTPServer(
            httpSrvSetting: getSetting(),
            errorCallback: { error in
                // HTTPサーバ起動エラーコールバック
                self.listenErrMsg = "HTTPサーバの起動に失敗しました。ポート番号を変更してください。: \(error)"
            }
        )
    }
    
    /// HTTPサーバを停止する
    func stopHTTPServer() {
        // エラーメッセージをクリア
        self.listenErrMsg = ""
        
        infraMgr.announceMgr.stop()
    }
    
    /// WiFiのIPアドレスを通知する
    /// - Parameters:
    ///   - ipAddr: WiFiのIPアドレス
    func notifyWiFiListenIPAddr(ipAddr: String) {
        self.wifiIPAddr = ipAddr
    }
    
    /// WiFiのIPアドレス取得失敗を通知する
    func notifyWiFiListenIPAddrNG() {
        self.wifiIPAddr = ""
    }
    
    func setCommTestOK() {
        commTestMessage = "OK（最終確認日時：\(Date().description(with: .current))）"
        isCommTestOK = true
        isCommTestExecuted = true
    }
    
    func setCommTestNG() {
        commTestMessage = "NG（最終確認日時：\(Date().description(with: .current))）"
        isCommTestOK = false
        isCommTestExecuted = true
    }
    
    private func clearTestResult() {
        commTestMessage = ""
        isCommTestOK = false
        isCommTestExecuted = false
    }
}
