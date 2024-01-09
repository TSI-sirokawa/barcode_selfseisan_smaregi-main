//
//  GrolyR08AutoCashierAdapter.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/19.
//

import Foundation
import Logging

/// グローリーR08自動つり銭機アダプタ
final class GrolyR08AutoCashierAdapter: CashTransactionProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// グローリーR08つり銭機通信設定
    private let setting: Setting
    /// つり銭機アダプタとの最終通信時刻
    private var lastAccessTime = Date.now
    /// つり銭機アダプタとの通信実行間隔[秒]
    /// 　→1秒固定
    /// 　→API呼び出しは最低1秒の間隔を空けるように仕様書に記載があるため
    private static let ACCESS_INTERVAL_SEC: Double = 1
    
    /// コンストラクタ
    init(setting: Setting) {
        self.setting = setting
    }
    
    /// 通信テストを実施する
    func execCommTest() async throws {
        let url = URL(string: "http://\(setting.ipAddr):\(setting.port)/api/v1/machine/status")
        var urlReq = URLRequest(url: url!)
        urlReq.timeoutInterval = Double(setting.commTimeoutSec)
        urlReq.httpMethod = "POST"
        
        // HTTPリクエストを実行する。接続できればOK。レスポンスの成否は確認しない
        (_, _) = try await execHttpRequest(urlReq)
    }
    
    /// つり銭機の取引を開始する（現金取引プロトコル実装）
    /// - Parameter billing: 請求
    /// - Returns: 取引ID
    func startTransaction(billing: BillingProtocol) async throws -> String {
        waitAccess()
        
        // リクエストJSONを生成
        // ・showFixDepositButton=false: つり銭機アダプタに確定ボタンを表示しない
        // ・timeout=0: 取引処理のタイムアウトを無効にする
        let reqJSON = "{" +
        "\"total\":\(billing.amount.value)," +
        "\"showFixDepositButton\":false," +
        "\"timeout\":0" +
        "}"
        
        let url = URL(string: "http://\(setting.ipAddr):\(setting.port)/api/v1/transactions")
        var urlReq = URLRequest(url: url!)
        urlReq.timeoutInterval = Double(setting.commTimeoutSec)
        urlReq.httpMethod = "POST"
        urlReq.httpBody = reqJSON.data(using: .utf8)
        
        // HTTPリクエストを実行し、レスポンスの成否を確認
        let (data, resp) = try await execHttpRequest(urlReq)
        updateAccessTime()
        try checkResponse(data: data, resp: resp)
        
        do {
            // 応答をデリシアライズ
            let respData = try JSONDecoder().decode(StartTransactionResponse.self, from: data)
            return respData.transactionID
        } catch  {
            throw CashTransactionError.unexpected(message: "error=\(error), content=\(String(data: data, encoding: .utf8)!)")
        }
    }
    
    /// つり銭機の取引状態を取得する（現金取引プロトコル実装）
    /// - Parameter transactionID: 取引ID
    /// - Returns: 現金取引状態
    func getTransaction(transactionID: String) async throws -> CashTransctionState {
        waitAccess()
        
        let url = URL(string: "http://\(setting.ipAddr):\(setting.port)/api/v1/transactions/\(transactionID)")
        var urlReq = URLRequest(url: url!)
        urlReq.timeoutInterval = Double(setting.commTimeoutSec)
        urlReq.httpMethod = "GET"
        
        // HTTPリクエストを実行し、レスポンスの成否を確認
        let (data, resp) = try await execHttpRequest(urlReq)
        updateAccessTime()
        try checkResponse(data: data, resp: resp)
        
        var state: CashTransctionState?
        do {
            // 応答をデリシアライズ
            state = try JSONDecoder().decode(CashTransctionState.self, from: data)
        } catch  {
            throw CashTransactionError.unexpected(message: "error=\(error), content=\(String(data: data, encoding: .utf8)!)")
        }
        
        // おつり払出しが必要かを確認
        // 　→投入金額が請求金額を超えたらおつり払出しあり
        var isCanPayoutChange = false
        let change = state!.deposit - state!.total
        if change > 0 {
            // おつり払出し可否を取得
            isCanPayoutChange = try await self.canPayoutChange(amount: change)
        }
        state!.isCanPayoutChange = isCanPayoutChange
        
        return state!
    }
    
    /// 指定金額の払出しが可能かどうか
    /// - Parameter amount: 払い出したい金額[円]
    /// - Returns: true:払い出し可、false:払い出し不可
    func canPayoutChange(amount: Int) async throws -> Bool {
        waitAccess()
        
        // 在高取得API
        let url = URL(string: "http://\(setting.ipAddr):\(setting.port)/api/v1/machine/cash")
        var urlReq = URLRequest(url: url!)
        urlReq.timeoutInterval = Double(setting.commTimeoutSec)
        urlReq.httpMethod = "GET"
        
        // HTTPリクエストを実行し、レスポンスの成否を確認
        let (data, resp) = try await execHttpRequest(urlReq)
        updateAccessTime()
        try checkResponse(data: data, resp: resp)
        
        var cashInCashier: CashInCashierResponse
        do {
            // 応答をデリシアライズ
            cashInCashier = try JSONDecoder().decode(CashInCashierResponse.self, from: data)
        } catch  {
            throw CashTransactionError.unexpected(message: "error=\(error), content=\(String(data: data, encoding: .utf8)!)")
        }
        
        // 払出し可否を判定
        let canPayout = CanPayout(
            the10000: cashInCashier.cashCount.cash.get10000(),
            the5000: cashInCashier.cashCount.cash.get5000(),
            the2000: cashInCashier.cashCount.cash.get2000(),
            the1000: cashInCashier.cashCount.cash.get1000(),
            the500: cashInCashier.cashCount.cash.get500(),
            the100: cashInCashier.cashCount.cash.get100(),
            the50: cashInCashier.cashCount.cash.get50(),
            the10: cashInCashier.cashCount.cash.get10(),
            the5: cashInCashier.cashCount.cash.get5(),
            the1: cashInCashier.cashCount.cash.get1())
        return canPayout.isOK(amount: amount)
    }
    
    /// 入金完了を要求する（現金取引プロトコル実装）
    func fixDeposit() async throws {
        waitAccess()
        
        let url = URL(string: "http://\(setting.ipAddr):\(setting.port)/api/v1/transactions/fix-deposit")
        var urlReq = URLRequest(url: url!)
        urlReq.timeoutInterval = Double(setting.commTimeoutSec)
        urlReq.httpMethod = "POST"
        
        // HTTPリクエストを実行し、レスポンスの成否を確認
        let (data, resp) = try await execHttpRequest(urlReq)
        updateAccessTime()
        try checkResponse(data: data, resp: resp)
    }
    
    /// つり銭機の取引をキャンセルする（現金取引プロトコル実装）
    func cancelTransaction() async throws {
        waitAccess()
        
        let url = URL(string: "http://\(setting.ipAddr):\(setting.port)/api/v1/transactions/cancel")
        var urlReq = URLRequest(url: url!)
        urlReq.timeoutInterval = Double(setting.commTimeoutSec)
        urlReq.httpMethod = "POST"
        
        // HTTPリクエストを実行し、レスポンスの成否を確認
        let (data, resp) = try await execHttpRequest(urlReq)
        updateAccessTime()
        try checkResponse(data: data, resp: resp)
    }
    
    /// 機器の状態を取得する
    /// - Returns: 機器の状態
    func getMachineStatus() async throws -> MachineState {
        waitAccess()
        
        let url = URL(string: "http://\(setting.ipAddr):\(setting.port)/api/v1/machine/status")
        var urlReq = URLRequest(url: url!)
        urlReq.timeoutInterval = Double(setting.commTimeoutSec)
        urlReq.httpMethod = "POST"
        
        // HTTPリクエストを実行し、レスポンスの成否を確認
        let (data, resp) = try await execHttpRequest(urlReq)
        updateAccessTime()
        try checkResponse(data: data, resp: resp)
        
        do {
            // 応答をデリシアライズ
            let respData = try JSONDecoder().decode(MachineState.self, from: data)
            return respData
        } catch  {
            throw CashTransactionError.unexpected(message: "error=\(error), content=\(String(data: data, encoding: .utf8)!)")
        }
    }
    
    /// つり銭機アダプタとの通信を待機する
    /// ・つり銭機アダプタ仕様のためリクエスト間隔を1秒空ける
    private func waitAccess() {
        // 前回通信時からの経過時間[秒]を計算し、指定された時間だけ待機
        let elapsedSec = Date().timeIntervalSince(lastAccessTime)
        let waitSec = GrolyR08AutoCashierAdapter.ACCESS_INTERVAL_SEC - elapsedSec
        if waitSec <= 0 {
            return
        }
        Thread.sleep(forTimeInterval: TimeInterval(waitSec))
    }
    
    /// つり銭機アダプタとの最終通信時刻を更新する
    private func updateAccessTime() {
        lastAccessTime = Date.now
    }
    
    /// HTTPリクエストを実行する
    /// - Parameter urlReq: リクエスト
    /// - Returns: Data: レスポンスボディ、HTTPURLResponse: レスポンス
    func execHttpRequest(_ urlReq: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var data: Data?
        var resp: URLResponse?
        do {
            (data, resp) = try await URLSession.shared.data(for: urlReq)
        } catch let error as NSError {
            if error.domain == NSURLErrorDomain {
                throw CashTransactionError.transaction(message: "つり銭機と通信できません。\nつり銭機との接続状態を確認してください。")
            }
            throw error
        } catch {
            throw error
        }
            
        guard let httpResp = resp as? HTTPURLResponse else {
            throw CashTransactionError.unexpected(message: "reponse is not HTTPURLResponse")
        }
        
        return (data!, httpResp)
    }
    
    /// レスポンスの成否を確認する
    /// - Parameter data: 受信ボディ
    /// - Parameter resp: レスポンス
    private func checkResponse(data: Data, resp: HTTPURLResponse) throws {
        let respClass = resp.statusCode / 100
        switch respClass {
        case 2:
            // 成功
            break
        case 4:
            // 不正なリクエスト
            throw CashTransactionError.transaction(message: try parseErrorReponse(data: data))
        case 5:
            // つり銭機アダプタ側エラー
            throw CashTransactionError.transaction(message: try parseErrorReponse(data: data))
        default:
            throw CashTransactionError.unexpected(message: "statusCode=\(resp.statusCode), content=\(String(data: data, encoding: .utf8)!)")
        }
    }
    
    /// 失敗時レスポンスを解析する
    /// - Parameter data: 受信ボディ
    /// - Returns: エラーメッセージ
    private func parseErrorReponse(data: Data) throws -> String {
        do {
            // 応答をデリシアライズ
            let respData = try JSONDecoder().decode(APIErrorResponse.self, from: data)
            return "\(respData.detail)(\(respData.title))"
        } catch  {
            throw CashTransactionError.unexpected(message: "error=\(error), content=\(String(data: data, encoding: .utf8)!)")
        }
    }
}

