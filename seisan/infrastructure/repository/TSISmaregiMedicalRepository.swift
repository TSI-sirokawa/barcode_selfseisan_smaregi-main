//
//  TSISmaregiMedicalRepository.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/18.
//

import Foundation
import Logging

/// TSIクラウドスマレジForMedical 取引履歴+α項目リポジトリ
final class TSISmaregiMedicalRepository: TemporaryTransacitonAddItemProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    let setting: Setting
    private var accessToken: AccessToken?
    
    init(setting: Setting) {
        self.setting = setting
    }
    
    /// 通信テストを実施する
    func execCommTest() async throws {
        defer {
            // テスト時に発行したアクセストークンは破棄する
            accessToken = nil
        }
        
        let accessToken = try await getAccessToken()
        
        let path = "/api/item"
        let url = setting.baseUrl.appendingPathComponent(path)
        
        // URLパラメータを設定
        // ・取引IDを未指定でリクエストを送信する
        let queries: [URLQueryItem] = [
            URLQueryItem(name: "contractId", value: setting.contractID),
        ]
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.port = url.port
        components.path = url.path
        components.queryItems = queries
        
        var req = URLRequest(url: components.url!)
        req.httpMethod = "GET"
        req.setValue("close", forHTTPHeaderField: "Connection")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (resData, res) = try await URLSession.shared.data(for: req)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.other("URLResponse to HTTPURLResponse error")
        }
        
        log.info("\(type(of: self)): comm test result. url=\(String(describing: components.url)), statusCode=\(res.statusCode)")
        
        if res.statusCode == 401 {
            // 認証エラー(401)の場合は、テスト失敗とする
            throw RunError.test(createErrorMessage(statusCode: res.statusCode, errResData: resData))
        }
    }
    
    /// 仮販売追加項目を取得する
    /// - Parameter tempTranses: 仮販売配列
    /// - Returns: 仮販売追加項目配列
    func loadTempTransAddItems(tempTranses: [TemporaryTransaction]) async throws -> [TemporaryTransacitonAddItem] {
        log.trace("\(type(of: self)): load temp trans add item start. tempTranses=[\(tempTranses)]")
        
        var addItems: [TemporaryTransacitonAddItem] = []
        for tempTrans in tempTranses {
            log.trace("\(type(of: self)): find item... tempTransID=\(tempTrans.id)")
            
            let res = try await findItem(transID: tempTrans.id.value)
            
            log.info("\(type(of: self)): find item ok. tempTransID=\(tempTrans.id)")
            
            for item in res.itemList {
                var prescriptionFlg = false
                if let resFlg = item.prescriptionFlg {
                    prescriptionFlg = (resFlg == "0" ? false : true)
                }
                
                let addItem = TemporaryTransacitonAddItem(tempTransID: tempTrans.id,
                                                          reportText: item.reportText,
                                                          billText: item.billText,
                                                          prescriptionFlg: prescriptionFlg)
                addItems.append(addItem)
            }
        }
        
        return addItems
    }
    
    /// 追加項目を検索する
    /// ・検索APIに対応
    /// - Parameter transID: 取引ID
    /// - Returns: 追加項目
    private func findItem(transID: String) async throws -> FindResponse {
        let accessToken = try await getAccessToken()
        
        let path = "/api/item"
        let url = setting.baseUrl.appendingPathComponent(path)
        
        // URLパラメータを設定
        let queries: [URLQueryItem] = [
            URLQueryItem(name: "contractId", value: setting.contractID),
            URLQueryItem(name: "tranId", value: transID),
        ]
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.port = url.port
        components.path = url.path
        components.queryItems = queries
        
        log.debug("\(type(of: self)): fine item. url=\(String(describing: components.url))")
        
        var req = URLRequest(url: components.url!)
        req.httpMethod = "GET"
        req.setValue("close", forHTTPHeaderField: "Connection")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (resData, res) = try await URLSession.shared.data(for: req)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.other("URLResponse to HTTPURLResponse error. transID=\(transID)")
        }
        
        try checkResponse(resData: resData, res: res)
        
        do {
            let decoder = JSONDecoder()
            let findRes = try decoder.decode(FindResponse.self, from: resData)
            return findRes
        } catch {
            throw RunError.unexpectedResponse("response json decode error. transID=\(transID): \(error)")
        }
    }
    
    private func getAccessToken() async throws -> String {
        // 取得済みのアクセストークンが有効期限内なら取得済みのトークンを返す
        if accessToken != nil && (Date.now < accessToken!.expireTime) {
            return accessToken!.value
        }
        
        var isTokenGetted = false
        var retryCount = 0
        while !isTokenGetted {
            do {
                let accessTokenRes = try await execGetAccessToken()
                
                // アクセストークンをメンバ変数に保持
                accessToken = try AccessToken(value: accessTokenRes.token, expiredTimeStr: accessTokenRes.expiredTime)
                
                isTokenGetted = true
            } catch {
                retryCount += 1
                if retryCount <= 3 {
                    continue
                }
                throw error
            }
        }
        
        return accessToken!.value
    }
    
    private func execGetAccessToken() async throws -> AccessTokenResponse {
        let path = "/api/token"
        let url = setting.baseUrl.appendingPathComponent(path)
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        
        req.setValue("close", forHTTPHeaderField: "Connection")
        
        let clientCredentialData = "\(setting.clientID):\(setting.clientSecret)".data(using: .utf8)!
        let clientCredential = clientCredentialData.base64EncodedString()
        req.setValue("Basic {\(clientCredential)}", forHTTPHeaderField: "Authorization")
        
        let (resData, res) = try await URLSession.shared.data(for: req)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.other("URLResponse to HTTPURLResponse error")
        }
        
        try checkResponse(resData: resData, res: res)
        
        let accessTokenRes = try JSONDecoder().decode(AccessTokenResponse.self, from: resData)
        return accessTokenRes
    }
    
    private func checkResponse(resData: Data, res: HTTPURLResponse) throws {
        switch res.statusCode {
        case 200, 204:
            log.debug("\(type(of: self)): response ok")
            break
        case 400 ..< 500:
            throw RunError.client(createErrorMessage(statusCode: res.statusCode, errResData: resData))
        case 500 ..< 600:
            throw RunError.server(createErrorMessage(statusCode: res.statusCode, errResData: resData))
        default:
            throw RunError.unexpectedResponse(createErrorMessage(statusCode: res.statusCode, errResData: resData))
        }
    }
    
    private func createErrorMessage(statusCode: Int, errResData: Data) -> String {
        var body = ""
        if let resStr = String(data: errResData, encoding: .utf8) {
            body = resStr
        } else {
            dump(errResData, to: &body)
        }
        return "statusCode=\(statusCode), body=\(body)"
    }
}

