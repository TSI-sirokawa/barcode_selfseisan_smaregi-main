//
//  SmaregiPlatformSettingState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/25.
//

import Foundation
import Logging

// スマレジ通信設定状態
final class SmaregiPlatformSettingState: SettingCheckProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    var contractID: String {
        didSet {
            if contractID != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var accessTokenBaseUrlStr: String {
        didSet {
            if accessTokenBaseUrlStr != oldValue {
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
    var platformAPIBaseUrlStr: String {
        didSet {
            if platformAPIBaseUrlStr != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    /// デフォルト設定を設けず、必ず入力してもらうために空白を許容するString型で定義する
    var maxDayPerRequestStr: String {
        didSet {
            if maxDayPerRequestStr != oldValue {
                // 現バージョンでは、店舗ID、端末ID、商品IDは通信確認に使用しないため、
                // 更新時に通信確認をクリアしない
                // clearTestResult()
                validateSetting()
            }
        }
    }
    /// デフォルト設定を設けず、必ず入力してもらうために空白を許容するString型で定義する
    var storeIDStr: String {
        didSet {
            if storeIDStr != oldValue {
                // 現バージョンでは、店舗ID、端末ID、商品IDは通信確認に使用しないため、
                // 更新時に通信確認をクリアしない
                // clearTestResult()
                validateSetting()
            }
        }
    }
    /// デフォルト設定を設けず、必ず入力してもらうために空白を許容するString型で定義する
    var terminalIDStr: String {
        didSet {
            if terminalIDStr != oldValue {
                // 現バージョンでは、店舗ID、端末ID、商品IDは通信確認に使用しないため、
                // 更新時に通信確認をクリアしない
                // clearTestResult()
                validateSetting()
            }
        }
    }
    /// デフォルト設定を設けず、必ず入力してもらうために空白を許容するString型で定義する
    var productIDStr: String {
        didSet {
            if productIDStr != oldValue {
                // 現バージョンでは、店舗ID、端末ID、商品IDは通信確認に使用しないため、
                // 更新時に通信確認をクリアしない
                // clearTestResult()
                validateSetting()
            }
        }
    }
    
    /// バリデーション結果
    var isContractIDOK = false
    var isAccessTokenBaseUrlStrOK = false
    var isClientIDOK = false
    var isClientSecretOK = false
    var isPlatformAPIBaseUrlStrOK = false
    var isMaxDayPerRequestStrOK = false
    var isStoreIDOK = false
    var isTerminalIDOK = false
    var isProductIDOK = false
    
    /// 通信確認結果
    var isCommTestExecuted: Bool
    var isCommTestOK: Bool
    var commTestMessage: String
    
    /// 通信設定が完了したかどうか
    var isCommSettingOK: Bool {
        get {
            return isContractIDOK &&
            isAccessTokenBaseUrlStrOK &&
            isClientIDOK &&
            isClientSecretOK &&
            isPlatformAPIBaseUrlStrOK &&
            isMaxDayPerRequestStrOK
        }
    }
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        get {
            return isContractIDOK &&
            isAccessTokenBaseUrlStrOK &&
            isClientIDOK &&
            isClientSecretOK &&
            isPlatformAPIBaseUrlStrOK &&
            isMaxDayPerRequestStrOK &&
            isStoreIDOK &&
            isTerminalIDOK &&
            isProductIDOK
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
    
    /// バーコードモードを参照する設定があるため、バーコードモードを保持
    private let selectedBarcodeState: SelectedBarcodeState
    
    static let DEFAULT = SmaregiPlatformSettingState(
        contractID: SmaregiPlatformRepository.Setting.CONTRACT_ID.defaultValue,
        accessTokenBaseUrlStr: SmaregiPlatformRepository.Setting.ACCESS_TOKEN_BASE_URL.defaultValue,
        clientID: SmaregiPlatformRepository.Setting.CLIENT_ID.defaultValue,
        clientSecret: SmaregiPlatformRepository.Setting.CLIENT_SECRET.defaultValue,
        platformAPIBaseUrlStr: SmaregiPlatformRepository.Setting.PLATFORM_API_BASE_URL.defaultValue,
        maxDayPerRequestStr: String( SmaregiPlatformRepository.Setting.MAX_DAY_PER_REQUEST.defaultValue),
        storeIDStr: "",
        terminalIDStr: "",
        productIDStr: "",
        isCommTestExecuted: false,
        isCommTestOK: false,
        commTestMessage: "",
        selectedBarcodeState: SelectedBarcodeState(selectedType: .ReceiptBarcord)   // 使用しない値
    )
    
    init(contractID: String,
         accessTokenBaseUrlStr: String,
         clientID: String,
         clientSecret: String,
         platformAPIBaseUrlStr: String,
         maxDayPerRequestStr: String,
         storeIDStr: String,
         terminalIDStr: String,
         productIDStr: String,
         isCommTestExecuted: Bool,
         isCommTestOK: Bool,
         commTestMessage: String,
         selectedBarcodeState: SelectedBarcodeState) {
        self.contractID = contractID
        self.accessTokenBaseUrlStr = accessTokenBaseUrlStr
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.platformAPIBaseUrlStr = platformAPIBaseUrlStr
        self.maxDayPerRequestStr = maxDayPerRequestStr
        self.storeIDStr = storeIDStr
        self.terminalIDStr = terminalIDStr
        self.productIDStr = productIDStr
        self.isCommTestExecuted = isCommTestExecuted
        self.isCommTestOK = isCommTestOK
        self.commTestMessage = commTestMessage
        self.selectedBarcodeState = selectedBarcodeState
        
        validateSetting()
    }
    
    func validateSetting() {
        do {
            try SmaregiPlatformRepository.Setting.CONTRACT_ID.validate(contractID)
            isContractIDOK = true
        } catch {
            isContractIDOK = false
        }
        
        do {
            try SmaregiPlatformRepository.Setting.ACCESS_TOKEN_BASE_URL.validate(accessTokenBaseUrlStr)
            isAccessTokenBaseUrlStrOK = true
        } catch {
            isAccessTokenBaseUrlStrOK = false
        }
        
        do {
            try SmaregiPlatformRepository.Setting.CLIENT_ID.validate(clientID)
            isClientIDOK = true
        } catch {
            isClientIDOK = false
        }
        
        do {
            try SmaregiPlatformRepository.Setting.CLIENT_SECRET.validate(clientSecret)
            isClientSecretOK = true
        } catch {
            isClientSecretOK = false
        }
        
        do {
            try SmaregiPlatformRepository.Setting.PLATFORM_API_BASE_URL.validate(platformAPIBaseUrlStr)
            isPlatformAPIBaseUrlStrOK = true
        } catch {
            isPlatformAPIBaseUrlStrOK = false
        }
        
        do {
            // 最大検索期間[日]/リクエスト
            guard let maxDayPerRequest = Int(maxDayPerRequestStr) else {
                throw SettingError(SmaregiPlatformRepository.Setting.MAX_DAY_PER_REQUEST.errorMessage)
            }
            
            try SmaregiPlatformRepository.Setting.MAX_DAY_PER_REQUEST.validate(maxDayPerRequest)
            isMaxDayPerRequestStrOK = true
        } catch {
            isMaxDayPerRequestStrOK = false
        }
            
        if selectedBarcodeState.selectedType == .ReceiptBarcord {
            // 領収書バーコードモード時のみ
            do {
                // 店舗ID
                guard let storeID = Int(storeIDStr) else {
                    throw SettingError(SmaregiPlatformRepository.Setting.STORE_ID.errorMessage)
                }
                
                try SmaregiPlatformRepository.Setting.STORE_ID.validate(storeID)
                isStoreIDOK = true
            } catch {
                isStoreIDOK = false
            }
            do {
                // 商品ID
                guard let productID = Int64(productIDStr) else {
                    throw SettingError(SmaregiPlatformRepository.Setting.PRODUCT_ID.errorMessage)
                }
                
                try SmaregiPlatformRepository.Setting.PRODUCT_ID.validate(productID)
                isProductIDOK = true
            } catch {
                isProductIDOK = false
            }
        } else {
            isStoreIDOK = true
            isProductIDOK = true
        }
        
        do {
            // 端末ID
            guard let terminalID = Int(terminalIDStr) else {
                throw SettingError(SmaregiPlatformRepository.Setting.TERMINAL_ID.errorMessage)
            }
            
            try SmaregiPlatformRepository.Setting.TERMINAL_ID.validate(terminalID)
            isTerminalIDOK = true
        } catch {
            isTerminalIDOK = false
        }
    }
    
    func getSetting() -> SmaregiPlatformRepository.Setting? {
        do {
            guard let accessTokenBaseUrl = URL(string: accessTokenBaseUrlStr) else {
                throw SettingError(SmaregiPlatformRepository.Setting.ACCESS_TOKEN_BASE_URL.errorMessage)
            }
            guard let platformAPIBaseUrl = URL(string: platformAPIBaseUrlStr) else {
                throw SettingError(SmaregiPlatformRepository.Setting.PLATFORM_API_BASE_URL.errorMessage)
            }
            guard let maxDayPerRequest = Int(maxDayPerRequestStr) else {
                throw SettingError(SmaregiPlatformRepository.Setting.MAX_DAY_PER_REQUEST.errorMessage)
            }
            guard let terminalID = Int(terminalIDStr) else {
                throw SettingError(SmaregiPlatformRepository.Setting.TERMINAL_ID.errorMessage)
            }
            
            switch selectedBarcodeState.selectedType {
            case .ReceiptBarcord:
                // 領収書バーコードモード時のみ
                guard let storeID = Int(storeIDStr) else {
                    throw SettingError(SmaregiPlatformRepository.Setting.STORE_ID.errorMessage)
                }
                guard let productID = Int64(productIDStr) else {
                    throw SettingError(SmaregiPlatformRepository.Setting.PRODUCT_ID.errorMessage)
                }
                
                let setting = try SmaregiPlatformRepository.Setting(
                    contractID: contractID,
                    accessTokenBaseUrl: accessTokenBaseUrl,
                    clientID: clientID,
                    clientSecret: clientSecret,
                    platformAPIBaseUrl: platformAPIBaseUrl,
                    maxDayPerRequest: maxDayPerRequest,
                    storeID: storeID,
                    terminalID: terminalID,
                    productID: productID)
                return setting
            case .PatientCardBarcord:
                // 領収書バーコードモード時のみ
                let setting = try SmaregiPlatformRepository.Setting(
                    contractID: contractID,
                    accessTokenBaseUrl: accessTokenBaseUrl,
                    clientID: clientID,
                    clientSecret: clientSecret,
                    platformAPIBaseUrl: platformAPIBaseUrl,
                    maxDayPerRequest: maxDayPerRequest,
                    storeID: nil,
                    terminalID: terminalID,
                    productID: nil)
                return setting
            }
        } catch {
            log.error("\(type(of: self)): create setting eror: \(error)")
            return nil
        }
    }
    
    /// 通信設定確認のために、店舗ID、端末ID、商品ID（通信設定以外の設定項目）が未設定でも設定を返すメソッドを設ける。
    /// ※getSettingメソッドは、店舗ID、端末ID、商品IDが未設定の場合に例外を投げるため
    /// ※可能であれば、店舗ID、端末ID、商品IDを絡めた通信確認にしたい。その場合は、getSettingメソッドに一本化する
    func getSettingForCommTest() -> SmaregiPlatformRepository.Setting? {
        do {
            guard let accessTokenBaseUrl = URL(string: accessTokenBaseUrlStr) else {
                throw SettingError(SmaregiPlatformRepository.Setting.ACCESS_TOKEN_BASE_URL.errorMessage)
            }
            guard let platformAPIBaseUrl = URL(string: platformAPIBaseUrlStr) else {
                throw SettingError(SmaregiPlatformRepository.Setting.PLATFORM_API_BASE_URL.errorMessage)
            }
            guard let maxDayPerRequest = Int(maxDayPerRequestStr) else {
                throw SettingError(SmaregiPlatformRepository.Setting.MAX_DAY_PER_REQUEST.errorMessage)
            }
            
            let setting = try SmaregiPlatformRepository.Setting(
                contractID: contractID,
                accessTokenBaseUrl: accessTokenBaseUrl,
                clientID: clientID,
                clientSecret: clientSecret,
                platformAPIBaseUrl: platformAPIBaseUrl,
                maxDayPerRequest: maxDayPerRequest,
                storeID: 1,
                terminalID: 1,
                productID: 1)
            return setting
        } catch {
            log.error("\(type(of: self)): create setting for comm test eror: \(error)")
            return nil
        }
    }
    
    static func load(repo: AppSettingRepositoryProtocol,
                     selectedBarcodeState: SelectedBarcodeState) -> SmaregiPlatformSettingState {
        return SmaregiPlatformSettingState(
            // 本当はcontactIDではなく、contractIDだがキーだけは後方互換のためにそのままとする
            contractID: repo.load(key: "SmaregiPlatformSettingState.contactID") ?? DEFAULT.contractID,
            accessTokenBaseUrlStr: repo.load(key: "SmaregiPlatformSettingState.accessTokenBaseUrlStr") ?? DEFAULT.accessTokenBaseUrlStr,
            clientID: repo.load(key: "SmaregiPlatformSettingState.clientID") ?? DEFAULT.clientID,
            clientSecret: repo.load(key: "SmaregiPlatformSettingState.clientSecret") ?? DEFAULT.clientID,
            platformAPIBaseUrlStr: repo.load(key: "SmaregiPlatformSettingState.platformAPIBaseUrlStr") ?? DEFAULT.platformAPIBaseUrlStr,
            maxDayPerRequestStr: repo.load(key: "SmaregiPlatformSettingState.maxDayPerRequestStr") ?? DEFAULT.maxDayPerRequestStr,
            storeIDStr: repo.load(key: "SmaregiPlatformSettingState.storeIDStr") ?? DEFAULT.storeIDStr,
            terminalIDStr: repo.load(key: "SmaregiPlatformSettingState.terminalIDStr") ?? DEFAULT.terminalIDStr,
            productIDStr: repo.load(key: "SmaregiPlatformSettingState.productIDStr") ?? DEFAULT.productIDStr,
            isCommTestExecuted: repo.load(key: "SmaregiPlatformSettingState.isCommTestExecuted") ?? DEFAULT.isCommTestExecuted,
            isCommTestOK: repo.load(key: "SmaregiPlatformSettingState.isCommTestOK") ?? DEFAULT.isCommTestOK,
            commTestMessage: repo.load(key: "SmaregiPlatformSettingState.commTestMessage") ?? DEFAULT.commTestMessage,
            selectedBarcodeState: selectedBarcodeState)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: SmaregiPlatformSettingState) {
        // 本当はcontactIDではなく、contractIDだがキーだけは後方互換のためにそのままとする
        repo.save(key: "SmaregiPlatformSettingState.contactID", value: state.contractID)
        repo.save(key: "SmaregiPlatformSettingState.accessTokenBaseUrlStr", value: state.accessTokenBaseUrlStr)
        repo.save(key: "SmaregiPlatformSettingState.clientID", value: state.clientID)
        repo.save(key: "SmaregiPlatformSettingState.clientSecret", value: state.clientSecret)
        repo.save(key: "SmaregiPlatformSettingState.platformAPIBaseUrlStr", value: state.platformAPIBaseUrlStr)
        repo.save(key: "SmaregiPlatformSettingState.maxDayPerRequestStr", value: state.maxDayPerRequestStr)
        repo.save(key: "SmaregiPlatformSettingState.storeIDStr", value: state.storeIDStr)
        repo.save(key: "SmaregiPlatformSettingState.terminalIDStr", value: state.terminalIDStr)
        repo.save(key: "SmaregiPlatformSettingState.productIDStr", value: state.productIDStr)
        repo.save(key: "SmaregiPlatformSettingState.isCommTestExecuted", value: state.isCommTestExecuted)
        repo.save(key: "SmaregiPlatformSettingState.isCommTestOK", value: state.isCommTestOK)
        repo.save(key: "SmaregiPlatformSettingState.commTestMessage", value: state.commTestMessage)
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
