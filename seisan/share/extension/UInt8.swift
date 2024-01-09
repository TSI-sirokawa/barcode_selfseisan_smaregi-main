//
//  UInt8.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/12/29.
//

import Foundation

extension UInt8 {
    enum UInt8Error: Error {
        case convert(message: String)
    }
    
    public static func fromString(_ elem: String.Element, radix: Int = 10) throws -> UInt8 {
        return try UInt8.fromString(String(elem), radix: radix)
    }
    
    public static func fromString(_ str: String, radix: Int = 10) throws -> UInt8 {
        guard let num = UInt32(str, radix: radix) else {
            throw UInt8Error.convert(message: "String to UInt32 error. str=\(str), radix=\(radix)")
        }
        if num > UInt8.max {
            throw UInt8Error.convert(message: "number greater than UInt8.max(\(UInt8.max))")
        }
        let ret = UInt8(num)
        return ret
    }
}

