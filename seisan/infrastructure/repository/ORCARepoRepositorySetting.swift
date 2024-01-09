//
//  ORCARepoRepository.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/18.
//

import Foundation

/// ORCAリポジトリ
extension ORCARepository {
    /// ORCA稼働環境種別
    enum ORCAEnvType: String, CaseIterable, Codable {
        /// WebORCA
        case Web
        /// オンプレ
        case OnPremises
        
        var description: String {
            switch self {
            case .Web:
                return "WebORCA"
            case .OnPremises:
                return "オンプレ"
            }
        }
        
        static func parse(str: String?, defaultValue: ORCAEnvType) -> ORCAEnvType {
            guard let str = str else {
                return defaultValue
            }
            
            let ret = ORCAEnvType(rawValue: str) ?? defaultValue
            return ret
        }
    }
    
    final class Setting {
        /// ORCA稼働環境
        let orcaEnvType: ORCAEnvType
        /// 日医標準レセプトソフトHAORIのエンドポイントURL
        let baseUrl: URL
        /// クライアント証明書ファイル(PKCS12#形式)
        let clientCertFile: FileSetting?
        /// 　・ORCA稼働環境がWebORCAの場合に使用
        /// クライアント証明書のパスワード
        /// 　・ORCA稼働環境がWebORCAの場合に使用
        let clientCertPassword: String
        /// クライアントID
        let clientID: String
        /// APIキー
        /// 　・ORCA稼働環境がWebORCAの場合に使用
        let apiKey: String
        /// クライアントパスワード
        /// 　・ORCA稼働環境がオンプレの場合に使用
        let clientPassword: String
        /// カルテUID
        let karteUid: String
        /// 現金の入金方法コード
        /// ・入金方法情報マスタ(1041)で設定されている値：01（デフォルト）
        let shunoCashID: String
        /// クレジットの入金方法コード
        /// ・入金方法情報マスタ(1041)で設定されている値：03など（運用によって異なる）
        let shunoCreditID: String
        
        /// 生成
        /// - Parameters:
        ///   - orcaEnvType: ORCA稼働環境種別
        ///   - baseUrl: 日医標準レセプトソフトHAORIのエンドポイントURL
        ///   - clientCertFile: クライアント証明書ファイル(PKCS12#形式)
        ///   - clientCertPassword: クライアント証明書のパスワード
        ///   - clientID: クライアントID
        ///   - apiKey: APIキー
        ///   - clientPassword: クライアントパスワード
        ///   - karteUid: カルテUID
        ///   - shunoCashID: 現金の入金方法コード
        ///   - shunoCreditID: クレジットの入金方法コード
        init(orcaEnvType: ORCAEnvType,
             baseUrl: URL,
             clientCertFile: FileSetting?,
             clientCertPassword: String,
             clientID: String,
             apiKey: String,
             clientPassword: String,
             karteUid: String,
             shunoCashID: String,
             shunoCreditID: String) throws {
            self.orcaEnvType = orcaEnvType
            self.baseUrl = baseUrl
            self.clientCertFile = clientCertFile
            self.clientCertPassword = clientCertPassword
            self.clientID = clientID
            self.apiKey = apiKey
            self.clientPassword = clientPassword
            self.karteUid = karteUid
            self.shunoCashID = shunoCashID
            self.shunoCreditID = shunoCreditID
            
            try Setting.checkParam(orcaEnvType: self.orcaEnvType,
                               baseUrl: self.baseUrl,
                               clientCertFile: self.clientCertFile,
                               clientCertPassword: self.clientCertPassword,
                               clientID: self.clientID,
                               apiKey: self.apiKey,
                               clientPassword: self.clientPassword,
                               karteUid: self.karteUid)
            try Setting.SHUNO_CASH_ID.validate(shunoCashID)
            try Setting.SHUNO_CREDIT_ID.validate(shunoCreditID)
        }
        
