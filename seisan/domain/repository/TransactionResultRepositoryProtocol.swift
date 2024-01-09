//
//  TransactionResultRepositoryProtocol.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/24.
//

import Foundation

/// 取引結果登録リポジトリプロトコル
protocol TransactionResultRepositoryProtocol {
    /// 複数の取引を登録する
    /// - Parameter result: 複数の取引結果
    /// - Returns: 取引ID配列
    func registerTransactions(results: [TransactionResult]) async throws -> [String]
    
    /// 取引を登録する
    /// - Parameter result: 取引結果
    /// - Returns: 取引ID
    func registerTransaction(result: TransactionResult) async throws -> String
}
