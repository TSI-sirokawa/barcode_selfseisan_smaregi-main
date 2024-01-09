//
//  Date.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/12/29.
//

import Foundation

extension Date {
    func getISO8601(timezoneID: String = "Asia/Tokyo") -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: timezoneID)!
        return formatter.string(from: self)
    }
    
    func format(_ dateFormat: String, timezoneID: String = "Asia/Tokyo") -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: timezoneID)!
        formatter.dateFormat = dateFormat
        return formatter.string(from: self)
    }
    
    /// 同じ日のXX時XX分XX秒を返す
    /// - Parameters:
    ///   - hour: 時
    ///   - minute: 分
    ///   - second: 秒
    ///   - timezoneID: タイムゾーンID
    /// - Returns: 同じ日のXX時XX分XX秒
    func hhmmdd(_ hour:Int, _ minute: Int, _ second: Int, timezoneID: String = "Asia/Tokyo") -> Date? {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: timezoneID)!
        
        var comps = cal.dateComponents([.year, .month, .day], from: self)
        comps.hour = hour
        comps.minute = minute
        comps.second = second
        return Calendar.current.date(from: comps)
    }
    
    /// オフセットした月の１日（ついたち）の0時0分0秒を返す
    /// - Parameter offsetMonth: オフセット月数
    /// - Parameter timezoneID: タイムゾーンID
    /// - Returns: オフセットした月の１日（ついたち）の0時0分0秒
    func firstDayOfMonth(_ offsetMonth: Int, timezoneID: String = "Asia/Tokyo") -> Date? {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: timezoneID)!
        
        guard let targetMonth = cal.date(byAdding: .month, value: offsetMonth, to: self) else {
            return nil
        }
        
        let firstDayComps = cal.dateComponents([.year, .month], from: targetMonth)
        guard let firstDay = cal.date(from: firstDayComps) else {
            return nil
        }
        
        return firstDay
    }
    
    /// オフセットした日の0時0分0秒を返す
    /// - Parameter offsetDay: オフセット日数
    /// - Parameter timezoneID: タイムゾーンID
    /// - Returns: オフセットした日の0時0分0秒
    func firstHourOfDay(_ offsetDay: Int, timezoneID: String = "Asia/Tokyo") -> Date? {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: timezoneID)!
        
        guard let targetDay = cal.date(byAdding: .day, value: offsetDay, to: self) else {
            return nil
        }
        
        let firstHourComps = cal.dateComponents([.year, .month, .day], from: targetDay)
        guard let firstHour = cal.date(from: firstHourComps) else {
            return nil
        }
        
        return firstHour
    }
    
    /// Date値間の日数差を計算する
    /// - Parameters:
    ///   - to: Date値
    ///   - timezoneID: タイムゾーンID
    /// - Returns: 日数差
    func diffDay(_ to: Date, timezoneID: String = "Asia/Tokyo") -> Double {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: timezoneID)!
        
        let comps = cal.dateComponents([.day, .hour, .minute, .second], from: self, to: to)
        
        let diff =  Double(comps.day!) +
        Double(comps.hour!) / 24 +
        Double(comps.minute!) / (24 * 60) +
        Double(comps.second!) / (24 * 60 * 60)
        return diff
    }
}
