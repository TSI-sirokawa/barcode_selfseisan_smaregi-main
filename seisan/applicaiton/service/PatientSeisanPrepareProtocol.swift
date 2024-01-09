//
//  PatientSeisanPrepareProtocol.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/08/01.
//

import Foundation

/// 患者番号精算準備プロトコル
protocol PatientSeisanPrepareProtocol {
    /// 実行する
    /// - Parameter patientNo: 患者番号
    /// - Returns:
    func exec(patientNo: String) async throws
}
