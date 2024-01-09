//
//  Groly300AutoCashierAdapterSettingState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/25.
//

import Foundation
import Logging

/// グローリー300設定状態
final class Groly300AutoCashierAdapterSettingState: SettingCheckProtocol {
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
    var connectionTimeoutSec: Int {
        didSet {
            if connectionTimeoutSec != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var commandIntervalSec: Double {
        didSet {
            if commandIntervalSec != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var smallRespBaseWaitSec: Double {
        didSet {
            if smallRespBaseWaitSec != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var smallRespRetryCount: Int {
        didSet {
            if smallRespRetryCount != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var smallRespIncTimeSec: Double {
        didSet {
            if smallRespIncTimeSec != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var largeRespBaseWaitSec: Double {
        didSet {
            if largeRespBaseWaitSec != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var largeRespRetryCount: Int {
        didSet {
            if largeRespRetryCount != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var largeRespIncTimeSec: Double {
        didSet {
            if largeRespIncTimeSec != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    
    /// バリデーション結果
    var isIPAddrOK = false
    var isPortOK = false
    var isConnectionTimeoutOK = false
    var isSmallRespBaseWaitSecOK = false
    var isSmallRespRetryCountOK = false
    var isSmallRespIncTimeSecOK = false
    var isLargeRespBaseWaitSecOK = false
    var isLargeRespRetryCountOK = false
    var isLargeRespIncTimeSecOK = false
    var isCommandIntervalSecOK = false
    
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
            isConnectionTimeoutOK &&
            isSmallRespBaseWaitSecOK &&
            isSmallRespRetryCountOK &&
            isSmallRespIncTimeSecOK &&
            isLargeRespBaseWaitSecOK &&
            isLargeRespRetryCountOK &&
            isLargeRespIncTimeSecOK &&
            isCommandIntervalSecOK
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
        return "グローリー300"
    }
    
    static let DEFAULT = Groly300AutoCashierAdapterSettingState(
        ipAddr: Groly300AutoCashierAdapter.Setting.IPADDR.defaultValue,
        port: Groly300AutoCashierAdapter.Setting.PORT.defaultValue,
        connectionTimeoutSec: Groly300AutoCashierAdapter.Setting.CONNECTION_TIMEOUT_SEC.defaultValue,
        commandIntervalSec: Groly300AutoCashierAdapter.Setting.COMMAND_INTERVAL_SEC.defaultValue,
        smallRespBaseWaitSec: Groly300AutoCashierAdapter.RespSizeSetting.SMALL_RESP_BASE_WAIT_SEC.defaultValue,
        smallRespRetryCount: Groly300AutoCashierAdapter.RespSizeSetting.SMALL_RESP_RETRY_COUNT.defaultValue,
        smallRespIncTimeSec: Groly300AutoCashierAdapter.RespSizeSetting.SMALL_RESP_INC_TIME_SEC.defaultValue,
        largeRespBaseWaitSec: Groly300AutoCashierAdapter.RespSizeSetting.LARGE_RESP_BASE_WAIT_SEC.defaultValue,
        largeRespRetryCount: Groly300AutoCashierAdapter.RespSizeSetting.LARGE_RESP_RETRY_COUNT.defaultValue,
        largeRespIncTimeSec: Groly300AutoCashierAdapter.RespSizeSetting.LARGE_RESP_INC_TIME_SEC.defaultValue,
        isCommTestExecuted: false,
        isCommTestOK: false,
        commTestMessage: "")
    
    init(ipAddr: String,
         port: UInt16,
         connectionTimeoutSec: Int,
         commandIntervalSec: Double,
         smallRespBaseWaitSec: Double,
         smallRespRetryCount: Int,
         smallRespIncTimeSec: Double,
         largeRespBaseWaitSec: Double,
         largeRespRetryCount: Int,
         largeRespIncTimeSec: Double,
         isCommTestExecuted: Bool,
         isCommTestOK: Bool,
         commTestMessage: String) {
        self.ipAddr = ipAddr
        self.port = port
        self.connectionTimeoutSec = connectionTimeoutSec
        self.commandIntervalSec = commandIntervalSec
        self.smallRespBaseWaitSec = smallRespBaseWaitSec
        self.smallRespRetryCount = smallRespRetryCount
        self.smallRespIncTimeSec = smallRespIncTimeSec
        self.largeRespBaseWaitSec = largeRespBaseWaitSec
        self.largeRespRetryCount = largeRespRetryCount
        self.largeRespIncTimeSec = largeRespIncTimeSec
        self.isCommTestOK = isCommTestOK
        self.commTestMessage = commTestMessage
        self.isCommTestExecuted = isCommTestExecuted
        self.isCommTestOK = isCommTestOK
        self.commTestMessage = commTestMessage
        
        validateSetting()
    }
    
    func validateSetting() {
        do {
            try Groly300AutoCashierAdapter.Setting.IPADDR.validate(ipAddr)
            isIPAddrOK = true
        } catch {
            isIPAddrOK = false
        }
        
        do {
            try Groly300AutoCashierAdapter.Setting.PORT.validate(port)
            isPortOK = true
        } catch {
            isPortOK = false
        }
        
        do {
            try Groly300AutoCashierAdapter.Setting.CONNECTION_TIMEOUT_SEC.validate(connectionTimeoutSec)
            isConnectionTimeoutOK = true
        } catch {
            isConnectionTimeoutOK = false
        }
        
        do {
            try Groly300AutoCashierAdapter.Setting.COMMAND_INTERVAL_SEC.validate(commandIntervalSec)
            isCommandIntervalSecOK = true
        } catch {
            isCommandIntervalSecOK = false
        }
        
        do {
            try Groly300AutoCashierAdapter.RespSizeSetting.SMALL_RESP_BASE_WAIT_SEC.validate(smallRespBaseWaitSec)
            isSmallRespBaseWaitSecOK = true
        } catch {
            isSmallRespBaseWaitSecOK = false
        }
        do {
            try Groly300AutoCashierAdapter.RespSizeSetting.SMALL_RESP_RETRY_COUNT.validate(smallRespRetryCount)
            isSmallRespRetryCountOK = true
        } catch {
            isSmallRespRetryCountOK = false
        }
        do {
            try Groly300AutoCashierAdapter.RespSizeSetting.SMALL_RESP_INC_TIME_SEC.validate(smallRespIncTimeSec)
            isSmallRespIncTimeSecOK = true
        } catch {
            isSmallRespIncTimeSecOK = false
        }
        
        do {
            try Groly300AutoCashierAdapter.RespSizeSetting.LARGE_RESP_BASE_WAIT_SEC.validate(largeRespBaseWaitSec)
            isLargeRespBaseWaitSecOK = true
        } catch {
            isLargeRespBaseWaitSecOK = false
        }
        do {
            try Groly300AutoCashierAdapter.RespSizeSetting.LARGE_RESP_RETRY_COUNT.validate(largeRespRetryCount)
            isLargeRespRetryCountOK = true
        } catch {
            isLargeRespRetryCountOK = false
        }
        do {
            try Groly300AutoCashierAdapter.RespSizeSetting.LARGE_RESP_INC_TIME_SEC.validate(largeRespIncTimeSec)
            isLargeRespIncTimeSecOK = true
        } catch {
            isLargeRespIncTimeSecOK = false
        }
    }
    
    func getSetting() -> Groly300AutoCashierAdapter.Setting? {
        do {
            let setting = try Groly300AutoCashierAdapter.Setting(
                ipAddr: ipAddr,
                port: port,
                connectionTimeoutSec: connectionTimeoutSec,
                commandIntervalSec: commandIntervalSec,
                smallSizeResp: Groly300AutoCashierAdapter.RespSizeSetting(
                    isSmallResp: true,
                    baseWaitSec: smallRespBaseWaitSec,
                    retryCount: smallRespRetryCount,
                    incTimeSec: smallRespIncTimeSec),
                largeSizeResp: Groly300AutoCashierAdapter.RespSizeSetting(
                    isSmallResp: false,
                    baseWaitSec: largeRespBaseWaitSec,
                    retryCount: largeRespRetryCount,
                    incTimeSec: largeRespIncTimeSec)
                )
            return setting
        } catch {
            log.error("\(type(of: self)): create setting eror: \(error)")
            return nil
        }
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> Groly300AutoCashierAdapterSettingState {
        return Groly300AutoCashierAdapterSettingState(
            ipAddr: repo.load(key: "Groly300AutoCashierAdapterSettingState.ipAddr") ?? DEFAULT.ipAddr,
            port: repo.load(key: "Groly300AutoCashierAdapterSettingState.port") ?? DEFAULT.port,
            connectionTimeoutSec: repo.load(key: "Groly300AutoCashierAdapterSettingState.connectionTimeoutSec") ?? DEFAULT.connectionTimeoutSec,
            commandIntervalSec: repo.load(key: "Groly300AutoCashierAdapterSettingState.commandIntervalSec") ?? DEFAULT.commandIntervalSec,
            smallRespBaseWaitSec: repo.load(key: "Groly300AutoCashierAdapterSettingState.smallRespBaseWaitSec") ?? DEFAULT.smallRespBaseWaitSec,
            smallRespRetryCount: repo.load(key: "Groly300AutoCashierAdapterSettingState.smallRespRetryCount") ?? DEFAULT.smallRespRetryCount,
            smallRespIncTimeSec: repo.load(key: "Groly300AutoCashierAdapterSettingState.smallRespIncTimeSec") ?? DEFAULT.smallRespIncTimeSec,
            largeRespBaseWaitSec: repo.load(key: "Groly300AutoCashierAdapterSettingState.largeRespBaseWaitSec") ?? DEFAULT.largeRespBaseWaitSec,
            largeRespRetryCount: repo.load(key: "Groly300AutoCashierAdapterSettingState.largeRespRetryCount") ?? DEFAULT.largeRespRetryCount,
            largeRespIncTimeSec: repo.load(key: "Groly300AutoCashierAdapterSettingState.largeRespIncTimeSec") ?? DEFAULT.largeRespIncTimeSec,
            isCommTestExecuted: repo.load(key: "Groly300AutoCashierAdapterSettingState.isCommTestExecuted") ?? DEFAULT.isCommTestOK,
            isCommTestOK: repo.load(key: "Groly300AutoCashierAdapterSettingState.isCommTestOK") ?? DEFAULT.isCommTestOK,
            commTestMessage: repo.load(key: "Groly300AutoCashierAdapterSettingState.commTestMessage") ?? DEFAULT.commTestMessage
        )
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: Groly300AutoCashierAdapterSettingState) {
        repo.save(key: "Groly300AutoCashierAdapterSettingState.ipAddr", value: state.ipAddr)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.port", value: state.port)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.connectionTimeoutSec", value: state.connectionTimeoutSec)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.commandIntervalSec", value: state.commandIntervalSec)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.smallRespBaseWaitSec", value: state.smallRespBaseWaitSec)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.smallRespRetryCount", value: state.smallRespRetryCount)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.smallRespIncTimeSec", value: state.smallRespIncTimeSec)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.largeRespBaseWaitSec", value: state.largeRespBaseWaitSec)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.largeRespRetryCount", value: state.largeRespRetryCount)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.largeRespIncTimeSec", value: state.largeRespIncTimeSec)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.isCommTestExecuted", value: state.isCommTestExecuted)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.isCommTestOK", value: state.isCommTestOK)
        repo.save(key: "Groly300AutoCashierAdapterSettingState.commTestMessage", value: state.commTestMessage)
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
