//
//  FileLogDaySetting.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/02/02.
//

import Foundation
import Logging

extension FileLogger {
    final class Setting {
        let rotationCount: Int
        
        static let ROTATION_COUNT = SettingValueAttr(
            label: "保持するログファイル数",
            defaultValue: 7,
            placeHolder: "例：7",
            errorMessage: "1以上の値を入力してください。",
            isValidOK: { value in return value >= 1 })
        
        init(rotationCount: Int) {
            self.rotationCount = rotationCount
        }
    }
}
