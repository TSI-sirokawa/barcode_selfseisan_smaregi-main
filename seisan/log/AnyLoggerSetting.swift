//
//  AnyLoggerSetting.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/02/03.
//

import Foundation
import Logging

extension AnyLogger {
    final class Setting {
        let isOutputEnable: Bool
        let logLevel: Logger.Level
        
        static let IS_OUTPUT_ENABLE = SettingValueAttr(
            label: "ログを記録する",
            defaultValue: true,
            placeHolder: "",
            errorMessage: "設定してください。",
            isValidOK: { value in return true })
        
        static let LOG_LEVEL = SettingValueAttr(
            label: "ログレベル",
            defaultValue: Logger.Level.info,
            placeHolder: "",
            errorMessage: "",
            isValidOK: { value in return true})
        
        init(isOutputEnable: Bool, logLevel: Logger.Level) {
            self.isOutputEnable = isOutputEnable
            self.logLevel = logLevel
        }
    }
}
