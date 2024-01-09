//
//  KesaiResult.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/06.
//

import Foundation

/// 決済結果
final class KesaiResult: CustomStringConvertible, Codable {
    /// 決済方法
    let kesaiMethod: KesaiMethodType
    /// 預かり金
    let deposit: Amount
    /// 預かり金現金
    let depositCash: Amount
    /// つり銭
    let change: Amount
    /// 預かり金クレジット
    let depositCredit: Amount
    
    init(kesaiMethod: KesaiMethodType, deposit: Amount, depositCash: Amount, change: Amount, depositCredit: Amount) {
        self.kesaiMethod = kesaiMethod
        self.deposit = deposit
        self.depositCash = depositCash
        self.change = change
        self.depositCredit = depositCredit
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
