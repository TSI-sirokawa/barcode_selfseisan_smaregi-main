//
//  InOutType.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/20.
//

import Foundation

/// 入外種別
enum InOutType: String, Codable {
    /// 入院
    case In = "I"
    /// 外来
    case Out = "O"
}