extension TSISmaregiMedicalRepository {
    /// エラー
    enum RunError: Error {
        case test(String)
        case client(String)
        case server(String)
        case unexpectedResponse(String)
        case other(String)
    }
    
    /// 追加項目
    private final class Item: Codable {
        let crtDate: String
        let updDate: String
        let contractId: String
        let tranId: String
        let patientNum: String
        let slipNum: String
        /// 診療費請求書兼領収書
        let reportText: String?
        /// 診療費明細書
        let billText: String?
        let prescriptionFlg: String?
        
        enum CodingKeys: String, CodingKey {
            case crtDate = "crtDate"
            case updDate = "updDate"
            case contractId = "contractId"
            case tranId = "tranId"
            case patientNum = "patientNum"
            case slipNum = "slipNum"
            case reportText = "reportText"
            case billText = "billText"
            case prescriptionFlg = "prescriptionFlg"
        }
    }
    
    /// 検索APIのレスポンス
    private final class FindResponse: Codable {
        let itemList: [Item]
    }
    
    /// アクセストークンレスポンス
    private final class AccessTokenResponse: Codable {
        let token: String
        let userName: String
        let expiredTime: String
        
        enum CodingKeys: String, CodingKey {
            case token
            case userName
            case expiredTime
        }
    }
    
    /// アクセストークン
    private final class AccessToken {
        let value: String
        let expireTime: Date
        
        init(value: String, expiredTimeStr: String) throws {
            self.value = value
            
            let dateFormatter = ISO8601DateFormatter()
            // オプション設定
            // ・withInternetDateTime: yyyy-MM-ddTHH:mm:ssZ形式の解析に必須
            // ・withFractionalSeconds: ミリ秒解析に必須
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let expiredTime = dateFormatter.date(from: expiredTimeStr) else {
                throw RunError.unexpectedResponse("access token expiredTime is invalid. expiredTime=\(expiredTimeStr)")
            }
            self.expireTime = expiredTime
        }
    }
}
