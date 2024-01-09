//
//  TemporaryTransactionID.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/26.
//

import Foundation

/// 仮販売取引ID
final class TemporaryTransactionID: CustomStringConvertible, Codable, Equatable {
    let value: String
    
    init(_ value: String) {
        self.value = value
    }
    
    var description: String {
        return value
    }
    
    static func == (lhs: TemporaryTransactionID, rhs: TemporaryTransactionID) -> Bool {
        return lhs.value == rhs.value
    }
}
