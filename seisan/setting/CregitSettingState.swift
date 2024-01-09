//
//  CregitSettingState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/27.
//

import Foundation
import Logging

final class CregitSettingState: SettingCheckProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    var isStoresUse: Bool {
        didSet {
            if isStoresUse != oldValue {
                validateSetting()
            }
        }
    }
    
    /// レシートプリンタを使用するかどうか
    var isUseReceiptPrinter: Bool {
        return isStoresUse
    }
    
    /// STORESログイン結果
    var isSTORESLoginExecuted: Bool
    var isSTORESLoginOK: Bool
    var storesLoginMessage: String
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        get {
            if !isStoresUse {
                // STORES決済を使用しない場合は設定OKを返す
                return true
            }
            
            // STORESへのログインが設定とテストを兼ねているため、ログイン完了状態をそのまま返す
            // 設定項目が増えた場合はここに項目をAND条件で追加
            return isSTORESLoginOK
        }
    }
    /// テストが完了したかどうか
    var isTestOK: Bool {
        get {
            if !isStoresUse {
                // STORES決済を使用しない場合は設定OKを返す
                return true
            }
            
            // 現バージョンではSTORESへのログインが設定とテストを兼ねているため、設定完了状態をそのまま返す
            return isSettingOK
        }
    }
    
    var shortSummary: String {
        return isStoresUse ? "有効" : "無効"
    }
    
    static let DEFAULT = CregitSettingState(
        isStoresUse: false,
        isSTORESLoginExecuted: false,
        isSTORESLoginOK: false,
        storesLoginMessage: "")
    
    init(isStoresUse: Bool,
         isSTORESLoginExecuted: Bool,
         isSTORESLoginOK: Bool,
         storesLoginMessage: String) {
        self.isStoresUse = isStoresUse
        self.isSTORESLoginExecuted = isSTORESLoginExecuted
        self.isSTORESLoginOK = isSTORESLoginOK
        self.storesLoginMessage = storesLoginMessage
        
        validateSetting()
    }
    
    func validateSetting() {
        // テストが設定を兼ねているため、ここでは何もしない
    }
    
    func getSetting() -> STORES.Setting {
        let setting = STORES.Setting(isStoresUse: isStoresUse)
        return setting
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> CregitSettingState {
        return CregitSettingState(
            isStoresUse: repo.load(key: "STORESSettingState.isStoresUse") ?? DEFAULT.isStoresUse,
            isSTORESLoginExecuted: repo.load(key: "STORESSettingState.isSTORESLoginExecuted") ?? DEFAULT.isSTORESLoginExecuted,
            isSTORESLoginOK: repo.load(key: "STORESSettingState.isSTORESLoginOK") ?? DEFAULT.isSTORESLoginOK,
            storesLoginMessage: repo.load(key: "STORESSettingState.storesLoginMessage") ?? DEFAULT.storesLoginMessage)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: CregitSettingState) {
        repo.save(key: "STORESSettingState.isStoresUse", value: state.isStoresUse)
        repo.save(key: "STORESSettingState.isSTORESLoginExecuted", value: state.isSTORESLoginExecuted)
        repo.save(key: "STORESSettingState.isSTORESLoginOK", value: state.isSTORESLoginOK)
        repo.save(key: "STORESSettingState.storesLoginMessage", value: state.storesLoginMessage)
    }
    
    func setSTORESLoginOK() {
        storesLoginMessage = "OK（最終確認日時：\(Date().description(with: .current))）"
        isSTORESLoginOK = true
        isSTORESLoginExecuted = true
    }
    
    func setSTORESLoginNG() {
        storesLoginMessage = "NG（最終確認日時：\(Date().description(with: .current))）"
        isSTORESLoginOK = false
        isSTORESLoginExecuted = true
    }
    
    func setSTORESLogoutOK() {
        storesLoginMessage = ""
        isSTORESLoginOK = false
        isSTORESLoginExecuted = false
    }
}
