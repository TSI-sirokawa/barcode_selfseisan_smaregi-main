//
//  LoggerManger.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/27.
//

import Foundation

final class LoggerManger {
    private var anyLoggers: [AnyLogger]?
    private var fileLogOutput: FileLogger?
    private var stdoutLogOutput: StdoutLogger?
    
    /// シングルトンインスタンス
    static var shared: LoggerManger = .init()
    
    private init() {
    }
    
    func setLogger(anyLoggers: [AnyLogger], fileLogOutput: FileLogger, stdoutLogOutput: StdoutLogger) {
        self.anyLoggers = anyLoggers
        self.fileLogOutput = fileLogOutput
        self.stdoutLogOutput = stdoutLogOutput
    }
    
    func updateLogSetting(logSetting: AnyLogger.Setting, fileLogSetting: FileLogger.Setting) {
        anyLoggers?.forEach({ log in
            log.updateSetting(logSetting)
        })
        fileLogOutput?.updateSetting(fileLogSetting)
    }
}
