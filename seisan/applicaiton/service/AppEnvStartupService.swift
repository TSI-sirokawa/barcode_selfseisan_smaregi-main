//
//  AppEnvStartupService.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/04/23.
//

import Foundation

/// アプリ動作環境の初期化処理を行う
final class AppEnvStartupService {
    /// 初期化処理を実行する
    static func execute() {
        // ORCA通信設定状態
        ORCASettingState.execEnvInit()
        
        // 診察券精算設定
        PatientCardSeisanSettingState.execEnvInit()
        
        // 画面設定
        ViewSettingState.execEnvInit()
    }
}
