//
//  Shuno.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/18.
//

import Foundation

/// 収納
final class Shuno: CustomStringConvertible, Codable {
    /// 伝票番号
    let invoiceNo: InvoiceNo
    /// 入外種別
    let inOut: InOutType
    /// 請求金額
    let billingAmount: BillingAmount
    /// 入金日時
    private(set) var depositDateTime: Date?
    /// 入金方法
    var depositMethod: DepositMethodType?
    /// 入金金額
    var depositAmount: Amount?
    
    init(invoiceNo: InvoiceNo,
         inOut: InOutType,
         billingAmount: BillingAmount) {
        self.invoiceNo = invoiceNo
        self.inOut = inOut
        self.billingAmount = billingAmount
    }
    
    init(invoiceNo: String,
         inOut: String,
         billingAmount: BillingAmount) throws {
        self.invoiceNo = InvoiceNo(invoiceNo)
        guard let inOutType = InOutType(rawValue: inOut) else {
            throw ModelError.argument("inOut is invalid. value=\(inOut)")
        }
        self.inOut = inOutType
        self.billingAmount = billingAmount
    }
    
    var description: String {
        do {
            let jsonData = try JSONEncoder().encode(self)
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    /// 入金方法と入金金額をセットする
    /// - Parameters:
    ///   - Date: 入金日時
    ///   - depositMethod: 入金方法
    ///   - depositAmount: 入金金額
    func setDeposit(depositDateTime: Date, depositMethod: DepositMethodType, depositAmount: Amount) {
        self.depositDateTime = depositDateTime
        self.depositMethod = depositMethod
        self.depositAmount = depositAmount
    }
}

extension Shuno {
    /// 入金方法
    enum DepositMethodType: Codable {
        case Cash
        case Credit
    }
}
