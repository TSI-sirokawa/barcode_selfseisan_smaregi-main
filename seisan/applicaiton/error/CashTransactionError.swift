//
//  CashTransactionError.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/31.
//

import Foundation

/// 現金取引エラー
enum CashTransactionError: Error {
    /// 取引エラー
    case transaction(message: String)
    /// 予期せぬエラー
    case unexpected(message: String)
}
