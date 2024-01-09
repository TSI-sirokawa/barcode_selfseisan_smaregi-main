//
//  seisanApp.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/07/18.
//

import SwiftUI
import Logging

@main
/// 精算アプリ
struct seisanApp: App {
    private let log: Logger
    
    init() {
        // アプリが稼働するにために最低限必要な初期化処理を行う
        AppEnvStartupService.execute()
        
        // アプリ設定状態サービスにリポジトリをセット
        AppSettingStateService.shared.setRepository(repo: AppSettingRepositoryFactory.create())
        
        // アプリ設定状態を読み込み
        let appSettingState = AppSettingStateService.shared.load()
        
        // 現状のアプリ設定を取得
        let appSetting = appSettingState.getAppSetting()
        
        // 現在のアプリ設定をアプリ設定取得サービスにセット
        AppSettingGetService.shared.update(appSettingState.isAppSettingOK(), appSetting)
        
        // ログのファイル出力用アダプタ
        let fileLogSetting = FileLogger.Setting(
            rotationCount: appSetting.fileLogSetting.rotationCount)
        let fileLogOutput = FileLogger(setting: fileLogSetting)
        
        // ログの標準出力用アダプタ
        let stdoutLogOutput = StdoutLogger()
        
        let anyLoggers = [
            AnyLogger(label: Bundle.main.bundleIdentifier!,
                      setting: appSetting.anyLogSetting,
                      output: fileLogOutput),
            AnyLogger(label: Bundle.main.bundleIdentifier!,
                      setting: appSetting.anyLogSetting,
                      output: stdoutLogOutput)
        ]
        
        LoggerManger.shared.setLogger(anyLoggers: anyLoggers,
                                  fileLogOutput: fileLogOutput,
                                  stdoutLogOutput: stdoutLogOutput)
        
        
        LoggingSystem.bootstrap { label in
            MultiplexLogHandler(anyLoggers as [LogHandler])
        }
        log = Logger(label: Bundle.main.bundleIdentifier!)
        
        // アプリバージョンを取得
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        log.info("\(type(of: self)): app start. version=\(version)")
    }
    
    var body: some Scene {
        WindowGroup {
            //ルート画面を開く
            RoutingView()
                .environmentObject(AppState.shared)
                .environmentObject(AppSettingStateService.shared)
                .environmentObject(AppSettingGetService.shared)
                .environmentObject(ScreenRouter.shared)
                .environmentObject(InfraManager.shared)
                .environmentObject(InfraManager.shared.announceMgr)
        }
    }
}
