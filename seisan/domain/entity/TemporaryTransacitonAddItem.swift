//
//  TemporaryTransacitonAddItem.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/18.
//

import Foundation

/// 仮販売追加項目
final class TemporaryTransacitonAddItem: CustomStringConvertible, Codable {
    let tempTransID: TemporaryTransactionID
    /// 診療費請求書兼領収書
    let reportText: String?
    /// 診療費明細書
    let billText: String?
    let prescriptionFlg: Bool
    
    init(tempTransID: TemporaryTransactionID, reportText: String?, billText: String?, prescriptionFlg: Bool) {
        self.tempTransID = tempTransID
        self.reportText = reportText
        self.billText = billText
        self.prescriptionFlg = prescriptionFlg
    }
    
    var description: String {
        do {
            let jsonData = try JSONEncoder().encode(self)
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
