//
//  Groly300AutoCashierAdapterSetting.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/20.
//

import Foundation

extension Groly300AutoCashierAdapter {
    /// グローリー300自動つり銭機通信設定
    final class Setting {
        /// ホスト名、または、IPアドレス
        let ipAddr: String
        /// ポート番号
        let port: UInt16
        /// 接続タイムアウト時間[秒]
        let connectionTimeoutSec: Int
        /// コマンド実行間隔[秒]
        let commandIntervalSec: Double
        /// レスポンスサイズが小さいコマンドの設定
        let smallSizeResp: RespSizeSetting
        /// レスポンスサイズが大きいコマンドの設定
        let largeSizeResp: RespSizeSetting
        
        init(ipAddr: String,
             port: UInt16,
             connectionTimeoutSec: Int,
             commandIntervalSec: Double,
             smallSizeResp: RespSizeSetting,
             largeSizeResp: RespSizeSetting) throws {
            self.ipAddr = ipAddr
            self.port = port
            self.connectionTimeoutSec = connectionTimeoutSec
            self.commandIntervalSec = commandIntervalSec
            self.smallSizeResp = smallSizeResp
            self.largeSizeResp = largeSizeResp
            
            try Setting.IPADDR.validate(ipAddr)
            try Setting.PORT.validate(port)
            try Setting.CONNECTION_TIMEOUT_SEC.validate(connectionTimeoutSec)
            try Setting.COMMAND_INTERVAL_SEC.validate(commandIntervalSec)
        }
        
        static let IPADDR = SettingValueAttr(
            label: "IPアドレス",
            defaultValue: "",
            placeHolder: "例：192.168.XXX.XXX",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
        
        static let PORT = SettingValueAttr(
            label: "ポート番号",
            defaultValue: UInt16(10230),
            placeHolder: "例：10230",
            errorMessage: "0〜65535の値を入力してください。例：10230",
            isValidOK: { value in return true })
        
        static let CONNECTION_TIMEOUT_SEC = SettingValueAttr(
            label: "接続タイムアウト時間[秒]",
            defaultValue: 10,
            placeHolder: "例：10",
            errorMessage: "1以上の値を入力してください。例：10",
            isValidOK: { value in return value >= 1 })
        
        static let COMMAND_INTERVAL_SEC = SettingValueAttr(
            label: "コマンド実行間隔[秒]",
            defaultValue: 0.0,
            placeHolder: "例：0",
            errorMessage: "0以上の値を入力してください。例：0",
            isValidOK: { value in return value >= 0 })
    }
    
    /// レスポンスサイズで差異のある設定
    final class RespSizeSetting {
        /// ベース待機時間[秒]
        let baseWaitSec: Double
        /// リトライ回数
        let retryCount: Int
        /// リトライ時のインクリメンタル時間[秒]
        let incTimeSec: Double
        
        init(isSmallResp: Bool, baseWaitSec: Double, retryCount: Int, incTimeSec: Double) throws {
            self.baseWaitSec = baseWaitSec
            self.retryCount = retryCount
            self.incTimeSec = incTimeSec
            
            if isSmallResp {
                try RespSizeSetting.SMALL_RESP_BASE_WAIT_SEC.validate(baseWaitSec)
                try RespSizeSetting.SMALL_RESP_RETRY_COUNT.validate(retryCount)
                try RespSizeSetting.SMALL_RESP_INC_TIME_SEC.validate(incTimeSec)
            } else {
                try RespSizeSetting.LARGE_RESP_BASE_WAIT_SEC.validate(baseWaitSec)
                try RespSizeSetting.LARGE_RESP_RETRY_COUNT.validate(retryCount)
                try RespSizeSetting.LARGE_RESP_INC_TIME_SEC.validate(incTimeSec)
            }
        }
        
        static let SMALL_RESP_BASE_WAIT_SEC = SettingValueAttr(
            label: "ベース待機時間[秒]",
            defaultValue: 0.0,
            placeHolder: "例：0",
            errorMessage: "0以上の値を入力してください。例：0",
            isValidOK: { value in return value >= 0 })
        
        static let SMALL_RESP_RETRY_COUNT = SettingValueAttr(
            label: "リトライ回数",
            defaultValue: 4,
            placeHolder: "例：4",
            errorMessage: "0以上の値を入力してください。例：4",
            isValidOK: { value in return value >= 0 })
        
        static let SMALL_RESP_INC_TIME_SEC = SettingValueAttr(
            label: "リトライ時の待機増加時間[秒]",
            defaultValue: 0.1,
            placeHolder: "例：0.1",
            errorMessage: "0以上の値を入力してください。例：0.1",
            isValidOK: { value in return value >= 0 })
        
        static let LARGE_RESP_BASE_WAIT_SEC = SettingValueAttr(
            label: "ベース待機時間[秒]",
            defaultValue: 0.0,
            placeHolder: "例：0",
            errorMessage: "0以上の値を入力してください。例：0",
            isValidOK: { value in return value >= 0 })
        
        static let LARGE_RESP_RETRY_COUNT = SettingValueAttr(
            label: "リトライ回数",
            defaultValue: 5,
            placeHolder: "例：5",
            errorMessage: "0以上の値を入力してください。例：5",
            isValidOK: { value in return value >= 0 })
        
        static let LARGE_RESP_INC_TIME_SEC = SettingValueAttr(
            label: "リトライ時の待機増加時間[秒]",
            defaultValue: 0.1,
            placeHolder: "例：0.1",
            errorMessage: "0以上の値を入力してください。例：0.1",
            isValidOK: { value in return value >= 0 })
    }
}
