//
//  AnyLoggerOutputProtocol.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/02/03.
//

import Foundation
import Logging

protocol AnyLoggerOutputProtocol {
    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt)
}
