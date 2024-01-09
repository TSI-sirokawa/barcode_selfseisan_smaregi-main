//
//  GrolyR08AutoCashierAdapterSetting.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/20.
//

import Foundation

extension GrolyR08AutoCashierAdapter {
    /// グローリーR08自動つり銭機アダプタ設定
    struct Setting {
        /// IPアドレス
        let ipAddr: String
        /// ポート番号
        let port: UInt16
        /// 通信タイムアウト時間[秒]
        let commTimeoutSec: Int
        
        init(ipAddr: String, port: UInt16, commTimeoutSec: Int) throws {
            self.ipAddr = ipAddr
            self.port = port
            self.commTimeoutSec = commTimeoutSec
            
            try Setting.IPADDR.validate(ipAddr)
            try Setting.PORT.validate(port)
            try Setting.COMM_TIMEOUT_SEC.validate(commTimeoutSec)
        }
        
        static let IPADDR = SettingValueAttr(
            label: "IPアドレス",
            defaultValue: "",
            placeHolder: "例：192.168.XXX.XXX",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
        
        static let PORT = SettingValueAttr(
            label: "ポート番号",
            defaultValue: UInt16(80),
            placeHolder: "例：80",
            errorMessage: "0〜65535の値を入力してください。例：80",
            isValidOK: { value in return true })
        
        static let COMM_TIMEOUT_SEC = SettingValueAttr(
            label: "通信タイムアウト時間[秒]",
            defaultValue: 10,
            placeHolder: "例：10",
            errorMessage: "1以上の値を入力してください。例：10",
            isValidOK: { value in return value >= 1 })
    }
}