extension GrolyR08AutoCashierAdapter {
    /// つり銭機アダプタ - 簡単インターフェース - 失敗時レスポンス
    private final class APIErrorResponse: Decodable {
        var title: String
        var detail: String
    }
    
    /// つり銭機アダプタ - 簡単インターフェース - 取引開始APIレスポンス
    private final class StartTransactionResponse: Decodable {
        /// 対象取引の一意なID（取引ID）
        var transactionID: String
        
        enum CodingKeys: String, CodingKey {
            case transactionID = "transactionId"
        }
    }
    
    // つり銭機アダプタ - 簡単インターフェース - 在高取得APIレスポンス
    class CashInCashierResponse: Codable {
        let cashCount: CashCount
        let cashErrorStatus: CashErrorStatus
        let billRejectCount, seqNo: Int

        init(cashCount: CashCount, cashErrorStatus: CashErrorStatus, billRejectCount: Int, seqNo: Int) {
            self.cashCount = cashCount
            self.cashErrorStatus = cashErrorStatus
            self.billRejectCount = billRejectCount
            self.seqNo = seqNo
        }
        
        class CashCount: Codable {
            var cash: Cash
            var stock: Cash?
            var wrap: Cash?
            
            class Cash: Codable {
                // 0の場合は省略されるため、オプショナル型で定義
                var the1, the5, the10, the50: UInt16?
                var the100, the500, the1000, the2000: UInt16?
                var the5000, the10000: UInt16?

