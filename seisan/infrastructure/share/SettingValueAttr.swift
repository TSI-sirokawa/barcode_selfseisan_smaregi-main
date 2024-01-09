//
//  SettingValueAttr.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/23.
//

import Foundation

final class SettingValueAttr<T> {
    let label: String
    let defaultValue: T
    let placeHolder: String
    let errorMessage: String
    let isValidOK: (T) -> Bool
    
    init(label: String, defaultValue: T, placeHolder: String, errorMessage: String, isValidOK: @escaping (T) -> Bool) {
        self.label = label
        self.defaultValue = defaultValue
        self.placeHolder = placeHolder
        self.errorMessage = errorMessage
        self.isValidOK = isValidOK
    }
    
    func validate(_ value: T) throws {
        if !isValidOK(value) {
            throw SettingError("\(label):\(errorMessage)")
        }
    }
}
