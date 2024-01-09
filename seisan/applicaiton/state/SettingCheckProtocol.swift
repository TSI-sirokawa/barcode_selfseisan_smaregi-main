//
//  SettingCheckProtocol.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/28.
//

import Foundation

protocol SettingCheckProtocol {
    /// 設定値バリデーション
    /// 設定が完了したかどうかの状態を更新する
    func validateSetting()
    /// 設定が完了したかどうか
    var isSettingOK: Bool { get }
    /// テストが完了したかどうか
    var isTestOK: Bool { get }
    /// 設定内容を端的に説明するサマリ
    var shortSummary: String { get }
}
