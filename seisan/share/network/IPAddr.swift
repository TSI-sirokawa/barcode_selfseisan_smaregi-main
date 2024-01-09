//
//  IPAddr.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/09/27.
//

import Foundation

/// IPアドレス関連ツール
class IPAddr {
    /// WiFiインターフェイスに割り当てられたIPアドレスを取得する
    /// - Parameter callback: ビュー側で変更を検知するためにコールバックでもIPアドレスを通知する
    ///
    /// - Returns: IPアドレス。取得出来なかった場合は空文字を返す
    static func getWiFiIPAddr(callback: (String) -> Void) -> String {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0 else {
            return ""
        }
        
        var ipAddr = ""
        var pointer = interfaces
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            
            guard let addr = pointer?.pointee.ifa_addr else {
                continue
            }
            
            if addr.pointee.sa_family == UInt8(AF_INET) {
                // IPv4のみ
                
                // インターフェイスを取得
                guard let interface = pointer?.pointee, let addr = interface.ifa_addr else {
                    continue
                }
                
                let interfaceName = String(cString: interface.ifa_name)
                if interfaceName != "en0" {
                    // WiFiインターフェイス以外は何もしない
                    continue
                }
                
                // IPアドレスを取得
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(
                    UnsafePointer<sockaddr>(addr),
                    socklen_t(addr.pointee.sa_len),
                    &hostname,
                    socklen_t(hostname.count),
                    nil,
                    socklen_t(0),
                    NI_NUMERICHOST)
                ipAddr = String(cString: hostname)
                
                if ipAddr == "127.0.0.1" {
                    // ループバックアドレスは除外
                    continue
                }
                
                break
            }
        }
        
        freeifaddrs(interfaces)
        
        // コールバック通知
        callback(ipAddr)
        
        return ipAddr
    }
}
