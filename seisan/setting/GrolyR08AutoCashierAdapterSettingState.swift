//
//  GrolyR08AutoCashierAdapterSettingState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/25.
//

import Foundation
import Logging

/// グローリーR08設定状態
final class GrolyR08AutoCashierAdapterSettingState: SettingCheckProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    var ipAddr: String {
        didSet {
            if ipAddr != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var port: UInt16 {
        didSet {
            if port != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var commTimeoutSec: Int {
        didSet {
            if commTimeoutSec != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    
    /// バリデーション結果
    var isIPAddrOK = false
    var isPortOK = false
    var isCommTimeoutSecOK = false
    
    /// 通信確認結果
    var isCommTestExecuted: Bool
    var isCommTestOK: Bool
    var commTestMessage: String
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        get {
            // 設定項目が増えた場合はここに項目をAND条件で追加
            return isIPAddrOK &&
            isPortOK &&
            isCommTimeoutSecOK
        }
    }
    /// テストが完了したかどうか
    var isTestOK: Bool {
        get {
            // テスト項目が増えた場合はここに項目をAND条件で追加
            return isCommTestOK
        }
    }
    
    /// 設定内容を端的に説明するサマリ
    var shortSummary: String {
        return "グローリーR08"
    }
    
    static let DEFAULT = GrolyR08AutoCashierAdapterSettingState(
        ipAddr: GrolyR08AutoCashierAdapter.Setting.IPADDR.defaultValue,
        port: GrolyR08AutoCashierAdapter.Setting.PORT.defaultValue,
        commTimeoutSec: GrolyR08AutoCashierAdapter.Setting.COMM_TIMEOUT_SEC.defaultValue,
        isCommTestExecuted: false,
        isCommTestOK: false,
        commTestMessage: "")
    
    init(ipAddr: String,
         port: UInt16,
         commTimeoutSec: Int,
         isCommTestExecuted: Bool,
         isCommTestOK: Bool,
         commTestMessage: String) {
        self.ipAddr = ipAddr
        self.port = port
        self.commTimeoutSec = commTimeoutSec
        self.isCommTestExecuted = isCommTestExecuted
        self.isCommTestOK = isCommTestOK
        self.commTestMessage = commTestMessage
        
        validateSetting()
    }
    
    func setUse() {
        
    }
    
    func setNoUse() {
        
    }
    
    func validateSetting() {
        do {
            try GrolyR08AutoCashierAdapter.Setting.IPADDR.validate(ipAddr)
            isIPAddrOK = true
        } catch {
            isIPAddrOK = false
        }
        
        do {
            try GrolyR08AutoCashierAdapter.Setting.PORT.validate(port)
            isPortOK = true
        } catch {
            isPortOK = false
        }
        
        do {
            try GrolyR08AutoCashierAdapter.Setting.COMM_TIMEOUT_SEC.validate(commTimeoutSec)
            isCommTimeoutSecOK = true
        } catch {
            isCommTimeoutSecOK = false
        }
    }
    
    func getSetting() -> GrolyR08AutoCashierAdapter.Setting? {
        do {
            let setting = try GrolyR08AutoCashierAdapter.Setting(
                ipAddr: ipAddr,
                port: port,
                commTimeoutSec: commTimeoutSec)
            return setting
        } catch {
            log.error("\(type(of: self)): create setting eror: \(error)")
            return nil
        }
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> GrolyR08AutoCashierAdapterSettingState {
        return GrolyR08AutoCashierAdapterSettingState(
            ipAddr: repo.load(key: "GrolyR08AutoCashierAdapterSettingState.ipAddr") ?? DEFAULT.ipAddr,
            port: repo.load(key: "GrolyR08AutoCashierAdapterSettingState.port") ?? DEFAULT.port,
            commTimeoutSec: repo.load(key: "GrolyR08AutoCashierAdapterSettingState.commTimeoutSec") ?? DEFAULT.commTimeoutSec,
            isCommTestExecuted: repo.load(key: "GrolyR08AutoCashierAdapterSettingState.isCommTestExecuted") ?? DEFAULT.isCommTestExecuted,
            isCommTestOK: repo.load(key: "GrolyR08AutoCashierAdapterSettingState.isCommTestOK") ?? DEFAULT.isCommTestOK,
            commTestMessage: repo.load(key: "GrolyR08AutoCashierAdapterSettingState.commTestMessage") ?? DEFAULT.commTestMessage)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: GrolyR08AutoCashierAdapterSettingState) {
        repo.save(key: "GrolyR08AutoCashierAdapterSettingState.ipAddr", value: state.ipAddr)
        repo.save(key: "GrolyR08AutoCashierAdapterSettingState.port", value: state.port)
        repo.save(key: "GrolyR08AutoCashierAdapterSettingState.commTimeoutSec", value: state.commTimeoutSec)
        repo.save(key: "GrolyR08AutoCashierAdapterSettingState.isCommTestExecuted", value: state.isCommTestExecuted)
        repo.save(key: "GrolyR08AutoCashierAdapterSettingState.isCommTestOK", value: state.isCommTestOK)
        repo.save(key: "GrolyR08AutoCashierAdapterSettingState.commTestMessage", value: state.commTestMessage)
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
    
    func clearTestResult() {
        commTestMessage = ""
        isCommTestOK = false
        isCommTestExecuted = false
    }
}
