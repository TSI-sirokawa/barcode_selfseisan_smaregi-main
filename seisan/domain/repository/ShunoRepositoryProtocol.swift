//
//  ShunoRepositoryProtocol.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/21.
//

import Foundation

/// 収納リポジトリ
protocol ShunoRepositoryProtocol {
    /// 収納を保存する
    /// - Parameters:
    ///   - patient: 患者
    ///   - shunos: 収納
    func saveShunos(patient: Customer, shunos: [Shuno]) async throws
}
