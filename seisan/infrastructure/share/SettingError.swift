//
//  SettingError.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/20.
//

import Foundation

final class SettingError: Error, CustomStringConvertible {
    let message: String
    
    var description: String {
        return "SettingError \(message)"
    }
    
    init(_ message: String) {
        self.message = message
    }
}
