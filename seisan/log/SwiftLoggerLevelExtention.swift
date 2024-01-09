//
//  LogLevelExtention.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/02/03.
//

import Foundation
import Logging

extension Logger.Level {
    static func parse(str: String?, defaultValue: Logger.Level) -> Logger.Level {
        guard let str = str else {
            return defaultValue
        }
        
        let ret = Logger.Level(rawValue: str) ?? defaultValue
        return ret
    }
    
    func number() -> Int {
        switch self {
        case .trace:
            return 0
        case .debug:
            return 1
        case .info:
            return 2
        case .notice:
            return 3
        case .warning:
            return 4
        case .error:
            return 5
        case .critical:
            return 6
        }
    }
}