                enum CodingKeys: String, CodingKey, Equatable {
                    case the1 = "1"
                    case the5 = "5"
                    case the10 = "10"
                    case the50 = "50"
                    case the100 = "100"
                    case the500 = "500"
                    case the1000 = "1000"
                    case the2000 = "2000"
                    case the5000 = "5000"
                    case the10000 = "10000"
                }
                
                func get1() -> UInt16 {
                    return the1 ?? 0
                }
                
                func get5() -> UInt16 {
                    return the5 ?? 0
                }
                
                func get10() -> UInt16 {
                    return the10 ?? 0
                }
                
                func get50() -> UInt16 {
                    return the50 ?? 0
                }
                
                func get100() -> UInt16 {
                    return the100 ?? 0
                }
                
                func get500() -> UInt16 {
                    return the500 ?? 0
                }
                
                func get1000() -> UInt16 {
                    return the1000 ?? 0
                }
                
                func get2000() -> UInt16 {
                    return the2000 ?? 0
                }
                
                func get5000() -> UInt16 {
                    return the5000 ?? 0
                }
                
                func get10000() -> UInt16 {
                    return the10000 ?? 0
                }
            }
        }
        
        class CashErrorStatus: Codable {
            var cash: Cash
            
            class Cash: Codable {
                var the1, the5, the10, the50: Bool
                var the100, the500, the1000: Bool
                var the2000: Bool?
                var the5000, the10000: Bool
                var cassette: Bool?

                enum CodingKeys: String, CodingKey, Equatable {
                    case the1 = "1"
                    case the5 = "5"
                    case the10 = "10"
                    case the50 = "50"
                    case the100 = "100"
                    case the500 = "500"
                    case the1000 = "1000"
                    case the2000 = "2000"
                    case the5000 = "5000"
                    case the10000 = "10000"
                    case cassette = "cassette"
                }
            }
        }
    }
}
