//
//  PatientCardSeisanUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/14.
//

import Foundation
import Logging

/// 診察券精算開始ユースケース
final class PatientCardSeisanUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    let barcode: PatientBarcode
    let billingRepo: PatientCardBillingRepositoryProtocol
    let from: Date
    let to: Date
    
    /// 取得する請求の最大件数
    /// ・21件目からは対応しない
    static let BILLING_MAX_COUNT = 20
    
    init(barcode: PatientBarcode,
         billingRepo: PatientCardBillingRepositoryProtocol,
         from: Date,
         to: Date) {
        self.barcode = barcode
        self.billingRepo = billingRepo
        self.from = from
        self.to = to
    }
    
    func exec() async throws -> PatientCardBilling {
        log.info("\(type(of: self)): load billing... patientNo=\(barcode.patientNo), from=\(from), to=\(to)")
        
        // 診察券請求モデルを取得
        let billing = try await billingRepo.loadPatientCardBilling(patientNo: barcode.patientNo,
                                                 from: from,
                                                 to: to,
                                                 limit: PatientCardSeisanUseCase.BILLING_MAX_COUNT)
        if billing.amount.value < 0 {
            // 請求額がマイナスの場合、返金であることを示す例外を投げる
            throw RunError.refund(billing.amount.value)
        }
        return billing
    }
}

extension PatientCardSeisanUseCase {
    enum RunError: Error {
        /// 返金
        case refund(Int)
    }
}
