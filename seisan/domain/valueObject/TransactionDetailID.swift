//
//  TransactionDetailID.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/06.
//

import Foundation

/// 取引明細ID
final class TransactionDetailID: CustomStringConvertible, Codable {
    let value: String
    
    init(_ value: String) {
        self.value = value
    }
    
    var description: String {
        return value
    }
}
