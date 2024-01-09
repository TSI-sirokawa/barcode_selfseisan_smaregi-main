//
//  LogSettingState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/02/02.
//

import Foundation
import Logging

final class LogSettingState: SettingCheckProtocol {
    var isOutputEnable: Bool {
        didSet {
            if isOutputEnable != oldValue {
                validateSetting()
            }
        }
    }
    var logLevel: Logger.Level {
        didSet {
            if logLevel != oldValue {
                validateSetting()
            }
        }
    }
    var rotationCount: Int {
        didSet {
            if rotationCount != oldValue {
                validateSetting()
            }
        }
    }
    
    /// バリデーション結果
    var isOutputEnableOK = false
    var isLogLevelOK = false
    var isRotationCountOK = false
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        get {
            // 設定項目が増えた場合はここに項目をAND条件で追加
            return isRotationCountOK &&
            isLogLevelOK &&
            isRotationCountOK
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
        return ""
    }
    
    static let DEFAULT = LogSettingState(
        isOutputEnable:  AnyLogger.Setting.IS_OUTPUT_ENABLE.defaultValue,
        logLevel: AnyLogger.Setting.LOG_LEVEL.defaultValue,
        rotationCount: FileLogger.Setting.ROTATION_COUNT.defaultValue)
    
    init(isOutputEnable: Bool, logLevel: Logger.Level, rotationCount: Int) {
        self.isOutputEnable = isOutputEnable
        self.logLevel = logLevel
        self.rotationCount = rotationCount
        
        validateSetting()
    }
    
    func validateSetting() {
        do {
            try AnyLogger.Setting.IS_OUTPUT_ENABLE.validate(isOutputEnable)
            isOutputEnableOK = true
        } catch {
            isOutputEnableOK = false
        }
        do {
            try AnyLogger.Setting.LOG_LEVEL.validate(logLevel)
            isLogLevelOK = true
        } catch {
            isLogLevelOK = false
        }
        do {
            try FileLogger.Setting.ROTATION_COUNT.validate(rotationCount)
            isRotationCountOK = true
        } catch {
            isRotationCountOK = false
        }
    }
    
    func getSetting() -> (AnyLogger.Setting, FileLogger.Setting) {
        let logSetting = AnyLogger.Setting(
            isOutputEnable: isOutputEnable,
            logLevel: logLevel)
        
        let fileLogsetting = FileLogger.Setting(
            rotationCount: rotationCount)
        
        return (logSetting, fileLogsetting)
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> LogSettingState {
        let logLevel = Logger.Level.parse(str: repo.load(key: "LogSettingState.logLevel"), defaultValue: .info)
        
        return LogSettingState(
            isOutputEnable: repo.load(key: "LogSettingState.isOutputEnable") ?? DEFAULT.isOutputEnable,
            logLevel: logLevel,
            rotationCount: repo.load(key: "LogSettingState.rotationCount") ?? DEFAULT.rotationCount)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: LogSettingState) {
        repo.save(key: "LogSettingState.isOutputEnable", value: state.isOutputEnable)
        repo.save(key: "LogSettingState.logLevel", value: state.logLevel.rawValue)
        repo.save(key: "LogSettingState.rotationCount", value: state.rotationCount)
    }
}