        /// 生成（ORCA通信設定の通信確認用）
        /// - Parameters:
        ///   - orcaEnvType: ORCA稼働環境種別
        ///   - baseUrl: 日医標準レセプトソフトHAORIのエンドポイントURL
        ///   - clientCertFile: クライアント証明書ファイル(PKCS12#形式)
        ///   - clientCertPassword: クライアント証明書のパスワード
        ///   - clientID: クライアントID
        ///   - apiKey: APIキー
        ///   - clientPassword: クライアントパスワード
        ///   - karteUid: カルテUID
        init(orcaEnvType: ORCAEnvType,
             baseUrl: URL,
             clientCertFile: FileSetting?,
             clientCertPassword: String,
             clientID: String,
             apiKey: String,
             clientPassword: String,
             karteUid: String) throws {
            self.orcaEnvType = orcaEnvType
            self.baseUrl = baseUrl
            self.clientCertFile = clientCertFile
            self.clientCertPassword = clientCertPassword
            self.clientID = clientID
            self.apiKey = apiKey
            self.clientPassword = clientPassword
            self.karteUid = karteUid
            self.shunoCashID = ""
            self.shunoCreditID = ""
            
            try Setting.checkParam(orcaEnvType: self.orcaEnvType,
                               baseUrl: self.baseUrl,
                               clientCertFile: self.clientCertFile,
                               clientCertPassword: self.clientCertPassword,
                               clientID: self.clientID,
                               apiKey: self.apiKey,
                               clientPassword: self.clientPassword,
                               karteUid: self.karteUid)
        }
        
        /// パラメータチェック
        /// - Parameters:
        ///   - orcaEnvType: ORCA稼働環境種別
        ///   - baseUrl: 日医標準レセプトソフトHAORIのエンドポイントURL
        ///   - clientCertFile: クライアント証明書ファイル(PKCS12#形式)
        ///   - clientCertPassword: クライアント証明書のパスワード
        ///   - clientID: クライアントID
        ///   - apiKey: APIキー
        ///   - clientPassword: クライアントパスワード
        ///   - karteUid: カルテUID
        private static func checkParam(orcaEnvType: ORCAEnvType,
                                       baseUrl: URL,
                                       clientCertFile: FileSetting?,
                                       clientCertPassword: String,
                                       clientID: String,
                                       apiKey: String,
                                       clientPassword: String,
                                       karteUid: String) throws {
            // ORCA稼働環境は、正しいものしか受け取れないためチェックしない
            // 日医標準レセプトソフトHAORIのエンドポイントURLは、URLオブジェクトとして正しいものしか受け取れないためチェックしない
            switch orcaEnvType {
            case .Web:
                guard let clientCertFile = clientCertFile else {
                    throw SettingError("client cert is required at web orca")
                }
                try Setting.CLIENT_CERT_FILE.validate(clientCertFile)
                try Setting.CLIENT_CERT_PASSWORD.validate(clientCertPassword)
                try Setting.API_KEY.validate(apiKey)
            case .OnPremises:
                try Setting.CLIENT_PASSWORD.validate(clientPassword)
            }
            try Setting.CLIENT_ID.validate(clientID)
            try Setting.KARTE_UID.validate(karteUid)
        }
        
        static let ORCA_ENV_TYPE = SettingValueAttr(
            label: "ORCA稼働環境",
            defaultValue: ORCAEnvType.Web,
            placeHolder: "",
            errorMessage: "",
            isValidOK: { value in return true })
        
        static let BASE_URL = SettingValueAttr(
            label: "日医標準レセプトソフトHAORIのエンドポイントURL",
            defaultValue: "",
            placeHolder: "例：https://weborca.cloud.orcamo.jp/",
            errorMessage: "入力してください。",
            isValidOK: { value in return URL(string: value) != nil })
        
        static let CLIENT_CERT_FILE = SettingValueAttr(
            label: "クライアント証明書ファイル(PKCS12#形式)",
            defaultValue: FileSetting.Empty,
            placeHolder: "クライアント証明書ファイル(PKCS12#形式)",
            errorMessage: "設定してください。",
            isValidOK: { value in return value.invalid()})
        
        static let CLIENT_CERT_PASSWORD = SettingValueAttr(
            label: "クライアント証明書のパスワード",
            defaultValue: "",
            placeHolder: "クライアント証明書のパスワード",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
        
        static let CLIENT_ID = SettingValueAttr(
            label: "クライアントID",
            defaultValue: "",
            placeHolder: "クライアントID",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
        
        static let API_KEY = SettingValueAttr(
            label: "APIキー",
            defaultValue: "",
            placeHolder: "APIキー",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
        
        static let CLIENT_PASSWORD = SettingValueAttr(
            label: "クライアントパスワード",
            defaultValue: "",
            placeHolder: "クライアントパスワード",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
        
        static let KARTE_UID = SettingValueAttr(
            label: "カルテUID（自動生成）",
            defaultValue: UUID().uuidString.lowercased(),
            placeHolder: "",
            errorMessage: "",
            isValidOK: { value in return value != "" })
        
        static let SHUNO_CASH_ID = SettingValueAttr(
            label: "現金の入金方法コード",
            defaultValue: "01",
            placeHolder: "例：01",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
        
        static let SHUNO_CREDIT_ID = SettingValueAttr(
            label: "クレジットの入金方法コード",
            defaultValue: "",
            placeHolder: "例：03",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
    }
}
