//
//  AppSettingGetService.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/27.
//

import Foundation

/// アプリ設定取得サービス
/// ・精算処理時はこのサービスからアプリ設定を取得する
final class AppSettingGetService: ObservableObject {
    private var _isAppSettingOK = false
    private var _appSetting: AppSetting?
    
    /// シングルトンインスタンス
    static var shared: AppSettingGetService = .init()
    
    private init() {
    }
    
    /// アプリ設定取得サービスが保持するアプリ設定を更新する
    /// - Parameter isAppSettingOK: アプリ設定が完了しているかどうか
    /// - Parameter appSetting: アプリ設定
    func update(_ isAppSettingOK: Bool, _ appSetting: AppSetting) {
        self._appSetting = appSetting
        self._isAppSettingOK = isAppSettingOK
    }
    
    func isAppSettingOK() -> Bool {
        return _isAppSettingOK
    }
    
    func getMustAppSetting() -> AppSetting {
        return _appSetting!
    }
}
