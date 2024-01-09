//
//  PatientCardBillingRepositoryProtocol.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/06.
//

import Foundation

/// 診察券請求リポジトリ
protocol PatientCardBillingRepositoryProtocol {
    /// 診察券請求情報を取得する
    /// - Parameters:
    ///   - patientNo: 患者番号
    ///   - from: 取得期間From　※この日時も含む
    ///   - to: 取得期間To　※この日時も含む
    ///   - limit: 最大取得件数
    /// - Returns: 診察券号請求
    func loadPatientCardBilling(patientNo: String, from: Date, to: Date, limit: Int) async throws -> PatientCardBilling
}
