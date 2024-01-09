//
//  MoneyFormat.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/07/18.
//

import Foundation

class MoneyFormat {
    /// 指定した数値を3桁毎にカンマで区切った文字列（例：1.000,000）で返す
    /// - Parameter num: 数値
    /// - Returns: 3桁毎にカンマで区切った文字列
    static func format(num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        let number = "\(formatter.string(from: NSNumber(value: num)) ?? "")円"
        return number
    }
    
    /// 指定した数値を3桁毎にカンマで区切った文字列（例：1.000,000）で返す
    /// - Parameter num: 数値文字列
    /// - Returns: 3桁毎にカンマで区切った文字列
    static func format(num: String) -> String {
        guard let n = Int(num) else {
            return ""
        }
        
        return format(num: n)
    }
    
    /// 指定した数値を3桁毎にカンマで区切った文字列（例：1.000,000）で返す
    /// - Parameter num: 金額
    /// - Returns: 3桁毎にカンマで区切った文字列
    static func format(num: Amount) -> String {
        return format(num: num.value)
    }
}
