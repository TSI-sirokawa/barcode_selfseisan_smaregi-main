//
//  FileSetting.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/04/23.
//

import Foundation

final class FileSetting: Codable, Equatable {
    let name: String
    let data: Data
    
    static let Empty = FileSetting(name: "", data: Data())
    
    init(name: String, data: Data) {
        self.name = name
        self.data = data
    }
    
    func invalid() -> Bool {
        return name != "" && data.count > 0
    }
    
    static func == (lhs: FileSetting, rhs: FileSetting) -> Bool {
        return lhs.name == rhs.name && lhs.data == rhs.data
    }
}
