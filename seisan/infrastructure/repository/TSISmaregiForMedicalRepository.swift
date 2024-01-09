//
//  TSIMedicalRepository.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/18.
//

import Foundation
import Logging

/// TSIクラウドスマレジForMedical 取引履歴+α項目
final class TSISmaregiMedicalRepository: PrintDataProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    let setting: Setting
    private var accessToken: AccessToken?
    
    init(setting: Setting) {
        self.setting = setting
    }
    
    /// 印刷データを取得する
    /// - Parameter tempTranses: 仮取引配列
    /// - Returns: 印刷データ配列
    func loadPrintDatas(tempTranses: [TemporaryTransaction]) async throws -> [PrintData] {
        log.trace("\(type(of: self)): load print data start. tempTranses=[\(tempTranses)]")
        
        var printDatas: [PrintData] = []
        for tempTrans in tempTranses {
            let res = try await findItem(transID: tempTrans.id.value)
            for item in res.itemList {
                let printData = PrintData(tempTransID: tempTrans.id, data: item.reportJson)
                printDatas.append(printData)
            }
        }
        
        return printDatas
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
        components.path = url.path
        components.queryItems = queries
        // スマレジAPIは時刻文字列のタイムゾーン「+」がURLエンコードされていないとエラーになるが、
        // URLComponentsはデフォルトでは「+」をURLエンコードしないため、URLエンコードを行うようにする
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        log.info("\(type(of: self)): load print data. url=\(String(describing: components.url))")
        
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
            let res = try decoder.decode(FindResponse.self, from: resData)
            return res
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
        let path = "/token"
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
            if let resStr = String(data: resData, encoding: .utf8) {
                log.debug("\(type(of: self)): response ok. body=\(resStr)")
            }
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
        dump(errResData, to: &body)
        return "statusCode=\(statusCode), body=\(body)"
    }
}

extension TSISmaregiMedicalRepository {
    ///  エラー
    enum RunError: Error {
        case test(String)
        case client(String)
        case server(String)
        case notFound(String)
        case unexpectedResponse(String)
        case other(String)
    }
    
    /// 追加項目
    private final class Item: Codable {
        let contractId: String
        let tranId: String
        let reportKbn: String
        let patientNum: String
        let slipNum: String
        let reportJson: String
        let report: String
        
        enum CodingKeys: String, CodingKey {
            case contractId = "ContractId"
            case tranId = "TranId"
            case reportKbn = "ReportKbn"
            case patientNum = "PatientNum"
            case slipNum = "SlipNum"
            case reportJson = "ReportJson"  // TODO: レスポンスのプロパティ名を変更予定
            case report = "Report"
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
            
            guard let expiredTime = DateFormatter().date(from: expiredTimeStr) else {
                throw RunError.unexpectedResponse("access token expiredTime is invalid. expiredTime=\(expiredTimeStr)")
            }
            self.expireTime = expiredTime
        }
    }
}
