//
//  CustomerDisplaySettingState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/09/24.
//

import Foundation

final class CustomerDisplaySettingState: SettingCheckProtocol {
    /// カスタマーディスプレイが有効化どうか
    var isEnable: Bool {
        didSet {
            if isEnable != oldValue {
                validateSetting()
            }
        }
    }
    
    /// カスタマーディスプレイURL ※表示のみ
    private(set) var url = ""
    
    /// カスタマーディスプレイURL表示エラー
    private(set) var urlErrMsg = ""
    
    /// バリデーション結果
    var isEnableOK = false
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        get {
            // 設定項目が増えた場合はここに項目をAND条件で追加
            return isEnableOK
        }
    }
    /// テストが完了したかどうか
    var isTestOK: Bool {
        get {
            // 現バージョンではテストがないため、設定完了状態をそのまま返す
            return isSettingOK
        }
    }
    
    /// 設定内容を端的に説明するサマリ
    var shortSummary: String {
        let summary = isEnable ? "有効": "無効"
        return summary
    }
    
    static let DEFAULT = CustomerDisplaySettingState(
        isEnable: CustomerDisplaySetting.ENABLE.defaultValue
    )
    
    init(isEnable: Bool) {
        self.isEnable = isEnable
        
        validateSetting()
    }
    
    func validateSetting() {
        // カスタマーディスプレイが有効化どうか
        do {
            try CustomerDisplaySetting.ENABLE.validate(isEnable)
            isEnableOK = true
        } catch {
            isEnableOK = false
        }
    }
    
    func getSetting() -> CustomerDisplaySetting {
        let setting = CustomerDisplaySetting(
            isEnable: isEnable
        )
        return setting
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> CustomerDisplaySettingState {
        return CustomerDisplaySettingState(
            isEnable: repo.load(key: "CustomerDisplaySettingState.isEnable") ?? DEFAULT.isEnable)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: CustomerDisplaySettingState) {
        repo.save(key: "CustomerDisplaySettingState.isEnable", value: state.isEnable)
    }
    
    /// WiFiのIPアドレスとポート番号を更新を通知する
    /// - Parameters:
    ///   - ipAddr: WiFiのIPアドレス
    ///   - port: ポート番号
    func notifyWiFiIPAddrAndPort(ipAddr: String, port: UInt16) {
        // カスタマーディスプレイURLを更新
        url = CustomerDisplayAPIController.createURL(ipAddr: ipAddr, port: port)
        
        // IPアドレス取得失敗エラーメッセージをクリア
        urlErrMsg = ""
    }
    
    /// WiFiのIPアドレス取得失敗通知
    func notifyWiFiIPAddrNG() {
        // カスタマーディスプレイURLをクリア
        url = ""
        
        // IPアドレス取得失敗エラーメッセージをセット
        urlErrMsg = "IPアドレスを取得できませんでした。WiFiの接続状態を確認してください。"
    }
}
