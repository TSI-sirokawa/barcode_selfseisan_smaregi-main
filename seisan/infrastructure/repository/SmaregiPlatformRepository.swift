//
//  SmaregiPlatformAPIRepository.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/12/03.
//

import Foundation
import Logging

final class SmaregiPlatformRepository: TransactionResultRepositoryProtocol,
                                       PatientCardBillingRepositoryProtocol,
                                       TemporaryTransacitonRepositoryProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let setting: Setting
    private var accessToken: AccessToken?
    
    /// 仮販売データのメモ欄のフォーマット種別
    ///  　→仮販売データの「メモ」プロパティのフォーマット判定に仕様する
    private let integrationMemoType: SmaregiPlatformRepository.IntegrationMemoType?
    
    /// アプリ起動時からの取引結果登録回数
    private static var totalRegisterCount = 0
    
    /// アクセストークン取得時に指定するスコープ
    ///  ・本アプリで使用するAPI呼び出しに必要なものを一括指定する
    private static let REQURIE_SCOPES = "pos.transactions:read pos.transactions:write"
    
    init(setting: Setting) {
        self.setting = setting
        self.integrationMemoType = nil
    }
    
    init(setting: Setting, integrationMemoType: SmaregiPlatformRepository.IntegrationMemoType) {
        self.setting = setting
        self.integrationMemoType = integrationMemoType
    }
    
    /// 通信テストを実施する
    func execCommTest() async throws {
        defer {
            // テスト時に発行したアクセストークンは破棄する
            accessToken = nil
        }
        
        let accessToken = try await getAccessToken(scopes: "pos.products:read")
        
        let path = "/\(setting.contractID)/pos/products"
        var url = setting.platformAPIBaseUrl.appendingPathComponent(path)
        
        let queries: [URLQueryItem] = [
            URLQueryItem(name: "fields", value: "productId"),
            URLQueryItem(name: "limit", value: "1"),
        ]
        url.append(queryItems: queries)
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (resData, res) = try await URLSession.shared.data(for: req)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.other("URLResponse to HTTPURLResponse error")
        }
        
        if res.statusCode == 401 {
            // 認証エラー(401)の場合は、テスト失敗とする
            throw RunError.test(createErrorMessage(statusCode: res.statusCode, errResData: resData))
        }
    }
    
    /// 診察券請求情報を取得する
    /// - Parameters:
    ///   - patientNo: 患者番号
    ///   - from: 取得期間From　※この日時も含む
    ///   - to: 取得期間To　※この日時も含む
    ///   - limit: 最大取得件数
    /// - Returns: 診察券請求
    func loadPatientCardBilling(patientNo: String, from: Date, to: Date, limit: Int) async throws -> PatientCardBilling {
        log.trace("\(type(of: self)): load billing start. patientNo=\(patientNo), from=\(from), to=\(to)")
        
        // 未精算の仮販売データを取得し、
        // 仮販売データから以下を抽出する
        // ・請求額
        // ・メモから患者名を取得
        //　　　例：00062 田中　太郎,入外:O,ORCA伝票番号:0001085
        //　　　例：00004 大分　花子,入外:I,ORCA伝票番号:0001086
        let tempReses = try await getTemporariesDivision(customerCode: patientNo, from: from, to: to, limit: limit, status: .Normal)
        
        var patientName = ""
        var totalAmount = 0
        var shunos: [Shuno] = []
        var tempTranses: [TemporaryTransaction] = []
        for (i, tempRes) in tempReses.enumerated() {
            log.debug("\(type(of: self)): [\(i+1)] transactionHeadID=\(tempRes.transactionHeadID), total=\(tempRes.total), memo=\(tempRes.memo)")
            
            // 仮販売
            // 　→請求金額のマイナス値は返金を示すのでマイナス値を許容する
            let tempTrans = try TemporaryTransaction(
                id: tempRes.transactionHeadID,
                time: tempRes.transactionDateTime,
                status: .Normal,
                total: tempRes.total,
                memo: tempRes.memo,
                storeID: tempRes.storeID,
                customerID: tempRes.customerID,
                details: try tempRes.details.map {
                    TransactionDetail(
                        transactionDetailID: $0.transactionDetailID,
                        transactionDetailDivision: $0.transactionDetailDivision,
                        productId: $0.productID,
                        productCode: $0.productCode,
                        salesPrice: try Amount($0.salesPrice, isMinusAllow: true),
                        unitDiscountPrice: try Amount($0.unitDiscountPrice, isMinusAllow: true),
                        quantity: $0.quantity,
                        unitDiscountSum: try Amount($0.unitDiscountedSum, isMinusAllow: true))
                })
            
            log.info("\(type(of: self)): [\(i+1)] tempTrans=\(tempTrans)")
            tempTranses.append(tempTrans)
            
            // 請求額を合計
            totalAmount += tempTrans.total.value
            
            switch self.integrationMemoType! {
            case .orca:
                // ORCA連携
                // メモから患者名／入外種別／伝票番号を取得
                let (retPatientName, inOut, invoiceNo) = try parseTemporaryMemoForORCA(memo: tempRes.memo)
                log.debug("\(type(of: self)): [\(i+1)] customerName=\(patientName), inOut=\(inOut), invoiceNo=\(invoiceNo)")
                if patientName == "" {
                    // 患者名は同じものが取れるため初回だけ取得
                    patientName = retPatientName
                }
                
                // 収納
                let shuno = Shuno(invoiceNo: invoiceNo,
                                  inOut: inOut,
                                  billingAmount: try BillingAmount(tempRes.total, isMinusAllow: true))
                log.debug("\(type(of: self)): [\(i+1)] shuno=\(shuno)")
                shunos.append(shuno)
            case .csv:
                // CSV連携
                // メモから患者名を取得
                let retPatientName = try parseTemporaryMemoForCSV(memo: tempRes.memo)
                log.debug("\(type(of: self)): [\(i+1)] customerName=\(patientName)")
                if patientName == "" {
                    // 患者名は同じものが取れるため初回だけ取得
                    patientName = retPatientName
                }
            }
        }
        
        if patientName == "" {
            // 1回も名前が取得できなかった場合はエラー
            throw RunError.notFound("仮販売データが見つかりません。患者番号：\(patientNo)")
        }
        
        let billing = try PatientCardBilling(
            patient: Customer(code: patientNo, name: patientName),
            billingAmount: try BillingAmount(totalAmount, isMinusAllow: true),
            shunos: shunos,
            tempTranses: tempTranses)
        return billing
    }
    
    /// 仮販売データのメモを解析し患者名と収納を取得する（ORCA連携フォーマット対応）
    /// - Parameter memo: 管理販売データのメモの値
    /// - Returns: 患者名, 入外種別, 伝票番号
    private func parseTemporaryMemoForORCA(memo: String) throws -> (String, InOutType, InvoiceNo) {
        // 患者名をメモから抽出
        // 【フォーマット】
        // 　　・外来の場合
        // 　　　　患者:000000 漢字氏名,入外:O,ORCA伝票番号:999999
        // 　　・入院の場合
        // 　　　　患者:000000 漢字氏名,入外:I,ORCA伝票番号:999999,999999 ,入院期間：YYYY-MM-DD～YYYY-MM-DD
        //
        // 【フォーマット詳細】
        // 　　・カンマ区切りの一番左の患者パートは、患者番号＋半角空白＋漢字氏名
        do {
            let elems = memo.split(separator: ",")
            if elems.count < 3 {
                throw RunError.unexpectedResponse("elem count is invalid")
            }
            
            // 患者名
            let patientPart = elems[0]
            let patientElems = patientPart.split(separator: " ")
            if patientElems.count < 2 {
                throw RunError.unexpectedResponse("patient part is invalid")
            }
            let patientName = String(patientElems[1])
            
            // 入外種別
            let inOutPart = elems[1]
            let inOutElems = inOutPart.split(separator: ":")
            if inOutElems.count < 2 {
                throw RunError.unexpectedResponse("inOut part is invalid")
            }
            let inOutStr = String(inOutElems[1])
            guard let inOut = InOutType(rawValue: inOutStr) else {
                throw RunError.unexpectedResponse("inOut value is invalid")
            }
            
            // 伝票番号
            let invoiceNoPart = elems[2]
            let invoiceNoElems = invoiceNoPart.split(separator: ":")
            if invoiceNoElems.count < 2 {
                throw RunError.unexpectedResponse("invoiceNo part is invalid")
            }
            let invoiceNoStr = String(invoiceNoElems[1])
            let invoiceNo = InvoiceNo(invoiceNoStr)
            
            return (patientName, inOut, invoiceNo)
        } catch {
            throw RunError.unexpectedResponse("memo is invalid. memo=\(memo): \(error)")
        }
    }
    
    /// 複数の取引を登録する
    /// - Parameter result: 複数の取引結果
    /// - Returns: 取引ID配列
    func registerTransactions(results: [TransactionResult]) async throws -> [String] {
        var transIDs: [String] = []
        for (i, result) in results.enumerated() {
            let transID = try await registerTransaction(result: result)
            log.info("\(type(of: self)): [\(i+1)] register transaction ok. transID=\(transID)")
            transIDs.append(transID)
        }
        return transIDs
    }
    
    /// 仮販売データのメモを解析し患者名と収納を取得する（CSV連携フォーマット対応）
    /// - Parameter memo: 管理販売データのメモの値
    /// - Returns: 患者名
    private func parseTemporaryMemoForCSV(memo: String) throws -> String {
        // 患者名をメモから抽出
        // 　以下のようなフォーマット
        //   "患者番号:3137患者氏名:山田テス子,入外:O,端末取引ID:604,キー情報:230718022191"
        do {
            let elems = memo.split(separator: ",")
            if elems.count < 3 {
                throw RunError.unexpectedResponse("elem count is invalid")
            }
            
            // 患者名
            let patientPart = elems[0]
            let patientElems = patientPart.split(separator: "患者氏名:")
            if patientElems.count < 2 {
                throw RunError.unexpectedResponse("patient part is invalid")
            }
            let patientName = String(patientElems[1])
            
            return patientName
        } catch {
            throw RunError.unexpectedResponse("memo is invalid. memo=\(memo): \(error)")
        }
    }
    
    /// 取引を登録する
    /// - Parameter result: 取引結果
    /// - Returns: 取引ID
    func registerTransaction(result: TransactionResult) async throws -> String {
        let accessToken = try await getAccessToken(scopes: SmaregiPlatformRepository.REQURIE_SCOPES)
        
        let transaction = SmaregiPlatformRepository.TransactionRequest(
            transactionHeadDivision: 1,             // 取引区分：1:通常(固定)
            subtotal: result.subtotal.value,        // 小計：N円
            total: result.total.value,              // 合計：N円
            deposit: result.deposit.value,          // 預かり金
            depositCash: result.depositCash.value,  // 預かり金現金
            change: result.change.value,            // 釣銭
            depositCredit: result.depositCredit.value,      // 預かり金クレジット
            storeID: result.storeID ?? "\(setting.storeID!)",// 店舗ID
            terminalID: "\(setting.terminalID)",    // 端末ID
            customerID: result.customerID,          // 会員ID
            terminalTranID: SmaregiPlatformRepository.totalRegisterCount,   // 端末取引ID：アプリ起動時からの取引結果登録回数
            terminalTranDateTime: Date.now,         // 端末取引日時
            memo: result.memo,                      // メモ
            details: result.details.map {
                SmaregiPlatformRepository.TransactionRequest.Detail(
                    transactionDetailID: $0.transactionDetailID.value,
                    transactionDetailDivision: $0.transactionDetailDivision,
                    productID: $0.productId ?? "\(setting.productID!)",
                    salesPrice: "\($0.salesPrice.value)",
                    unitDiscountPrice: "\($0.unitDiscountPrice.value)",
                    quantity: $0.quantity)
            }
        )
        
        // アプリ起動時からの取引結果登録回数をインクリメント
        SmaregiPlatformRepository.totalRegisterCount += 1
        
        log.info("\(type(of: self)): register transaction. trans=\(transaction)")
        
        let path = "/\(setting.contractID)/pos/transactions"
        let url = setting.platformAPIBaseUrl.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(transaction)

        let (resData, res) = try await URLSession.shared.upload(for: req, from: jsonData)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.other("URLResponse to HTTPURLResponse error")
        }

        try checkResponse(resData: resData, res: res)

        do {
            let decoder = JSONDecoder()
            let transRes = try decoder.decode(SmaregiPlatformRepository.TransactionResponse.self, from: resData)
            return transRes.transactionHeadID
        } catch {
            throw RunError.unexpectedResponse("response json decode error: \(error)")
        }
    }
    
    /// 仮販売状態を完了に変更する
    /// - Parameter tempTranses: 仮販売配列
    func updateTemporaryTransactions(_ tempTranses: [TemporaryTransaction]) async throws {
        for tempTrans in tempTranses {
            log.trace("\(type(of: self)): update temporariery... tempTransID=\(tempTrans.id)")
            
            try await updateTemporaryTransaction(tempTrans)
            
            log.info("\(type(of: self)): update temporariery ok. tempTransID=\(tempTrans.id)")
        }
    }
    
    /// 仮販売状態を完了に変更する
    /// - Parameter tempTrans: 仮販売
    func updateTemporaryTransaction(_ tempTrans: TemporaryTransaction) async throws {
        let accessToken = try await getAccessToken(scopes: SmaregiPlatformRepository.REQURIE_SCOPES)
        
        let status = TemporaryTransactionStatusUpdateRequest(status: String(describing: tempTrans.status.rawValue))
        
        let path = "/\(setting.contractID)/pos/transactions/temporaries/\(tempTrans.id)/status"
        let url = setting.platformAPIBaseUrl.appendingPathComponent(path)
        
        log.info("\(type(of: self)): update temporariers. url=\(String(describing: url))")
        
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(status)
        
        let (resData, res) = try await URLSession.shared.upload(for: req, from: jsonData)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.other("URLResponse to HTTPURLResponse error")
        }
        
        try checkResponse(resData: resData, res: res)
    }
    
    /// 期間を分割して仮販売一覧（時刻昇順）を取得する
    /// ・スマレジの制限により、１度のリクエストで指定できるFrom〜Toの最大日数は31日間(※)なので、
    ///   それより長い期間の場合は分割して取得する仕組みを提供する
    /// 　※ スマレジ・プラットフォームAPI POS仕様書 (ver.1.0.0)で定義されている（2023/05/08時点）
    /// - Parameters:
    ///   - customerCode: 顧客コード
    ///   - from: 取得期間From　※この日時も含む
    ///   - to: 取得期間To　※この日時も含む
    ///   - limit: 最大取得件数
    ///   - status: 取得したい仮販売のステータス種別
    /// - Returns: 仮販売一覧（時刻昇順）取得レスポンス配列
    private func getTemporariesDivision(customerCode: String, from: Date, to: Date, limit: Int, status: TemporaryStatusType) async throws -> [TemporaryResponse] {
        var tempReses: [TemporaryResponse] = []
        
        log.info("\(type(of: self)): get temporaries division... \(from.getISO8601()) 〜 \(to.getISO8601()) (\(from.diffDay(to)))")
        
        var divCount = 0
        var paramTo = to
        while (paramTo >= from) {
            // Fromを算出
            let offsetDay = -(setting.maxDayPerRequest - 1)   // 当日分を含めてN日分なので当日分を引く
            guard let retParamFrom = paramTo.firstHourOfDay(offsetDay) else {
                throw RunError.other("'from' calc firstHourOfDay error. base=\(paramTo), offsetDay=\(offsetDay)")
            }
            var paramFrom = retParamFrom
            if paramFrom < from {
                // Fromより前になった場合はFromをセット
                paramFrom = from
            }
            
            divCount += 1
            log.info("\(type(of: self)): [\(divCount)] get temporaries division... \(paramFrom.getISO8601()) 〜 \(paramTo.getISO8601()) (\(paramFrom.diffDay(paramTo)))")
            
            // 仮販売データを取得
            let retTempReses = try await getTemporaries(customerCode: customerCode, from: paramFrom, to: paramTo, status: status)
            
            log.info("\(type(of: self)): [\(divCount)] get temporaries division ok. count=\(retTempReses.count)")
            
            var isLimitReached = false
            for (i, retTempRes) in retTempReses.enumerated() {
                tempReses.append(retTempRes)
                
                if tempReses.count == limit {
                    // 最大取得件数に達したら終了
                    log.warning("\(type(of: self)): [\(divCount)] temporaries limit. total=\(tempReses.count)), remain=\(retTempReses.count - (i + 1))")
                    isLimitReached = true
                    break
                }
            }
            
            if isLimitReached {
                break
            }
            
            // Fromの1日前の23時59分59秒をToにセット
            guard let retParamTo = paramFrom.firstHourOfDay(-1) else {
                throw RunError.other("'from' calc firstHourOfDay error. base=\(paramTo), offsetDay=\(offsetDay)")
            }
            guard let retParamTo = retParamTo.hhmmdd(23, 59, 59) else {
                throw RunError.other("'from' calc 23:59:59 error. date=\(retParamTo)")
            }
            paramTo = retParamTo
        }
        
        // 仮販売データを時刻昇順にソート
        tempReses.sort {
            $0.transactionDateTime < $1.transactionDateTime
        }
        
        return tempReses
    }
    
    /// 仮販売一覧を取得する
    /// - Parameters:
    ///   - customerCode: 顧客コード
    ///   - from: 取得期間From　※この日時も含む
    ///   - to: 取得期間To　※この日時も含む
    /// - Returns: 仮販売一覧取得（時刻昇順）レスポンス配列
    private func getTemporaries(customerCode: String, from: Date, to: Date, status: TemporaryStatusType) async throws -> [TemporaryResponse] {
        let accessToken = try await getAccessToken(scopes: SmaregiPlatformRepository.REQURIE_SCOPES)
        
        let path = "/\(setting.contractID)/pos/transactions/temporaries"
        let url = setting.platformAPIBaseUrl.appendingPathComponent(path)
        
        // URLパラメータを設定
        let queries: [URLQueryItem] = [
            URLQueryItem(name: "customer_code", value: customerCode),
            URLQueryItem(name: "transaction_date_time-from", value: URLTimestamp.create(from)),
            URLQueryItem(name: "transaction_date_time-to", value: URLTimestamp.create(to)),
            URLQueryItem(name: "status", value: String(describing: status.rawValue)),
            URLQueryItem(name: "fields", value: "transactionHeadId,transactionDateTime,sequentialNumber,total,memo,storeId,customerId"),
            URLQueryItem(name: "with_details", value: "summary"),
        ]
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.port = url.port
        components.path = url.path
        components.queryItems = queries
        // スマレジAPIは時刻文字列のタイムゾーン「+」がURLエンコードされていないとエラーになるが、
        // URLComponentsはデフォルトでは「+」をURLエンコードしないため、URLエンコードを行うようにする
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        log.info("\(type(of: self)): get temporariers. url=\(String(describing: components.url))")
        
        var req = URLRequest(url: components.url!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (resData, res) = try await URLSession.shared.data(for: req)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.other("URLResponse to HTTPURLResponse error")
        }
        
        try checkResponse(resData: resData, res: res)
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let tempReses = try decoder.decode([SmaregiPlatformRepository.TemporaryResponse].self, from: resData)
            return tempReses
        } catch {
            throw RunError.unexpectedResponse("response json decode error: \(error)")
        }
    }
    
    private func getAccessToken(scopes: String) async throws -> String {
        // 取得済みのアクセストークンが有効期限内なら取得済みのトークンを返す
        if accessToken != nil && (Date.now < accessToken!.expireTime) {
            log.info("\(type(of: self)): access token is valid. expireTime=\(accessToken!.expireTime.getISO8601())")
            return accessToken!.value
        }
        
        var isTokenGetted = false
        var retryCount = 0
        while !isTokenGetted {
            do {
                let accessTokenRes = try await execGetAccessToken(scope: scopes)
                
                // アクセストークンをメンバ変数に保持
                accessToken = AccessToken(value: accessTokenRes.accessToken, expiresIn: accessTokenRes.expiresIn)
                
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
    
    private func execGetAccessToken(scope: String) async throws -> AccessTokenResponse {
        let path = "/app/\(setting.contractID)/token"
        let url = setting.accessTokenBaseUrl.appendingPathComponent(path)
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        
        // 接続は毎回閉じる（連続リクエスト発行に必須。２重ログインになる？）
        req.setValue("close", forHTTPHeaderField: "Connection")
        
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let clientCredentialData = "\(setting.clientID):\(setting.clientSecret)".data(using: .utf8)!
        let clientCredential = clientCredentialData.base64EncodedString()
        req.setValue("Basic {\(clientCredential)}", forHTTPHeaderField: "Authorization")
        
        var body = "grant_type=client_credentials"
        body += "&scope=\(scope)"
        req.httpBody = body.data(using: .utf8)
        
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
        case 200:
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
        do {
            let errRes = try JSONDecoder().decode(ErrorResponse.self, from: errResData)
            return "statusCode=\(statusCode), body=\(errRes)"
        } catch {
            var body = String(data: errResData, encoding: .utf8)
            if body == nil {
                var tmp = ""
                dump(errResData, to: &tmp)
                body = tmp
            }
            return "statusCode=\(statusCode), body=\(body!)"
        }
    }
}

extension SmaregiPlatformRepository{
    /// 仮販売データのメモ欄のフォーマット種別
    enum IntegrationMemoType: String, CaseIterable, Codable {
        /// ORCA連携フォーマット
        case orca
        /// CSV連携フォーマット
        case csv
    }
}

extension SmaregiPlatformRepository {
    enum RunError: Error {
        case test(String)
        case client(String)
        case server(String)
        case notFound(String)
        case billing(String)
        case unexpectedResponse(String)
        case other(String)
    }
    
    private final class Timestamp {
        /// スマレジAPIのボディに指定するタイムスタンプを生成する
        /// ・時刻はJSTで指定する必要あり
        /// ・例えば、UTCで取引登録すると、その時刻がJSTとして扱われてしまう
        /// - Parameter date: 日時
        /// - Returns: タイムスタンプ
        static func create(_ date: Date) -> String {
            return date.getISO8601()
        }
    }
    
    private final class URLTimestamp {
        /// スマレジAPIのURLに指定するタイムスタンプを生成する
        /// - Parameter date: 日時
        /// - Returns: タイムスタンプ
        static func create(_ date: Date) -> String {
            return date.getISO8601()
        }
    }
    
    /// 取引登録リクエスト
    private final class TransactionRequest: CustomStringConvertible, Codable {
        let transactionHeadDivision, subtotal, total: String
        let deposit: String
        let depositCash: String
        let change: String
        let depositCredit: String
        let storeID: String
        let terminalID: String
        let customerID: String?
        let terminalTranID: String
        let terminalTranDateTime: String
        let memo: String?
        let details: [Detail]
        
        enum CodingKeys: String, CodingKey {
            case transactionHeadDivision, subtotal, total
            case deposit
            case depositCash
            case change
            case depositCredit
            case storeID = "storeId"
            case terminalID = "terminalId"
            case customerID = "customerId"
            case terminalTranID = "terminalTranId"
            case terminalTranDateTime, memo, details
        }
        
        init(transactionHeadDivision: Int,
             subtotal: Int,
             total: Int,
             deposit: Int,
             depositCash: Int,
             change: Int,
             depositCredit: Int,
             storeID: String,
             terminalID: String,
             customerID: String?,
             terminalTranID: Int,
             terminalTranDateTime: Date,
             memo: String?,
             details: [Detail]) {
            self.transactionHeadDivision = "\(transactionHeadDivision)"
            self.subtotal = "\(subtotal)"
            self.total = "\(total)"
            self.deposit = "\(deposit)"
            self.depositCash = "\(depositCash)"
            self.change = "\(change)"
            self.depositCredit = "\(depositCredit)"
            self.storeID = storeID
            self.terminalID = terminalID
            self.customerID = customerID
            self.terminalTranID = "\(terminalTranID)"
            self.terminalTranDateTime = Timestamp.create(terminalTranDateTime)
            self.memo = memo
            self.details = details
        }
        
        var description: String {
            do {
                let jsonData = try JSONEncoder().encode(self)
                return String(data: jsonData, encoding: .utf8) ?? ""
            } catch {
                return ""
            }
        }
        
        final class Detail: CustomStringConvertible, Codable {
            let transactionDetailID: String
            let transactionDetailDivision: String
            let productID: String
            let salesPrice: String
            let unitDiscountPrice: String
            let quantity: String
            
            init(transactionDetailID: String, transactionDetailDivision: String, productID: String, salesPrice: String, unitDiscountPrice: String, quantity: String) {
                self.transactionDetailID = transactionDetailID
                self.transactionDetailDivision = transactionDetailDivision
                self.productID = productID
                self.salesPrice = salesPrice
                self.unitDiscountPrice = unitDiscountPrice
                self.quantity = quantity
            }
            
            enum CodingKeys: String, CodingKey {
                case transactionDetailID = "transactionDetailId"
                case transactionDetailDivision
                case productID = "productId"
                case salesPrice
                case unitDiscountPrice
                case quantity
            }
            
            var description: String {
                do {
                    let jsonData = try JSONEncoder().encode(self)
                    return String(data: jsonData, encoding: .utf8) ?? ""
                } catch {
                    return ""
                }
            }
        }
    }
    
    /// 取引登録レスポンス
    private final class TransactionResponse: Codable {
        let transactionHeadID: String
        
        enum CodingKeys: String, CodingKey {
            case transactionHeadID = "transactionHeadId"
        }
    }
    
    /// 仮販売のステータス種別
    private enum TemporaryStatusType: Int {
        /// 0:通常
        case Normal = 0
        /// 1:完了
        case Complete = 1
        /// 2:取消
        case Cancel = 2
    }
    
    /// 仮販売一覧取得レスポンス
    private final class TemporaryResponse: Codable {
        let transactionHeadID: String
        let transactionDateTime: Date
        let sequentialNumber: String
        let total: String
        let memo: String
        let storeID: String
        let customerID: String
        let details: [Detail]
        
        enum CodingKeys: String, CodingKey {
            case transactionHeadID = "transactionHeadId"
            case transactionDateTime, sequentialNumber, total, memo
            case storeID = "storeId"
            case customerID = "customerId"
            case details
        }
        
        final class Detail: Codable {
            let transactionDetailID: String
            let transactionDetailDivision: String
            let productID: String
            let productCode: String
            let salesPrice: String
            let unitDiscountPrice: String
            let quantity: String
            let unitDiscountedSum: String
            
            enum CodingKeys: String, CodingKey {
                case transactionDetailID = "transactionDetailId"
                case transactionDetailDivision
                case productID = "productId"
                case productCode
                case salesPrice
                case unitDiscountPrice
                case quantity
                case unitDiscountedSum
            }
        }
    }
    
    /// 仮販売ステータス更新リクエスト
    private final class TemporaryTransactionStatusUpdateRequest: Codable {
        let status: String
        
        init(status: String) {
            self.status = status
        }
    }
    
    /// アクセストークンレスポンス
    private final class AccessTokenResponse: Codable {
        let scope, tokenType: String
        let expiresIn: Int
        let accessToken: String
        
        enum CodingKeys: String, CodingKey {
            case scope
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case accessToken = "access_token"
        }
    }
    
    /// アクセストークン
    private final class AccessToken {
        private(set) var value: String
        private(set) var expireTime: Date
        
        init(value: String, expiresIn: Int) {
            self.value = value
            self.expireTime = Date.now.addingTimeInterval(TimeInterval(expiresIn))
        }
    }
    
    /// エラーレスポンス
    private final class ErrorResponse: Codable, CustomStringConvertible {
        let type: String
        let title: String
        let status: Int
        let error: String?
        let errorDesc: String?
        let detail: String
        let scope: String?
        
        enum CodingKeys: String, CodingKey {
            case type
            case title
            case status
            case error
            case errorDesc = "error_description"
            case detail
            case scope
        }
        
        var description: String {
            do {
                let jsonData = try JSONEncoder().encode(self)
                return String(data: jsonData, encoding: .utf8) ?? ""
            } catch {
                return ""
            }
        }
    }
}
