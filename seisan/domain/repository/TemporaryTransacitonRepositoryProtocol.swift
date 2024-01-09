//
//  TemporaryTransacitonRepositoryProtocol.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/18.
//

import Foundation

/// 仮販売状態リポジトリプロトコル
protocol TemporaryTransacitonRepositoryProtocol {
    func updateTemporaryTransactions(_ tempTranses: [TemporaryTransaction]) async throws 
}
