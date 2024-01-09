//
//  TSISmaregiMedicalSettingState.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/26.
//

import Foundation
import Logging

// TSIクラウドスマレジForMedical取引履歴+α
final class TSISmaregiMedicalSettingState: SettingCheckProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    var contractID: String {
        didSet {
            if contractID != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var baseUrlStr: String {
        didSet {
            if baseUrlStr != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var clientID: String {
        didSet {
            if clientID != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var clientSecret: String {
        didSet {
            if clientSecret != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    
    /// バリデーション結果
    var isContractIDOK = false
    var isBaseUrlStrOK = false
    var isClientIDOK = false
    var isClientSecretOK = false
    
    /// 通信確認結果
    var isCommTestExecuted: Bool
    var isCommTestOK: Bool
    var commTestMessage: String
    
    /// 通信設定が完了したかどうか
    var isCommSettingOK: Bool {
        get {
            return isContractIDOK &&
            isBaseUrlStrOK &&
            isClientIDOK &&
            isClientSecretOK
        }
    }
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        get {
            return isContractIDOK &&
            isBaseUrlStrOK &&
            isClientIDOK &&
            isClientSecretOK
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
    
    static let DEFAULT = TSISmaregiMedicalSettingState(
        contractID: TSISmaregiMedicalRepository.Setting.CONTRACT_ID.defaultValue,
        baseUrlStr: TSISmaregiMedicalRepository.Setting.BASE_URL.defaultValue,
        clientID: TSISmaregiMedicalRepository.Setting.CLIENT_ID.defaultValue,
        clientSecret: TSISmaregiMedicalRepository.Setting.CLIENT_SECRET.defaultValue,
        isCommTestExecuted: false,
        isCommTestOK: false,
        commTestMessage: "")
    
    init(contractID: String,
         baseUrlStr: String,
         clientID: String,
         clientSecret: String,
         isCommTestExecuted: Bool,
         isCommTestOK: Bool,
         commTestMessage: String) {
        self.contractID = contractID
        self.baseUrlStr = baseUrlStr
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.isCommTestExecuted = isCommTestExecuted
        self.isCommTestOK = isCommTestOK
        self.commTestMessage = commTestMessage
        
        validateSetting()
    }
    
    func validateSetting() {
        do {
            try TSISmaregiMedicalRepository.Setting.CONTRACT_ID.validate(contractID)
            isContractIDOK = true
        } catch {
            isContractIDOK = false
        }
        
        do {
            try TSISmaregiMedicalRepository.Setting.BASE_URL.validate(baseUrlStr)
            isBaseUrlStrOK = true
        } catch {
            isBaseUrlStrOK = false
        }
        
        do {
            try TSISmaregiMedicalRepository.Setting.CLIENT_ID.validate(clientID)
            isClientIDOK = true
        } catch {
            isClientIDOK = false
        }
        
        do {
            try TSISmaregiMedicalRepository.Setting.CLIENT_SECRET.validate(clientSecret)
            isClientSecretOK = true
        } catch {
            isClientSecretOK = false
        }
    }
    
    func getSetting() -> TSISmaregiMedicalRepository.Setting? {
        do {
            guard let baseUrl = URL(string: baseUrlStr) else {
                throw SettingError(TSISmaregiMedicalRepository.Setting.CONTRACT_ID.errorMessage)
            }
            
            let setting = TSISmaregiMedicalRepository.Setting(
                contractID: contractID,
                baseUrl: baseUrl,
                clientID: clientID,
                clientSecret: clientSecret)
            return setting
        } catch {
            log.error("\(type(of: self)): create setting eror: \(error)")
            return nil
        }
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> TSISmaregiMedicalSettingState {
        return TSISmaregiMedicalSettingState(
            contractID: repo.load(key: "TSISmaregiMedicalSettingState.contractID") ?? DEFAULT.contractID,
            baseUrlStr: repo.load(key: "TSISmaregiMedicalSettingState.baseUrlStr") ?? DEFAULT.baseUrlStr,
            clientID: repo.load(key: "TSISmaregiMedicalSettingState.clientID") ?? DEFAULT.clientID,
            clientSecret: repo.load(key: "TSISmaregiMedicalSettingState.clientSecret") ?? DEFAULT.clientID,
            isCommTestExecuted: repo.load(key: "TSISmaregiMedicalSettingState.isCommTestExecuted") ?? DEFAULT.isCommTestExecuted,
            isCommTestOK: repo.load(key: "TSISmaregiMedicalSettingState.isCommTestOK") ?? DEFAULT.isCommTestOK,
            commTestMessage: repo.load(key: "TSISmaregiMedicalSettingState.commTestMessage") ?? DEFAULT.commTestMessage)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: TSISmaregiMedicalSettingState) {
        repo.save(key: "TSISmaregiMedicalSettingState.contractID", value: state.contractID)
        repo.save(key: "TSISmaregiMedicalSettingState.baseUrlStr", value: state.baseUrlStr)
        repo.save(key: "TSISmaregiMedicalSettingState.clientID", value: state.clientID)
        repo.save(key: "TSISmaregiMedicalSettingState.clientSecret", value: state.clientSecret)
        repo.save(key: "TSISmaregiMedicalSettingState.isCommTestExecuted", value: state.isCommTestExecuted)
        repo.save(key: "TSISmaregiMedicalSettingState.isCommTestOK", value: state.isCommTestOK)
        repo.save(key: "TSISmaregiMedicalSettingState.commTestMessage", value: state.commTestMessage)
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
