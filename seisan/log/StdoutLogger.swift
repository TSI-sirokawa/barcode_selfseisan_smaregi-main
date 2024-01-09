//
//  StdfoutLogger.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/30.
//

import Foundation
import Logging

/// 標準出力ロガー
/// ・デバッグ用
final class StdoutLogger: AnyLoggerOutputProtocol {
    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt) {
            let now = Date.now
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            print("\(dateFormatter.string(from: now)): [\(level)] \(message)")
        }
}
