//
//  BCC.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/12/30.
//

import Foundation

class Parity {
    /// 水平パリティを計算する
    /// - Parameter data: データ（バイト配列）
    /// - Returns: 計算結果値
    static func calcLRC(_ data: [UInt8]) -> UInt8 {
        var lrc: UInt8 = 0x00
        for i in 0..<data.count{
            lrc ^= data[i]
        }
        return lrc
    }
}
