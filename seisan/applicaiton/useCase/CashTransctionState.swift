//
//  CashTransctionState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/31.
//

import Foundation

/// 現金取引状態
struct CashTransctionState: Decodable, Equatable {
    /// 取引ID
    var transactionID: String
    /// 現金取引ステータス
    var transactionStatus: CashTransactionStatusType
    /// 請求金額
    var total: Int
    /// 預かり金額
    var deposit: Int
    /// おつり金額
    var change: Int
    /// おつり払出し可否
    var isCanPayoutChange: Bool?
    /// 出金された金額：未使用
    /// ・取引が完了した場合、つり銭の金額となります。
    /// ・取引がキャンセルされた場合、預かり金額となります。
    var dispensedCash: Int
    /// 入金完了フラグ
    /// ・確定ボタン押下か、入金完了 API 実行により、入金済みの預かり金額と出金予定のつり銭の金額が確定すると true になります。
    var fixDeposit: Bool
    /// レスポンスの順序を表すシーケンス番号(64bit 整数)：未使用
    /// ・シーケンス番号が大きい方のレスポンスが最新の情報となります。
    var seqNo: Int64
    /// 取引開始日時(ISO-8601 形式文字列)：未使用
    /// ・2020年1月2日 16時39分55秒001ミリ秒の場合、2020-01-02T16:39:55.001 となります。
    var startDate: String
    /// 取引終了日時(ISO-8601 形式文字列)：未使用
    var endData: String?
    
    enum CodingKeys: String, CodingKey {
        case transactionID = "transactionId"
        case transactionStatus
        case total
        case deposit
        case change
        case isCanPayoutChange
        case dispensedCash
        case fixDeposit
        case seqNo
        case startDate
        case endData
    }
}

/// 機器の状態
struct MachineState: Decodable, Equatable {
    var bill: Bill
    var coin: Bill
    var cashStatus: CashState
    var cashWrapStatus: CashWrapState
    var seqNo: Int
}

/// 紙幣部の情報
struct Bill: Codable, Equatable {
    var errorCode: Int
    var setInfo: Int
}

/// 収納庫の状態
struct CashState: Decodable, Equatable {
    var the1, the5, the10, the50: String
    var the100, the500, the1000, the2000: String
    var the5000, the10000:String
    var billReject: String
    var cassete: String
    var overflow: String

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
        case billReject, cassete, overflow
    }
}

/// 包装硬貨部の状態
struct CashWrapState: Decodable, Equatable {
    var the1, the5, the10, the50: String
    var the100, the500: String
    var reject: Bool
    var opened: Bool
    
    enum CodingKeys: String, CodingKey, Equatable {
        case the1 = "1"
        case the5 = "5"
        case the10 = "10"
        case the50 = "50"
        case the100 = "100"
        case the500 = "500"
        case reject, opened
    }
}

/// 現金取引ステータス種別
enum CashTransactionStatusType: String,Decodable {
    /// 入金中(取引開始 実行直後)
    case beginDeposit
    /// 出金中(つり銭出金中)
    case dispenseChange
    /// つり銭抜き取り待ち(つり銭出金後の抜き取り待ち)
    case waitPullOut
    /// 取引完了(つり銭なし時、もしくはつり銭の抜き取り完了後)
    case finish
    /// 取引キャンセル(取引キャンセル、またはエラー解除操作後のタイムアウト検知)
    case cancel
    /// 取引強制終了(電断、OS のクラッシュなどでの取引終了)
    case abort
    /// 取引タイムアウト(指定された時間内に入金が未完了)
    case timeout
    /// 取引エラー終了(出金中、つり銭抜き取り待ち時のエラー)
    case failure
}
