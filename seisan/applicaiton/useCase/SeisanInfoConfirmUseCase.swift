//
//  SeisanInfoConfirmUseCase.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/09/21.
//

import Foundation

/// 精算情報確認ユースケース
final class SeisanInfoConfirmUseCase {
    /// 精算種別
    let seisanType: SeisanType
    /// 請求プロトコル
    let billing: BillingProtocol?
    
    init(seisanType: SeisanType, billing: BillingProtocol?) {
        self.seisanType = seisanType
        self.billing = billing
    }
    
    /// 実行する
    /// - Returns: 精算情報レスポンス
    func exec() throws -> SeisanInfo {
        var isPatientNoEnable = false
        var patientNo: String? = nil
        var isPatientNameEnable = false
        var patientName: String? = nil
        var billingAmount: Int? = nil
            
        switch seisanType {
        case .ReceiptSeisan:
            // 領収書精算
            // 　無効：患者番号、患者名
            // 　有効：請求金額
            isPatientNoEnable = false
            isPatientNameEnable = false
            
            if let receiptBilling = billing as? ReceiptBilling {
                billingAmount = receiptBilling.amount.value
            }
        case .PatientCardSeisan:
            // 診察券精算
            // 　有効：患者番号、患者名、請求金額
            isPatientNoEnable = true
            isPatientNameEnable = true
            
            if let patientCardBilling = billing as? PatientCardBilling {
                billingAmount = patientCardBilling.amount.value
                
                if let customer = patientCardBilling.customer {
                    patientNo = customer.code
                    patientName = customer.name
                }
            }
        }
        
        return SeisanInfo(
            isPatientNoEnable: isPatientNoEnable,
            patientNo: patientNo,
            isPatientNameEnable: isPatientNameEnable,
            patientName: patientName,
            billingAmount: billingAmount)
    }
}

extension SeisanInfoConfirmUseCase {
    // 精算情報
    struct SeisanInfo: Encodable {
        let isPatientNoEnable: Bool
        let patientNo: String?
        let isPatientNameEnable: Bool
        let patientName: String?
        let billingAmount: Int?
    }

    enum RunError: Error {
        case invalid(String)
    }
}
