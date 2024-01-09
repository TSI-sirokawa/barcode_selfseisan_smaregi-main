//
//  UInt16.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/12/29.
//

import Foundation

extension UInt16 {
    enum UInt16Error: Error {
        case convert(message: String)
    }
    
    public static func fromString(_ elems: Array<String.Element>.SubSequence, radix: Int = 10) throws -> UInt16 {
        return try UInt16.fromString(String(elems), radix: radix)
    }
    
    public static func fromString(_ str: String, radix: Int = 10) throws -> UInt16 {
        guard let num = UInt32(str, radix: radix) else {
            throw UInt16Error.convert(message: "String to UInt32 error. str=\(str), radix=\(radix)")
        }
        if num > UInt16.max {
            throw UInt16Error.convert(message: "number greater than UInt16.max(\(UInt16.max))")
        }
        let ret = UInt16(num)
        return ret
    }
}
