//
//  AnyLogger.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/02/03.
//

import Foundation
import Logging

final class AnyLogger: LogHandler {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let label: String
    private var setting: AnyLogger.Setting
    private let output: AnyLoggerOutputProtocol
    
    subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set(newValue) {
            self.metadata[metadataKey] = newValue
        }
    }
    
    var metadata = Logger.Metadata()
    var logLevel: Logging.Logger.Level
    
    init(label: String, setting: AnyLogger.Setting, output: AnyLoggerOutputProtocol) {
        self.label = label
        self.setting = setting
        self.output = output
        
        self.logLevel = self.setting.logLevel
    }
    
    func updateSetting(_ setting: AnyLogger.Setting) {
        let oldSetting = self.setting
        self.setting = setting
        logLevel = self.setting.logLevel
        
        if oldSetting.isOutputEnable != self.setting.isOutputEnable {
            log.info("\(type(of: self)): change log ouput enable. \(oldSetting.isOutputEnable) -> \(self.setting.isOutputEnable)")
        }
        if oldSetting.logLevel != self.setting.logLevel {
            log.info("\(type(of: self)): change log level. \(oldSetting.logLevel) -> \(self.setting.logLevel)")
        }
    }
    
    /// ログ出力時に、swift-logからコールバックされるメソッド
    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        if !setting.isOutputEnable {
            return
        }
        
        output.log(level: level,
                   message: message,
                   metadata: metadata,
                   source: source,
                   file: file,
                   function: function,
                   line: line)
    }
}
