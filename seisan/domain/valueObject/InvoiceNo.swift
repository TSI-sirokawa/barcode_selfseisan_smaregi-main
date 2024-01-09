//
//  InvoiceNo.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/20.
//

import Foundation

/// 伝票番号
final class InvoiceNo: CustomStringConvertible, Codable, Equatable {
    let value: String
    
    init(_ value: String) {
        self.value = value
    }
    
    var description: String {
        return value
    }
    
    static func == (lhs: InvoiceNo, rhs: InvoiceNo) -> Bool {
        return lhs.value == rhs.value
    }
}
