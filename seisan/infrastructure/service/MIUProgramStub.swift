//
//  MIUIntegrationProgram.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/08/01.
//

import Foundation
import Logging

/// MIU連携プログラムスタブ
final class MIUProgramStub: PatientSeisanPrepareProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)

    /// 実行する
    /// - Parameter patientNo: 患者番号
    func exec(patientNo: String) async throws {
        log.info("\(type(of: self)): stub exec")
    }
}
