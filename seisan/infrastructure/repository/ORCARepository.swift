//
//  ORCARepository.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/18.
//

import Foundation
import Logging
import XMLCoder

/// ORCAリポジトリ
final class ORCARepository: ShunoRepositoryProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    let setting: Setting
    
    init(setting: Setting) {
        self.setting = setting
    }
    
    /// 通信テストを実施する
    func execCommTest() async throws {
        // 終了リクエストで通信テストを行う
        let req = FiniishRequest(
            incomev3Req: FiniishRequest.Incomev3Req(
                karteUid: UUID().uuidString,
                orcaUid: "")
        )
        
        let reqXmlData = try XMLEncoder().encode(req, withRootKey: "data")
        
        let resData = try await execRequest(path: getURLPath(), reqXmlData: reqXmlData)
        
        let res = try XMLDecoder().decode(seisan.ORCARepository.FiniishReponseForCommTest.self, from: resData)
            
        log.info("\(type(of: self)): comm test ok. Api_Result=\(res.incomev3res.apiResult), Api_Result_Message=\(res.incomev3res.apiResultMessage)")
    }
    
    /// 収納を保存する
    /// ・ORCAの収納を更新するには以下のシーケンスを実行する必要がある
    /// 　　１）請求確認リクエスト
    /// 　　　　→ここで患者がロックされる
    /// 　　２）入金リクエスト or 入金取消リクエスト
    /// 　　３）終了リクエスト
    /// 　　　　→ロックを解除するためのリクエスト
    /// - Parameters:
    ///   - patient: 患者
    ///   - shunos: 収納
    func saveShunos(patient: Customer, shunos: [Shuno]) async throws {
        for shuno in shunos {
            try await saveShuno(patient: patient, shuno: shuno)
        }
    }
    
    /// 収納を保存する
    /// - Parameters:
    ///   - patient: 患者
    ///   - shuno: 収納
    private func saveShuno(patient: Customer, shuno: Shuno) async throws {
        // リトライ処理用ループ
        // 　→該当の患者に対して排他が掛かっていた場合は一旦解除してからリトライする
        var retryCount = 0
        while(true) {
            var orcaUid = ""
            do {
                // 請求確認
                let confirmRes = try await confirmBilling(karteUid: setting.karteUid,
                                                          patientID: patient.code,
                                                          inOut: shuno.inOut,
                                                          invoiceNumber: shuno.invoiceNo)
                orcaUid = confirmRes.incomev3res.orcaUid!
                
                var icCode = setting.shunoCashID
                if shuno.depositMethod == Shuno.DepositMethodType.Credit {
                    icCode = setting.shunoCreditID
                }
                
                if shuno.billingAmount.isPayment() {
                    // 入金
                    _ = try await doPayment(karteUid: setting.karteUid,
                                            orcaUid: confirmRes.incomev3res.orcaUid!,
                                            patientID: patient.code,
                                            inOut: shuno.inOut,
                                            invoiceNumber: shuno.invoiceNo,
                                            processingDateTime: shuno.depositDateTime!,
                                            icCode: icCode,
                                            icMoney: shuno.billingAmount)
                } else {
                    // 返金
                    _ = try await doPaymentCancel(karteUid: setting.karteUid,
                                            orcaUid: confirmRes.incomev3res.orcaUid!,
                                            patientID: patient.code,
                                            inOut: shuno.inOut,
                                            invoiceNumber: shuno.invoiceNo,
                                            processingDateTime: shuno.depositDateTime!,
                                            icCode: icCode,
                                            icMoney: shuno.billingAmount)
                }
            } catch RunError.server(let message, let apiResult) {
                do {
                    // 最後に必ず終了処理を呼び出す
                    _ = try await finish(karteUid: setting.karteUid, orcaUid: orcaUid)
                    log.warning("\(type(of: self)): finish ok at confirm retry")
                } catch {
                    log.warning("\(type(of: self)): finish error at confirm retry: \(error)")
                }
                
                // サーバが排他系のエラーを返した場合は終了処理を行った後にリトライ
                switch apiResult {
                case "E1038":
                    // E1038: 他の端末より同じカルテＵＩＤでの接続がある
                    break
                default:
                    throw RunError.server(message, apiResult)
                }
                
                if retryCount == 1 {
                    throw RunError.server(message, apiResult)
                }
                retryCount += 1
                log.info("\(type(of: self)): save shuno retry... reason=\(message)")
                continue
            } catch {
                log.error("\(type(of: self)): save shuno sequence error: \(error)")
                do {
                    // 最後に必ず終了処理を呼び出す
                    _ = try await finish(karteUid: setting.karteUid, orcaUid: orcaUid)
                    log.warning("\(type(of: self)): finish ok at payment error")
                } catch {
                    log.warning("\(type(of: self)): finish error at payment error: \(error)")
                }
                throw error
            }
            
            // 最後に必ず終了処理を呼び出す
            _ = try await finish(karteUid: setting.karteUid, orcaUid: orcaUid)
            
            break
        }
    }
    
    /// 請求確認リクエストを実行する
    /// - Parameters:
    ///   - karteUid: カルテID
    ///   - patientID: 患者番号
    ///   - inOut: 入外種別
    ///   - invoiceNumber: 伝票番号
    /// - Returns: 請求確認レスポンス
    private func confirmBilling(karteUid: String,
                                patientID: String,
                                inOut: InOutType,
                                invoiceNumber: InvoiceNo) async throws -> BillingConfirmReponse {
        let req = BillingConfirmRequest(
            incomev3Req: BillingConfirmRequest.Incomev3Req(
                karteUid: karteUid,
                patientID: patientID,
                inOut: inOut.rawValue,
                invoiceNumber: invoiceNumber.value)
        )
        
        let reqXmlData = try XMLEncoder().encode(req, withRootKey: "data")
        
        let resData = try await execRequest(path: getURLPath(), reqXmlData: reqXmlData)
        let res = try XMLDecoder().decode(seisan.ORCARepository.BillingConfirmReponse.self, from: Data(resData))
        
        log.info("\(type(of: self)): confirm bliing response received. Karte_Uid=\(res.incomev3res.karteUid), Orca_Uid=\(String(describing: res.incomev3res.orcaUid)), Invoice_Number=\(invoiceNumber), Api_Result=\(res.incomev3res.apiResult), Api_Result_Message=\(res.incomev3res.apiResultMessage)")
        
        try checkApiResult(#function, res.incomev3res.apiResult, res.incomev3res.apiResultMessage)
        
        return res
    }
    
    /// 入金リクエストを実行する
    /// - Parameters:
    ///   - karteUid: カルテID
    ///   - orcaUid: オルカID
    ///   - patientID: 患者ID
    ///   - inOut: 入外種別
    ///   - invoiceNumber: 伝票番号
    ///   - processingDateTime: 入金日時
    ///   - icCode: 入金種別
    ///   - icMoney: 入金金額
    /// - Returns: 入金レスポンス
    private func doPayment(karteUid: String,
                           orcaUid: String,
                           patientID: String,
                           inOut: InOutType,
                           invoiceNumber: InvoiceNo,
                           processingDateTime: Date,
                           icCode: String,
                           icMoney: BillingAmount) async throws -> PaymentReponse {
        let dateStr = processingDateTime.format("yyyy-MM-dd")
        let timeStr = processingDateTime.format("HH:mm")
        
        let req = PaymentRequest(
            incomev3Req: PaymentRequest.Incomev3Req(
                karteUid: karteUid,
                orcaUid: orcaUid,
                patientID: patientID,
                inOut: inOut.rawValue,
                invoiceNumber: invoiceNumber.value,
                processingDate: dateStr,
                processingTime: timeStr,
                icCode: icCode,
                icMoney: String(icMoney.value))
        )
        
        log.info("\(type(of: self)): payment request. req=\(req)")
        
        let reqXmlData = try XMLEncoder().encode(req, withRootKey: "data")
        let resData = try await execRequest(path: getURLPath(), reqXmlData: reqXmlData)
        let res = try XMLDecoder().decode(seisan.ORCARepository.PaymentReponse.self, from: resData)
        
        log.info("\(type(of: self)): payment response received. Karte_Uid=\(res.incomev3res.karteUid), Orca_Uid=\(res.incomev3res.orcaUid), Invoice_Number=\(invoiceNumber), Ic_Money=\(icMoney.value), Api_Result=\(res.incomev3res.apiResult), Api_Result_Message=\(res.incomev3res.apiResultMessage)")
        
        try checkApiResult(#function, res.incomev3res.apiResult, res.incomev3res.apiResultMessage)
        
        return res
    }
    
    /// 入金取消リクエストを実行する
    /// - Parameters:
    ///   - karteUid: カルテID
    ///   - orcaUid: オルカID
    ///   - patientID: 患者ID
    ///   - inOut: 入外種別
    ///   - invoiceNumber: 伝票番号
    ///   - processingDateTime: 入金日時
    ///   - icCode: 入金種別
    ///   - icMoney: 入金金額
    /// - Returns: 入金レスポンス
    private func doPaymentCancel(karteUid: String,
                           orcaUid: String,
                           patientID: String,
                           inOut: InOutType,
                           invoiceNumber: InvoiceNo,
                           processingDateTime: Date,
                           icCode: String,
                           icMoney: BillingAmount) async throws -> PaymentCancelReponse {
        let dateStr = processingDateTime.format("yyyy-MM-dd")
        let timeStr = processingDateTime.format("HH:mm")
        
        let req = PaymentCancelRequest(
            incomev3Req: PaymentCancelRequest.Incomev3Req(
                karteUid: karteUid,
                orcaUid: orcaUid,
                patientID: patientID,
                inOut: inOut.rawValue,
                invoiceNumber: invoiceNumber.value,
                processingDate: dateStr,
                processingTime: timeStr,
                icCode: icCode,
                icMoney: String(icMoney.value))
        )
        
        log.info("\(type(of: self)): payment cancel request. req=\(req)")
        
        let reqXmlData = try XMLEncoder().encode(req, withRootKey: "data")
        let resData = try await execRequest(path: getURLPath(), reqXmlData: reqXmlData)
        let res = try XMLDecoder().decode(seisan.ORCARepository.PaymentCancelReponse.self, from: resData)
        
        log.info("\(type(of: self)): payment cancel response received. Karte_Uid=\(res.incomev3res.karteUid), Orca_Uid=\(res.incomev3res.orcaUid), Invoice_Number=\(invoiceNumber), Ic_Money=\(icMoney.value), Api_Result=\(res.incomev3res.apiResult), Api_Result_Message=\(res.incomev3res.apiResultMessage)")
        
        try checkApiResult(#function, res.incomev3res.apiResult, res.incomev3res.apiResultMessage)
        
        return res
    }
    
    /// 終了リクエストを実行する
    /// - Parameters:
    ///   - karteUid: カルテID
    ///   - orcaUid: オルカID
    /// - Returns: 終了レスポンス
    private func finish(karteUid: String, orcaUid: String) async throws -> FiniishReponse {
        let req = FiniishRequest(
            incomev3Req: FiniishRequest.Incomev3Req(
                karteUid: karteUid,
                orcaUid: orcaUid)
        )
        
        let reqXmlData = try XMLEncoder().encode(req, withRootKey: "data")
        
        let resData = try await execRequest(path: getURLPath(), reqXmlData: reqXmlData)
        let res = try XMLDecoder().decode(seisan.ORCARepository.FiniishReponse.self, from: resData)

        log.info("\(type(of: self)): finish response received. Karte_Uid=\(String(describing: res.incomev3res.karteUid)), Orca_Uid=\(String(describing: res.incomev3res.orcaUid)), Api_Result=\(res.incomev3res.apiResult), Api_Result_Message=\(res.incomev3res.apiResultMessage)")
        
        try checkApiResult(#function, res.incomev3res.apiResult, res.incomev3res.apiResultMessage)

        return res
    }
    
    /// URLパスを取得する
    ///  ・WebORCAとオンプレORCAでURLパスがことなるため、メソッド化
    /// - Returns: URLパス
    func getURLPath() -> String {
        switch setting.orcaEnvType {
        case .Web:
            // WebORCA
            return "/api/orca23/incomev3"
        case .OnPremises:
            // オンプレ
            return "/orca23/incomev3"
        }
    }
    
    /// リクエストを実行する
    /// - Parameters:
    ///   - path: URLパス
    ///   - reqXmlData: リクエストボディXML
    /// - Returns: レスポンスデータ
    private func execRequest(path: String, reqXmlData: Data) async throws -> (Data) {
        let session = try createSession()
        
        let url = setting.baseUrl.appendingPathComponent(path)
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        
        var password: String
        switch setting.orcaEnvType {
        case .Web:
            password = setting.apiKey
        case .OnPremises:
            password = setting.clientPassword
        }
        
        let clientCredentialData = "\(setting.clientID):\(password)".data(using: .utf8)!
        let clientCredential = clientCredentialData.base64EncodedString()
        req.setValue("Basic \(clientCredential)", forHTTPHeaderField: "Authorization")
        
        let (resData, res) = try await session.upload(for: req, from: reqXmlData)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.other("URLResponse to HTTPURLResponse error")
        }
        
        try checkResponse(resData: resData, res: res)
        
        return resData
    }
    
    /// セッションを生成する
    /// - Returns: セッション
    private func createSession() throws -> URLSession {
        if setting.orcaEnvType == .Web {
            // WebORCAの場合は、HTTPS、かつ、クライアント認証を使用
            
            // TLSv1.3を明示的に指定した場合、iPadからORCAへの入金処理でTLS通信エラーが発生するようになったため、
            // 明示的に指定しないようにする
            //       // sessionConfig.tlsMinimumSupportedProtocolVersion = .TLSv13
            //       // sessionConfig.tlsMaximumSupportedProtocolVersion = .TLSv13
            //
            // 　・明示的に指定されていると、
            // 　　　ClientAuthSessionDelegateクラスのコールバック（クライアント証明書の設定処理）が呼び出されず、通信に失敗する
            // 　・明示的な指定を削除すると、
            // 　　　ClientAuthSessionDelegateクラスのコールバック（クライアント証明書の設定処理）が呼び出され、通信に成功する
            //
            // 　　→パケットキャプチャで確認すると、iPad（第9世代）からORCAへの入金処理はTLSv1.2が使用されていた。
            // 　 　実際に使用されるバージョンが明示的に指定したバージョンと異なると、
            // 　  ClientAuthSessionDelegateクラスのコールバック（クライアント証明書の設定処理）が呼びされないと考えられる
            let sessionConfig = URLSessionConfiguration.default
            
            let credential = try createCredential(clientCertData: setting.clientCertFile!.data,
                                                  password: setting.clientCertPassword)
            
            let session = URLSession(configuration: sessionConfig, delegate: ClientAuthSessionDelegate(credential: credential), delegateQueue: nil)
            return session
        }
        
        // オンプレオルカの場合は単純なHTTP
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        return session
    }
    
    /// PCKS#12形式のクライアント証明書データからURLクレデンシャルを生成する
    /// - Returns: URLクレデンシャル
    /// - Parameter clientCertData: PCKS#12形式のクライアント証明書データ
    /// - Parameter password: パスワード
    private func createCredential(clientCertData: Data, password: String) throws -> URLCredential {
        let options = [kSecImportExportPassphrase as String: password]
        var items: CFArray?
        let importRet = SecPKCS12Import(clientCertData as NSData, options as CFDictionary, &items)
        guard importRet == errSecSuccess else {
            // パスワードを間違えた場合など
            throw RunError.other("import client cert error: \(importRet)")
        }
        let dict = items! as! [[String: AnyObject]]
        let identity = dict[0][kSecImportItemIdentity as String] as! SecIdentity
        let certificate = dict[0][kSecImportItemCertChain as String] as! [SecCertificate]
        let credential = URLCredential(identity: identity, certificates: certificate, persistence: .forSession)
        return credential
    }
    
    /// HTTPレスポンスを確認する
    /// - Parameters:
    ///   - resData: レスポンスボディ
    ///   - res: HTTPレスポンス
    private func checkResponse(resData: Data, res: HTTPURLResponse) throws {
        switch res.statusCode {
        case 200, 204:
            log.debug("\(type(of: self)): response ok")
            break
        case 400 ..< 500:
            throw RunError.client(createErrorMessage(statusCode: res.statusCode, errResData: resData))
        case 500 ..< 600:
            throw RunError.server(createErrorMessage(statusCode: res.statusCode, errResData: resData), "-")
        default:
            throw RunError.unexpectedResponse(createErrorMessage(statusCode: res.statusCode, errResData: resData))
        }
    }
    
    /// HTTPエラーレスポンス受信時にエラーメッセージを作成する
    /// - Parameters:
    ///   - statusCode: HTTPステータスコード
    ///   - errResData: レスポンスボディ
    /// - Returns: エラーメッセージ文字列
    private func createErrorMessage(statusCode: Int, errResData: Data) -> String {
        var body = ""
        if let resStr = String(data: errResData, encoding: .utf8) {
            body = resStr
        } else {
            dump(errResData, to: &body)
        }
        return "statusCode=\(statusCode), body=\(body)"
    }
    
    /// Api_Resultを確認する
    /// - Parameters:
    ///   - method: 呼び出し元メソッド名
    ///   - apiResult: Api_Result
    ///   - apiResultMsg: Api_Result_Message
    private func checkApiResult(_ method: String,  _ apiResult: String, _ apiResultMsg: String) throws {
        guard let apiResultNo = Int(apiResult) else {
            throw RunError.server("recv api error result at \(method). Api_Result=\(apiResult), Api_Result_Message=\(apiResultMsg)", apiResult)
        }
        
        if apiResultNo != 0 {
            throw RunError.server("recv api error result at \(method). Api_Result=\(apiResult), Api_Result_Message=\(apiResultMsg)", apiResult)
        }
    }
}

extension ORCARepository {
    enum RunError: Error {
        case test(String)
        case client(String)
        case server(String, String)
        case notFound(String)
        case unexpectedResponse(String)
        case other(String)
    }
    
    /// クライアント認証セッションデリゲート
    class ClientAuthSessionDelegate: NSObject, URLSessionDelegate {
        let credential: URLCredential
        
        init(credential: URLCredential) {
            self.credential = credential
        }
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
    
    /// type="string"のタグ
    private final class StringTypeTag: Codable, DynamicNodeEncoding {
        let type = "string"
        let value: String
        
        init(_ value: String) {
            self.value = value
        }
        
        enum CodingKeys: String, CodingKey {
            case type = "type"
            case value = ""
        }
        
        static func nodeEncoding(for key: CodingKey) -> XMLCoder.XMLEncoder.NodeEncoding {
            switch key {
            case CodingKeys.type:
                return .attribute
            default:
                return .element
            }
        }
    }
    
    /// 請求確認リクエスト
    private final class BillingConfirmRequest: Codable {
        let incomev3Req: Incomev3Req
        
        init(incomev3Req: Incomev3Req) {
            self.incomev3Req = incomev3Req
        }
        
        enum CodingKeys: String, CodingKey {
            case incomev3Req = "incomev3req"
        }
        
        final class Incomev3Req: Codable, DynamicNodeEncoding {
            let type = "record"
            let requestNumber = StringTypeTag("01")
            let requestMode = StringTypeTag("02")
            let karteUid: StringTypeTag
            let orcaUid = StringTypeTag("")
            let patientID: StringTypeTag
            let inOut: StringTypeTag
            let invoiceNumber: StringTypeTag
            
            init(karteUid: String, patientID: String, inOut: String, invoiceNumber: String) {
                self.karteUid = StringTypeTag(karteUid)
                self.patientID = StringTypeTag(patientID)
                self.inOut = StringTypeTag(inOut)
                self.invoiceNumber = StringTypeTag(invoiceNumber)
            }
            
            enum CodingKeys: String, CodingKey {
                case type = "type"
                case requestNumber = "Request_Number"
                case requestMode = "Request_Mode"
                case karteUid = "Karte_Uid"
                case orcaUid = "Orca_Uid"
                case patientID = "Patient_ID"
                case inOut = "InOut"
                case invoiceNumber = "Invoice_Number"
            }
            
            static func nodeEncoding(for key: CodingKey) -> XMLCoder.XMLEncoder.NodeEncoding {
                switch key {
                case CodingKeys.type:
                    return .attribute
                default:
                    return .element
                }
            }
        }
    }
    
    /// 請求確認レスポンス
    private final class BillingConfirmReponse: Codable {
        let incomev3res: Incomev3res
        
        enum CodingKeys: String, CodingKey {
            case incomev3res = "incomev3res"
        }
        
        final class Incomev3res: Codable {
            let informationDate: String
            let InformationTime: String
            let apiResult: String
            let apiResultMessage: String
            let requestNumber: String
            let requestMode: String
            let responseNumber: String
            let karteUid: String
            let orcaUid: String?
            let patientID: String?
            let incomeDetail: IncomeDetail?
            let incomeHistory: [IncomeHistory]?
            
            enum CodingKeys: String, CodingKey {
                case informationDate = "Information_Date"
                case InformationTime = "Information_Time"
                case apiResult = "Api_Result"
                case apiResultMessage = "Api_Result_Message"
                case requestNumber = "Request_Number"
                case requestMode = "Request_Mode"
                case responseNumber = "Response_Number"
                case karteUid = "Karte_Uid"
                case orcaUid = "Orca_Uid"
                case patientID = "Patient_ID"
                case incomeDetail = "Income_Detail"
                case incomeHistory = "Income_History"
            }
            
            final class IncomeDetail: Codable {
                let performDate: String
                let issuedDate: String
                let inOut: String
                let invoiceNumber: String
                let insuranceCombinationNumber: String
                let rateCd: String
                let departmentCode: String
                let cdInformation: CdInformation
                let acPointInformation: AcPointInformation
                let oeEtcInformation: OeEtcInformation?
                
                enum CodingKeys: String, CodingKey {
                    case performDate = "Perform_Date"
                    case issuedDate = "IssuedDate"
                    case inOut = "InOut"
                    case invoiceNumber = "Invoice_Number"
                    case insuranceCombinationNumber = "Insurance_Combination_Number"
                    case rateCd = "Rate_Cd"
                    case departmentCode = "Department_Code"
                    case cdInformation = "Cd_Information"
                    case acPointInformation = "Ac_Point_Information"
                    case oeEtcInformation = "Oe_Etc_Information"
                }
                
                final class CdInformation: Codable {
                    let acMoney: String
                    let icMoney: String
                    let aiMoney: String
                    let oeMoney: String
                    
                    enum CodingKeys: String, CodingKey {
                        case acMoney = "Ac_Money"
                        case icMoney = "Ic_Money"
                        case aiMoney = "Ai_Money"
                        case oeMoney = "Oe_Money"
                    }
                }
                
                final class AcPointInformation: Codable {
                    let acTtlPoint: String
                    let acPointDetail: [AcPointDetail]
                    
                    enum CodingKeys: String, CodingKey {
                        case acTtlPoint = "Ac_Ttl_Point"
                        case acPointDetail = "Ac_Point_Detail"
                    }
                    
                    final class AcPointDetail: Codable {
                        let acPointDetailChild: AcPointDetailchild
                        
                        enum CodingKeys: String, CodingKey {
                            case acPointDetailChild = "Ac_Point_Detail_child"
                        }
                        
                        final class AcPointDetailchild: Codable {
                            let acPointCode: String
                            let acPointName: String
                            let acPoint: String
                            
                            enum CodingKeys: String, CodingKey {
                                case acPointCode = "Ac_Point_Code"
                                case acPointName = "Ac_Point_Name"
                                case acPoint = "Ac_Point"
                            }
                        }
                    }
                }
                
                final class OeEtcInformation: Codable {
                    let oeEtcDetail: [OeEtcDetail]
                    
                    enum CodingKeys: String, CodingKey {
                        case oeEtcDetail = "Oe_Etc_Detail"
                    }
                    
                    final class OeEtcDetail: Codable {
                        let oeEtcDetailChild: OeEtcDetailChild
                        
                        enum CodingKeys: String, CodingKey {
                            case oeEtcDetailChild = "Oe_Etc_Detail_child"
                        }
                        
                        final class OeEtcDetailChild: Codable {
                            let oeEtcNumber: String
                            let oeEtcName: String
                            
                            enum CodingKeys: String, CodingKey {
                                case oeEtcNumber = "Oe_Etc_Number"
                                case oeEtcName = "Oe_Etc_Name"
                            }
                        }
                    }
                }
            }
            
            final class IncomeHistory: Codable {
                let incomeHistoryChild: IncomeHistoryChild
                
                enum CodingKeys: String, CodingKey {
                    case incomeHistoryChild = "Income_History_child"
                }
                
                final class IncomeHistoryChild: Codable {
                    let historyNumber: String
                    let processingDate: String
                    let processingTime: String
                    let acMoney: String
                    let icMoney: String
                    let state: String
                    let stateName: String
                    let icCode: String
                    let icCodeName: String
                    
                    enum CodingKeys: String, CodingKey {
                        case historyNumber = "History_Number"
                        case processingDate = "Processing_Date"
                        case processingTime = "Processing_Time"
                        case acMoney = "Ac_Money"
                        case icMoney = "Ic_Money"
                        case state = "State"
                        case stateName = "State_Name"
                        case icCode = "Ic_Code"
                        case icCodeName = "Ic_Code_Name"
                    }
                }
            }
        }
    }
    
    /// 入金リクエスト
    private final class PaymentRequest: CustomStringConvertible, Codable {
        let incomev3Req: Incomev3Req
        
        init(incomev3Req: Incomev3Req) {
            self.incomev3Req = incomev3Req
        }
        
        var description: String {
            do {
                let jsonData = try JSONEncoder().encode(self)
                return String(data: jsonData, encoding: .utf8) ?? ""
            } catch {
                return ""
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case incomev3Req = "incomev3req"
        }
            
        final class Incomev3Req: CustomStringConvertible, Codable, DynamicNodeEncoding {
            let type = "record"
            let requestNumber = StringTypeTag("02")
            let requestMode = StringTypeTag("01")
            let karteUid: StringTypeTag
            let orcaUid: StringTypeTag
            let patientID: StringTypeTag
            let inOut: StringTypeTag
            let invoiceNumber: StringTypeTag
            let processingDate: StringTypeTag
            let processingTime: StringTypeTag
            let icCode: StringTypeTag
            let icMoney: StringTypeTag
            let printInformation: PrintInformation
            
            init(karteUid: String, orcaUid: String, patientID: String, inOut: String, invoiceNumber: String, processingDate: String, processingTime: String, icCode: String, icMoney: String) {
                self.karteUid = StringTypeTag(karteUid)
                self.orcaUid = StringTypeTag(orcaUid)
                self.patientID = StringTypeTag(patientID)
                self.inOut = StringTypeTag(inOut)
                self.invoiceNumber = StringTypeTag(invoiceNumber)
                self.processingDate = StringTypeTag(processingDate)
                self.processingTime = StringTypeTag(processingTime)
                self.icCode = StringTypeTag(icCode)
                self.icMoney = StringTypeTag(icMoney)
                self.printInformation = PrintInformation()
            }
            
            var description: String {
                do {
                    let jsonData = try JSONEncoder().encode(self)
                    return String(data: jsonData, encoding: .utf8) ?? ""
                } catch {
                    return ""
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case type = "type"
                case requestNumber = "Request_Number"
                case requestMode = "Request_Mode"
                case karteUid = "Karte_Uid"
                case orcaUid = "Orca_Uid"
                case patientID = "Patient_ID"
                case inOut = "InOut"
                case invoiceNumber = "Invoice_Number"
                case processingDate = "Processing_Date"
                case processingTime = "Processing_Time"
                case icCode = "Ic_Code"
                case icMoney = "Ic_Money"
                case printInformation = "Print_Information"
            }
            
            static func nodeEncoding(for key: CodingKey) -> XMLCoder.XMLEncoder.NodeEncoding {
                switch key {
                case CodingKeys.type:
                    return .attribute
                default:
                    return .element
                }
            }
            
            final class PrintInformation: CustomStringConvertible, Codable {
                let printInvoiceReceiptClass = StringTypeTag("1")
                let printStatementClass = StringTypeTag("1")
                
                var description: String {
                    do {
                        let jsonData = try JSONEncoder().encode(self)
                        return String(data: jsonData, encoding: .utf8) ?? ""
                    } catch {
                        return ""
                    }
                }
                
                enum CodingKeys: String, CodingKey {
                    case printInvoiceReceiptClass = "Print_Invoice_Receipt_Class"
                    case printStatementClass = "Print_Statement_Class"
                }
            }
        }
    }
    
    /// 入金レスポンス
    private final class PaymentReponse: Codable {
        let incomev3res: Incomev3res
        
        enum CodingKeys: String, CodingKey {
            case incomev3res = "incomev3res"
        }
        
        final class Incomev3res: Codable {
            let informationDate: String
            let InformationTime: String
            let apiResult: String
            let apiResultMessage: String
            let requestNumber: String
            let requestMode: String
            let responseNumber: String?
            let karteUid: String
            let orcaUid: String
            let patientID: String?
            let inOut: String?
            let invoiceNumber: String?
            let acMoney: String?
            let icMoney: String?
            let unpaidMoney: String?
            let state: String?
            let stateName: String?
            let incomeHistory: [IncomeHistory]?
            
            enum CodingKeys: String, CodingKey {
                case informationDate = "Information_Date"
                case InformationTime = "Information_Time"
                case apiResult = "Api_Result"
                case apiResultMessage = "Api_Result_Message"
                case requestNumber = "Request_Number"
                case requestMode = "Request_Mode"
                case responseNumber = "Response_Number"
                case karteUid = "Karte_Uid"
                case orcaUid = "Orca_Uid"
                case patientID = "Patient_ID"
                case inOut = "InOut"
                case invoiceNumber = "Invoice_Number"
                case acMoney = "Ac_Money"
                case icMoney = "Ic_Money"
                case unpaidMoney = "Unpaid_Money"
                case state = "State"
                case stateName = "State_Name"
                case incomeHistory = "Income_History"
            }
            
            final class IncomeHistory: Codable {
                let incomeHistoryChild: IncomeHistoryChild
                
                enum CodingKeys: String, CodingKey {
                    case incomeHistoryChild = "Income_History_child"
                }
                
                final class IncomeHistoryChild: Codable {
                    let historyNumber: String
                    let processingDate: String
                    let processingTime: String
                    let acMoney: String
                    let icMoney: String
                    let state: String
                    let stateName: String
                    let icCode: String
                    let icCodeName: String
                    
                    enum CodingKeys: String, CodingKey {
                        case historyNumber = "History_Number"
                        case processingDate = "Processing_Date"
                        case processingTime = "Processing_Time"
                        case acMoney = "Ac_Money"
                        case icMoney = "Ic_Money"
                        case state = "State"
                        case stateName = "State_Name"
                        case icCode = "Ic_Code"
                        case icCodeName = "Ic_Code_Name"
                    }
                }
            }
        }
    }
    
    /// 入金取消リクエスト
    private final class PaymentCancelRequest: CustomStringConvertible, Codable {
        let incomev3Req: Incomev3Req
        
        init(incomev3Req: Incomev3Req) {
            self.incomev3Req = incomev3Req
        }
        
        var description: String {
            do {
                let jsonData = try JSONEncoder().encode(self)
                return String(data: jsonData, encoding: .utf8) ?? ""
            } catch {
                return ""
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case incomev3Req = "incomev3req"
        }
            
        final class Incomev3Req: CustomStringConvertible, Codable, DynamicNodeEncoding {
            let type = "record"
            let requestNumber = StringTypeTag("02")
            let requestMode = StringTypeTag("03")
            let karteUid: StringTypeTag
            let orcaUid: StringTypeTag
            let patientID: StringTypeTag
            let inOut: StringTypeTag
            let invoiceNumber: StringTypeTag
            let processingDate: StringTypeTag
            let processingTime: StringTypeTag
            let icCode: StringTypeTag
            let icMoney: StringTypeTag
            
            init(karteUid: String, orcaUid: String, patientID: String, inOut: String, invoiceNumber: String, processingDate: String, processingTime: String, icCode: String, icMoney: String) {
                self.karteUid = StringTypeTag(karteUid)
                self.orcaUid = StringTypeTag(orcaUid)
                self.patientID = StringTypeTag(patientID)
                self.inOut = StringTypeTag(inOut)
                self.invoiceNumber = StringTypeTag(invoiceNumber)
                self.processingDate = StringTypeTag(processingDate)
                self.processingTime = StringTypeTag(processingTime)
                self.icCode = StringTypeTag(icCode)
                self.icMoney = StringTypeTag(icMoney)
            }
            
            var description: String {
                do {
                    let jsonData = try JSONEncoder().encode(self)
                    return String(data: jsonData, encoding: .utf8) ?? ""
                } catch {
                    return ""
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case type = "type"
                case requestNumber = "Request_Number"
                case requestMode = "Request_Mode"
                case karteUid = "Karte_Uid"
                case orcaUid = "Orca_Uid"
                case patientID = "Patient_ID"
                case inOut = "InOut"
                case invoiceNumber = "Invoice_Number"
                case processingDate = "Processing_Date"
                case processingTime = "Processing_Time"
                case icCode = "Ic_Code"
                case icMoney = "Ic_Money"
            }
            
            static func nodeEncoding(for key: CodingKey) -> XMLCoder.XMLEncoder.NodeEncoding {
                switch key {
                case CodingKeys.type:
                    return .attribute
                default:
                    return .element
                }
            }
        }
    }
    
    /// 入金取消レスポンス
    private final class PaymentCancelReponse: Codable {
        let incomev3res: Incomev3res
        
        enum CodingKeys: String, CodingKey {
            case incomev3res = "incomev3res"
        }
        
        final class Incomev3res: Codable {
            let informationDate: String
            let InformationTime: String
            let apiResult: String
            let apiResultMessage: String
            let requestNumber: String
            let requestMode: String
            let responseNumber: String
            let karteUid: String
            let orcaUid: String
            let patientID: String?
            let inOut: String?
            let invoiceNumber: String?
            let acMoney: String?
            let icMoney: String?
            let unpaidMoney: String?
            let state: String?
            let stateName: String?
            let incomeHistory: [IncomeHistory]?
            
            enum CodingKeys: String, CodingKey {
                case informationDate = "Information_Date"
                case InformationTime = "Information_Time"
                case apiResult = "Api_Result"
                case apiResultMessage = "Api_Result_Message"
                case requestNumber = "Request_Number"
                case requestMode = "Request_Mode"
                case responseNumber = "Response_Number"
                case karteUid = "Karte_Uid"
                case orcaUid = "Orca_Uid"
                case patientID = "Patient_ID"
                case inOut = "InOut"
                case invoiceNumber = "Invoice_Number"
                case acMoney = "Ac_Money"
                case icMoney = "Ic_Money"
                case unpaidMoney = "Unpaid_Money"
                case state = "State"
                case stateName = "State_Name"
                case incomeHistory = "Income_History"
            }
            
            final class IncomeHistory: Codable {
                let incomeHistoryChild: IncomeHistoryChild
                
                enum CodingKeys: String, CodingKey {
                    case incomeHistoryChild = "Income_History_child"
                }
                
                final class IncomeHistoryChild: Codable {
                    let historyNumber: String
                    let processingDate: String
                    let processingTime: String
                    let acMoney: String
                    let icMoney: String
                    let state: String
                    let stateName: String
                    let icCode: String
                    let icCodeName: String
                    
                    enum CodingKeys: String, CodingKey {
                        case historyNumber = "History_Number"
                        case processingDate = "Processing_Date"
                        case processingTime = "Processing_Time"
                        case acMoney = "Ac_Money"
                        case icMoney = "Ic_Money"
                        case state = "State"
                        case stateName = "State_Name"
                        case icCode = "Ic_Code"
                        case icCodeName = "Ic_Code_Name"
                    }
                }
            }
        }
    }
    
    /// 終了リクエスト
    private final class FiniishRequest: Codable {
        let incomev3Req: Incomev3Req
        
        init(incomev3Req: Incomev3Req) {
            self.incomev3Req = incomev3Req
        }
        
        enum CodingKeys: String, CodingKey {
            case incomev3Req = "incomev3req"
        }
        
        final class Incomev3Req: Codable, DynamicNodeEncoding {
            let type = "record"
            let requestNumber = StringTypeTag("99")
            let karteUid: StringTypeTag
            let orcaUid: StringTypeTag
            
            init(karteUid: String, orcaUid: String) {
                self.karteUid = StringTypeTag(karteUid)
                self.orcaUid = StringTypeTag(orcaUid)
            }
            
            enum CodingKeys: String, CodingKey {
                case type = "type"
                case requestNumber = "Request_Number"
                case karteUid = "Karte_Uid"
                case orcaUid = "Orca_Uid"
            }
            
            static func nodeEncoding(for key: CodingKey) -> XMLCoder.XMLEncoder.NodeEncoding {
                switch key {
                case CodingKeys.type:
                    return .attribute
                default:
                    return .element
                }
            }
        }
    }
    
    /// 終了レスポンス
    private final class FiniishReponse: Codable {
        let incomev3res: Incomev3res
        
        enum CodingKeys: String, CodingKey {
            case incomev3res = "incomev3res"
        }
        
        final class Incomev3res: Codable {
            let informationDate: String
            let InformationTime: String
            let apiResult: String
            let apiResultMessage: String
            let requestNumber: String?
            let karteUid: String?
            let orcaUid: String?
            
            enum CodingKeys: String, CodingKey {
                case informationDate = "Information_Date"
                case InformationTime = "Information_Time"
                case apiResult = "Api_Result"
                case apiResultMessage = "Api_Result_Message"
                case requestNumber = "Request_Number"
                case karteUid = "Karte_Uid"
                case orcaUid = "Orca_Uid"
            }
        }
    }
    
    /// 通信テスト用の終了レスポンス
    private final class FiniishReponseForCommTest: Codable {
        let incomev3res: Incomev3res
        
        enum CodingKeys: String, CodingKey {
            case incomev3res = "incomev3res"
        }
        
        final class Incomev3res: Codable {
            let informationDate: String
            let InformationTime: String
            let apiResult: String
            let apiResultMessage: String
            
            enum CodingKeys: String, CodingKey {
                case informationDate = "Information_Date"
                case InformationTime = "Information_Time"
                case apiResult = "Api_Result"
                case apiResultMessage = "Api_Result_Message"
            }
        }
    }
}
