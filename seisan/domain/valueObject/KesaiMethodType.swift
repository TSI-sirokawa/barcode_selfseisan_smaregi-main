//
//  KesaiMethodType.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/21.
//

import Foundation

/// 決済方法種別
enum KesaiMethodType: Codable {
    /// 現金決済
    case cash
    /// クレジット決済
    case credit
}
