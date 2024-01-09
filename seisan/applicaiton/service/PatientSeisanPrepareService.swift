//
//  PatientSeisanPrepareService.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/08/01.
//

import Foundation

/// 患者番号精算準備サービス
final class PatientSeisanPrepareService {
    /// 患者番号
    let patientNo: String
    /// 患者番号精算準備プロトコル
    let prepare: PatientSeisanPrepareProtocol
    
    init(patientNo: String, prepare: PatientSeisanPrepareProtocol) {
        self.patientNo = patientNo
        self.prepare = prepare
    }
    
    /// 実行する
    /// - Parameter patientNo: 患者番号
    /// - Returns:
    func exec() async throws {
        return try await prepare.exec(patientNo: patientNo)
    }
}
