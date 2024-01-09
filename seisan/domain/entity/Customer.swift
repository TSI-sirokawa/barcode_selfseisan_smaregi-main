//
//  Customer.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/09/13.
//

import Foundation

/// 顧客
final class Customer: CustomStringConvertible, Codable {
    private(set) var code: String
    private(set) var name: String
    
    init(code: String, name: String) throws {
        if code == "" || name == "" {
            // 空文字は許容しない
            throw ModelError.argument("code or name is invalid. code=\(code), name=\(name)")
        }
        
        self.code = code
        self.name = name
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
