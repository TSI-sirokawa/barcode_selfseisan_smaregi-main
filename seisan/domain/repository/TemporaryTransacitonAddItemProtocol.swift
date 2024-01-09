//
//  TemporaryTransacitonAddItemProtocol.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/18.
//

import Foundation

/// 仮販売追加項目リポジトリ
protocol TemporaryTransacitonAddItemProtocol {
    /// 仮販売追加項目を取得する
    /// - Parameter tempTranses: 仮販売配列
    /// - Returns: 仮販売追加項目配列
    func loadTempTransAddItems(tempTranses: [TemporaryTransaction]) async throws -> [TemporaryTransacitonAddItem]
}
