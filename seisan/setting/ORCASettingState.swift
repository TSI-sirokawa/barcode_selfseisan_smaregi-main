//
//  ORCASettingState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2024/04/10.
//

import Foundation
import Logging

// ORCA通信設定状態
final class ORCASettingState: SettingCheckProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// 証明書を配置するディレクト名
    static let CERT_DIR_NAME = "Cert"
    
    var orcaEnvType: ORCARepository.ORCAEnvType {
        didSet {
            if orcaEnvType != oldValue {
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
    /// クライアント証明書ファイルは、WebORCAの場合のみ必要。オンプレの場合は不要
    var clientCertFile: FileSetting {
        didSet {
            if clientCertFile != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var clientCertPassword: String {
        didSet {
            if clientCertPassword != oldValue {
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
    var apiKey: String {
        didSet {
            if apiKey != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var clientPassword: String {
        didSet {
            if clientPassword != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var karteUid: String {
        didSet {
            if karteUid != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var shunoCashID: String {
        didSet {
            if shunoCashID != oldValue {
                // 現バージョンでは、現金の入金方法コードは通信確認に使用しないため、
                // 更新時に通信確認をクリアしない
                // clearTestResult()
                validateSetting()
            }
        }
    }
    var shunoCreditID: String {
        didSet {
            if shunoCreditID != oldValue {
                // 現バージョンでは、クレジットの入金方法コードは通信確認に使用しないため、
                // 更新時に通信確認をクリアしない
                // clearTestResult()
                validateSetting()
            }
        }
    }
    
    /// バリデーション結果
    var isOrcaEnvTypeOK = false
    var isBaseUrlStrOK = false
    var isClientCertFileOK = false
    var isClientCertPasswordOK = false
    var isClientIDOK = false
    var isApiKeyOK = false
    var isClientPasswordOK = false
    var isKarteUidOK = false
    var isShunoCashIDOK = false
    var isShunoCreditIDOK = false
    
    /// 通信確認結果
    var isCommTestExecuted: Bool
    var isCommTestOK: Bool
    var commTestMessage: String
    
    /// 通信設定が完了したかどうか
    var isCommSettingOK: Bool {
        get {
            return isOrcaEnvTypeOK &&
            isBaseUrlStrOK &&
            isClientCertFileOK &&
            isClientCertPasswordOK &&
            isClientIDOK &&
            isApiKeyOK &&
            isClientPasswordOK &&
            isKarteUidOK
        }
    }
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        get {
            return isOrcaEnvTypeOK &&
            isBaseUrlStrOK &&
            isClientCertFileOK &&
            isClientCertPasswordOK &&
            isClientIDOK &&
            isApiKeyOK &&
            isClientPasswordOK &&
            isKarteUidOK &&
            isShunoCashIDOK &&
            isShunoCreditIDOK
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
        return orcaEnvType.description
    }
    
    static let DEFAULT = ORCASettingState(
        orcaEnvType: ORCARepository.Setting.ORCA_ENV_TYPE.defaultValue,
        baseUrlStr: ORCARepository.Setting.BASE_URL.defaultValue,
        clientCertFile: ORCARepository.Setting.CLIENT_CERT_FILE.defaultValue,
        clientCertPassword: ORCARepository.Setting.CLIENT_CERT_PASSWORD.defaultValue,
        clientID: ORCARepository.Setting.CLIENT_ID.defaultValue,
        apiKey: ORCARepository.Setting.API_KEY.defaultValue,
        clientPassword: ORCARepository.Setting.CLIENT_PASSWORD.defaultValue,
        karteUid: ORCARepository.Setting.KARTE_UID.defaultValue,
        shunoCashID: ORCARepository.Setting.SHUNO_CASH_ID.defaultValue,
        shunoCreditID: ORCARepository.Setting.SHUNO_CREDIT_ID.defaultValue,
        isCommTestExecuted: false,
        isCommTestOK: false,
        commTestMessage: "")
    
    init(orcaEnvType: ORCARepository.ORCAEnvType,
         baseUrlStr: String,
         clientCertFile: FileSetting,
         clientCertPassword: String,
         clientID: String,
         apiKey: String,
         clientPassword: String,
         karteUid: String,
         shunoCashID: String,
         shunoCreditID: String,
         isCommTestExecuted: Bool,
         isCommTestOK: Bool,
         commTestMessage: String) {
        self.orcaEnvType = orcaEnvType
        self.baseUrlStr = baseUrlStr
        self.clientCertFile = clientCertFile
        self.clientCertPassword = clientCertPassword
        self.clientID = clientID
        self.apiKey = apiKey
        self.clientPassword = clientPassword
        self.karteUid = karteUid
        self.shunoCashID = shunoCashID
        self.shunoCreditID = shunoCreditID
        self.isCommTestExecuted = isCommTestExecuted
        self.isCommTestOK = isCommTestOK
        self.commTestMessage = commTestMessage
        
        validateSetting()
    }
    
    func validateSetting() {
        // ORCA稼働環境
        do {
            try ORCARepository.Setting.ORCA_ENV_TYPE.validate(orcaEnvType)
            isOrcaEnvTypeOK = true
        } catch {
            isOrcaEnvTypeOK = false
        }
        
        // 日医標準レセプトソフトHAORIのエンドポイントURL
        do {
            try ORCARepository.Setting.BASE_URL.validate(baseUrlStr)
            isBaseUrlStrOK = true
        } catch {
            isBaseUrlStrOK = false
        }
        
        if orcaEnvType == .Web {
            // WebORCAの場合
            
            // クライアント証明書ファイル（PKCS12#形式）
            do {
                try ORCARepository.Setting.CLIENT_CERT_FILE.validate(clientCertFile)
                isClientCertFileOK = true
            } catch {
                isClientCertFileOK = false
            }
            
            // クライアント証明書のパスワード
            do {
                try ORCARepository.Setting.CLIENT_CERT_PASSWORD.validate(clientCertPassword)
                isClientCertPasswordOK = true
            } catch {
                isClientCertPasswordOK = false
            }
            
            // APIキー
            do {
                try ORCARepository.Setting.API_KEY.validate(apiKey)
                isApiKeyOK = true
            } catch {
                isApiKeyOK = false
            }
            
            isClientPasswordOK = true
        } else {
            // オンプレの場合
            isClientCertFileOK = true
            isClientCertPasswordOK = true
            isApiKeyOK = true
            
            // クライアントパスワード
            do {
                try ORCARepository.Setting.CLIENT_PASSWORD.validate(clientPassword)
                isClientPasswordOK = true
            } catch {
                isClientPasswordOK = false
            }
        }
        
        // クライアントID
        do {
            try ORCARepository.Setting.CLIENT_ID.validate(clientID)
            isClientIDOK = true
        } catch {
            isClientIDOK = false
        }
        
        // カルテID
        do {
            try ORCARepository.Setting.KARTE_UID.validate(karteUid)
            isKarteUidOK = true
        } catch {
            isKarteUidOK = false
        }
        
        // 現金の入金方法コード
        do {
            try ORCARepository.Setting.SHUNO_CASH_ID.validate(shunoCashID)
            isShunoCashIDOK = true
        } catch {
            isShunoCashIDOK = false
        }
        
        // クレジットの入金方法コード
        do {
            try ORCARepository.Setting.SHUNO_CREDIT_ID.validate(shunoCreditID)
            isShunoCreditIDOK = true
        } catch {
            isShunoCreditIDOK = false
        }
    }
    
    func getSetting() -> ORCARepository.Setting? {
        do {
            guard let baseUrl = URL(string: baseUrlStr) else {
                throw SettingError(ORCARepository.Setting.BASE_URL.errorMessage)
            }
            
            let setting = try ORCARepository.Setting(
                orcaEnvType: orcaEnvType,
                baseUrl: baseUrl,
                clientCertFile: clientCertFile,
                clientCertPassword: clientCertPassword,
                clientID: clientID,
                apiKey: apiKey,
                clientPassword: clientPassword,
                karteUid: karteUid,
                shunoCashID: shunoCashID,
                shunoCreditID: shunoCreditID)
            return setting
        } catch {
            log.error("\(type(of: self)): create setting eror: \(error)")
            return nil
        }
    }
    
    func getSettingForCommTest() -> ORCARepository.Setting? {
        do {
            guard let baseUrl = URL(string: baseUrlStr) else {
                throw SettingError(ORCARepository.Setting.BASE_URL.errorMessage)
            }
            
            // 通信確認向けの設定を生成
            let setting = try ORCARepository.Setting(
                orcaEnvType: orcaEnvType,
                baseUrl: baseUrl,
                clientCertFile: clientCertFile,
                clientCertPassword: clientCertPassword,
                clientID: clientID,
                apiKey: apiKey,
                clientPassword: clientPassword,
                karteUid: karteUid)
            return setting
        } catch {
            log.error("\(type(of: self)): create setting eror: \(error)")
            return nil
        }
    }
    
    /// アプリ動作環境の初期化処理を行う
    static func execEnvInit() {
        let logDirUrl = getClientCertDirUrl()
        do {
            try FileManager.default.createDirectory(at: logDirUrl, withIntermediateDirectories: true)
        } catch {
            print("create certs dir in document dir error: \(error)")
            return
        }
    }
    
    /// クライアント証明書格納先ディレクトリURL（端末内のディレクトリパス）を取得
    /// - Returns: クライアント証明書格納先ディレクトリURL
    static func getClientCertDirUrl() -> URL {
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dirUrl = docURL.appendingPathComponent(ORCASettingState.CERT_DIR_NAME)
        return dirUrl
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> ORCASettingState {
        let  orcaEnvType = ORCARepository.ORCAEnvType.parse(
            str: repo.load(key: "ORCASettingState.orcaEnvType"),
            defaultValue: DEFAULT.orcaEnvType)
        
        var clientCertFile = DEFAULT.clientCertFile
        if let clientCertFileData: Data = repo.load(key: "ORCASettingState.clientCertFile") {
            do {
                clientCertFile = try JSONDecoder().decode(FileSetting.self, from: clientCertFileData)
            } catch {
                print("\(type(of: self)): ORCASettingState.clientCertFile json decode error")
            }
        }
        
        var karteUid: String? = repo.load(key: "ORCASettingState.karteUid") as String?
        if karteUid == nil {
            // 初回作成時は保存する
            karteUid = DEFAULT.karteUid
            repo.save(key: "ORCASettingState.karteUid", value: karteUid)
        }
        
        return ORCASettingState(
            orcaEnvType: orcaEnvType,
            baseUrlStr: repo.load(key: "ORCASettingState.baseUrlStr") ?? DEFAULT.baseUrlStr,
            clientCertFile: clientCertFile,
            clientCertPassword: repo.load(key: "ORCASettingState.clientCertPassword") ?? DEFAULT.clientCertPassword,
            clientID: repo.load(key: "ORCASettingState.clientID") ?? DEFAULT.clientID,
            apiKey: repo.load(key: "ORCASettingState.apiKey") ?? DEFAULT.apiKey,
            clientPassword: repo.load(key: "ORCASettingState.clientPassword") ?? DEFAULT.clientPassword,
            karteUid: karteUid!,
            shunoCashID: repo.load(key: "ORCASettingState.shunoCashID") ?? DEFAULT.shunoCashID,
            shunoCreditID: repo.load(key: "ORCASettingState.shunoCreditID") ?? DEFAULT.shunoCreditID,
            isCommTestExecuted: repo.load(key: "ORCASettingState.isCommTestExecuted") ?? DEFAULT.isCommTestExecuted,
            isCommTestOK: repo.load(key: "ORCASettingState.isCommTestOK") ?? DEFAULT.isCommTestOK,
            commTestMessage: repo.load(key: "ORCASettingState.commTestMessage") ?? DEFAULT.commTestMessage)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: ORCASettingState) throws {
        let clientCertFileData = try JSONEncoder().encode(state.clientCertFile)
        
        repo.save(key: "ORCASettingState.orcaEnvType", value: state.orcaEnvType.rawValue)
        repo.save(key: "ORCASettingState.baseUrlStr", value: state.baseUrlStr)
        repo.save(key: "ORCASettingState.clientCertFile", value: clientCertFileData)
        repo.save(key: "ORCASettingState.clientCertPassword", value: state.clientCertPassword)
        repo.save(key: "ORCASettingState.clientID", value: state.clientID)
        repo.save(key: "ORCASettingState.apiKey", value: state.apiKey)
        repo.save(key: "ORCASettingState.clientPassword", value: state.clientPassword)
        repo.save(key: "ORCASettingState.karteUid", value: state.karteUid)
        repo.save(key: "ORCASettingState.shunoCashID", value: state.shunoCashID)
        repo.save(key: "ORCASettingState.shunoCreditID", value: state.shunoCreditID)
        repo.save(key: "ORCASettingState.isCommTestExecuted", value: state.isCommTestExecuted)
        repo.save(key: "ORCASettingState.isCommTestOK", value: state.isCommTestOK)
        repo.save(key: "ORCASettingState.commTestMessage", value: state.commTestMessage)
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
