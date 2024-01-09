//
//  PatientCardBilling.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/03.
//

import Foundation

/// 診察券請求
final class PatientCardBilling: BillingProtocol, ObservableObject, CustomStringConvertible, Codable {
    /// 請求ローカルID
    /// ・デバッグ用途
    let localID: BillingLocalID
    /// 患者
    let customer: Customer?
    /// 請求金額（合計）
    let amount: BillingAmount
    /// 収納
    private(set) var  shunos: [Shuno]
    /// 仮販売
    let tempTranses: [TemporaryTransaction]
    
    init(patient: Customer,
         billingAmount: BillingAmount,
         shunos: [Shuno],
         tempTranses: [TemporaryTransaction]) throws {
        self.localID = BillingLocalID()
        self.customer = patient
        self.amount = billingAmount
        self.shunos = shunos
        self.tempTranses = tempTranses
    }
    
    var description: String {
        do {
            let jsonData = try JSONEncoder().encode(self)
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    /// 収納を追加する
    /// - Parameter shuno: 収納
    func addShuno(_ shuno: Shuno) {
        self.shunos.append(shuno)
    }
}
