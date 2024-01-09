//
//  MIUProgram.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/08/01.
//

import Foundation
import Logging

/// MIU連携プログラム
final class MIUProgram: PatientSeisanPrepareProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)

    /// 設定
    let setting: Setting
    
    init(setting: Setting) {
        self.setting = setting
    }
    
    /// 通信テストを実施する
    func execCommTest() async throws {
        // HTTPレスポンスタイムアウト時間[秒]を設定
        // 　→通信テスト時のタイムアウト時間は短めに設定
        let conf = URLSessionConfiguration.default
        conf.timeoutIntervalForRequest = TimeInterval(10)
        
        let path = "/api/receipt"
        let url = setting.baseUrl.appendingPathComponent(path)
        
        // 患者番号を未指定でリクエストを送信する
        let queries: [URLQueryItem] = []
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.port = url.port
        components.path = url.path
        components.queryItems = queries
        
        var req = URLRequest(url: components.url!)
        req.httpMethod = "GET"
        req.setValue("close", forHTTPHeaderField: "Connection")
        
        let urlSession = URLSession(configuration: conf)
        let (_, res) = try await urlSession.data(for: req)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.other("URLResponse to HTTPURLResponse error")
        }
        
        log.info("\(type(of: self)): comm test result. url=\(String(describing: components.url)), statusCode=\(res.statusCode)")
    }
    
    /// 実行する
    /// - Parameter patientNo: 患者番号
    func exec(patientNo: String) async throws {
        // HTTPレスポンスタイムアウト時間[秒]を設定
        let conf = URLSessionConfiguration.default
        conf.timeoutIntervalForRequest = TimeInterval(setting.httpResWaitSec)
        
        let path = "/api/receipt"
        let url = setting.baseUrl.appendingPathComponent(path)
        
        // 患者番号をURLパラメータに設定
        let queries: [URLQueryItem] = [
            URLQueryItem(name: "patientNum", value: patientNo),
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
        
        let urlSession = URLSession(configuration: conf)
        let (resData, res) = try await urlSession.data(for: req)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.other("URLResponse to HTTPURLResponse error")
        }
        
        log.info("\(type(of: self)): comm test result. url=\(String(describing: components.url)), statusCode=\(res.statusCode)")
        
        switch res.statusCode {
        case 200:
            log.debug("\(type(of: self)): response ok")
            break
        case 204:
            // 検索結果が0件
            log.info("\(type(of: self)): no data")
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

extension MIUProgram {
    /// MIU連携プログラム通信設定
    final class Setting {
        let baseUrl: URL
        let httpResWaitSec: Int
        
        init(baseUrl: URL, httpResWaitSec: Int) throws {
            self.baseUrl = baseUrl
            self.httpResWaitSec = httpResWaitSec
            
            // URLは、URLオブジェクトとして正しいものしか受け取れないためチェックしない
            try Setting.HTTP_RES_WAIT_SEC.validate(httpResWaitSec)
        }
        
        static let BASE_URL = SettingValueAttr(
            label: "MIU連携プログラムAPIのエンドポイントURL",
            defaultValue: "",
            placeHolder: "例：http://xxx.xxx.xxx.xxx:8080",
            errorMessage: "入力してください。",
            isValidOK: { value in return URL(string: value) != nil })
        
        static let HTTP_RES_WAIT_SEC = SettingValueAttr(
            label: "HTTPレスポンス待ち時間[秒]",
            defaultValue: 60,
            placeHolder: "例：60",
            errorMessage: "1以上の値を入力してください。",
            isValidOK: { value in return value >= 1 })
    }
}

extension MIUProgram {
    /// エラー
    enum RunError: Error {
        case test(String)
        case client(String)
        case server(String)
        case unexpectedResponse(String)
        case other(String)
    }
}
