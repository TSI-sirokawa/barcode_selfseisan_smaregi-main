//
//  MIUProgramSettingState.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/08/02.
//

import Foundation
import Logging

// MIU連携プログラム設定状態
final class MIUProgramSettingState: SettingCheckProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    var baseUrlStr: String {
        didSet {
            if baseUrlStr != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var httpResWaitSec: Int {
        didSet {
            if httpResWaitSec != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    
    /// バリデーション結果
    var isBaseUrlStrOK = false
    var isHTTPResWaitSecOK = false
    
    /// 通信確認結果
    var isCommTestExecuted: Bool
    var isCommTestOK: Bool
    var commTestMessage: String
    
    /// 通信設定が完了したかどうか
    var isCommSettingOK: Bool {
        get {
            return isBaseUrlStrOK &&
            isHTTPResWaitSecOK
        }
    }
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        get {
            return isBaseUrlStrOK &&
            isHTTPResWaitSecOK
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
        return ""
    }
    
    static let DEFAULT = MIUProgramSettingState(
        baseUrlStr: MIUProgram.Setting.BASE_URL.defaultValue,
        httpResWaitSec: MIUProgram.Setting.HTTP_RES_WAIT_SEC.defaultValue,
        isCommTestExecuted: false,
        isCommTestOK: false,
        commTestMessage: "")
    
    init(baseUrlStr: String,
         httpResWaitSec: Int,
         isCommTestExecuted: Bool,
         isCommTestOK: Bool,
         commTestMessage: String) {
        self.baseUrlStr = baseUrlStr
        self.httpResWaitSec = httpResWaitSec
        self.isCommTestExecuted = isCommTestExecuted
        self.isCommTestOK = isCommTestOK
        self.commTestMessage = commTestMessage
        
        validateSetting()
    }
    
    func validateSetting() {
        // MIU連携プログラムAPIのエンドポイントURL
        do {
            try MIUProgram.Setting.BASE_URL.validate(baseUrlStr)
            isBaseUrlStrOK = true
        } catch {
            isBaseUrlStrOK = false
        }
        
        // HTTPレスポンス待ち時間[秒]
        do {
            try MIUProgram.Setting.HTTP_RES_WAIT_SEC.validate(httpResWaitSec)
            isHTTPResWaitSecOK = true
        } catch {
            isHTTPResWaitSecOK = false
        }
    }
    
    func getSetting() -> MIUProgram.Setting? {
        do {
            guard let baseUrl = URL(string: baseUrlStr) else {
                throw SettingError(MIUProgram.Setting.BASE_URL.errorMessage)
            }
            
            let setting = try MIUProgram.Setting(
                baseUrl: baseUrl,
                httpResWaitSec: httpResWaitSec)
            return setting
        } catch {
            log.error("\(type(of: self)): create setting eror: \(error)")
            return nil
        }
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> MIUProgramSettingState {
        return MIUProgramSettingState(
            baseUrlStr: repo.load(key: "MIUProgramSettingState.baseUrlStr") ?? DEFAULT.baseUrlStr,
            httpResWaitSec: repo.load(key: "MIUProgramSettingState.httpResWaitSec") ?? DEFAULT.httpResWaitSec,
            isCommTestExecuted: repo.load(key: "MIUProgramSettingState.isCommTestExecuted") ?? DEFAULT.isCommTestExecuted,
            isCommTestOK: repo.load(key: "MIUProgramSettingState.isCommTestOK") ?? DEFAULT.isCommTestOK,
            commTestMessage: repo.load(key: "MIUProgramSettingState.commTestMessage") ?? DEFAULT.commTestMessage)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: MIUProgramSettingState) {
        repo.save(key: "MIUProgramSettingState.baseUrlStr", value: state.baseUrlStr)
        repo.save(key: "MIUProgramSettingState.httpResWaitSec", value: state.httpResWaitSec)
        repo.save(key: "MIUProgramSettingState.isCommTestExecuted", value: state.isCommTestExecuted)
        repo.save(key: "MIUProgramSettingState.isCommTestOK", value: state.isCommTestOK)
        repo.save(key: "MIUProgramSettingState.commTestMessage", value: state.commTestMessage)
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
