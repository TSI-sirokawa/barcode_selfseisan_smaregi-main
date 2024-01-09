//
//  ViewSettingState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/29.
//

import Foundation
import Logging

// 画面設定状態
final class ViewSettingState: SettingCheckProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    ///  バーコード設定状態　※参照のみ
    var selectedBarcodeState: SelectedBarcodeState?
    
    /// 精算待機画面の背景画像はファイルを直接読み込むため定義しない
    
    /// 精算完了メッセージ表示時間[秒]
    var seisanCompleteViewMessageDisplayTimeSec: Int {
        didSet {
            if seisanCompleteViewMessageDisplayTimeSec != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 精算完了時のメッセージ（おつりがない場合）
    var seisanCompleteViewMessageNoChange: String {
        didSet {
            if seisanCompleteViewMessageNoChange != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 精算完了時のメッセージ（おつりがある場合）
    var seisanCompleteViewMessageWithChange: String {
        didSet {
            if seisanCompleteViewMessageWithChange != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 精算完了時の処方箋引換券受け取り案内メッセージ
    var seisanCompleteViewShohosenHikikaekenMessage: String {
        didSet {
            if seisanCompleteViewShohosenHikikaekenMessage != oldValue {
                validateSetting()
            }
        }
    }
    
    /// バリデーション結果
    var isSeisanCompleteViewMessageDisplayTimeSecOK = false
    var isSeisanCompleteViewMessageNoChangeOK = false
    var isSeisanCompleteViewMessageWithChangeOK = false
    var isSeisanCompleteViewShohosenHikikaekenMessageOK = false
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        get {
            // 設定項目が増えた場合はここに項目をAND条件で追加
            return isSeisanCompleteViewMessageDisplayTimeSecOK &&
            isSeisanCompleteViewMessageNoChangeOK &&
            isSeisanCompleteViewMessageWithChangeOK &&
            isSeisanCompleteViewShohosenHikikaekenMessageOK
        }
    }
    /// テストが完了したかどうか
    var isTestOK: Bool {
        get {
            // 現バージョンではテストがないため、設定完了状態をそのまま返す
            return isSettingOK
        }
    }
    
    /// 設定内容を端的に説明するサマリ
    var shortSummary: String {
        var summary = ""
        
        // 待機画面の背景画像
        summary += "精算待機画面（"
        
        let (_, isDefault) = ViewSetting.tryLoadStanbyBGImage(barcordType: selectedBarcodeState!.selectedType)
        summary += (isDefault ? "標準": "画像ファイル")
        summary += "）"
        
        return summary
    }
    
    static let DEFAULT = ViewSettingState(
        seisanCompleteViewMessageDisplayTimeSec: ViewSetting.SEISAN_COMPLETE_VIEW_MESSAGE_DISPLAY_TIME_SEC.defaultValue,
        seisanCompleteViewMessageNoChange: ViewSetting.SEISAN_COMPLETE_VIEW_MESSAGE_NO_CHANGE.defaultValue,
        seisanCompleteViewMessageWithChange: ViewSetting.SEISAN_COMPLETE_VIEW_MESSAGE_WITH_CHANGE.defaultValue,
        seisanCompleteViewShohosenHikikaekenMessage: ViewSetting.SEISAN_COMPLETE_VIEW_SHOHOSEN_HIKIKAKEN_MESSAGE.defaultValue)
    
    init(seisanCompleteViewMessageDisplayTimeSec: Int,
         seisanCompleteViewMessageNoChange: String,
         seisanCompleteViewMessageWithChange: String,
         seisanCompleteViewShohosenHikikaekenMessage: String) {
        self.seisanCompleteViewMessageDisplayTimeSec = seisanCompleteViewMessageDisplayTimeSec
        self.seisanCompleteViewMessageNoChange = seisanCompleteViewMessageNoChange
        self.seisanCompleteViewMessageWithChange = seisanCompleteViewMessageWithChange
        self.seisanCompleteViewShohosenHikikaekenMessage = seisanCompleteViewShohosenHikikaekenMessage
        
        validateSetting()
    }
    
    /// バリデーション
    func validateSetting() {
        // 精算完了メッセージ表示時間[秒]
        do {
            try ViewSetting.SEISAN_COMPLETE_VIEW_MESSAGE_DISPLAY_TIME_SEC.validate(seisanCompleteViewMessageDisplayTimeSec)
            isSeisanCompleteViewMessageDisplayTimeSecOK = true
        } catch {
            isSeisanCompleteViewMessageDisplayTimeSecOK = false
        }
        
        // 精算完了時のメッセージ（おつりがない場合）
        do {
            try ViewSetting.SEISAN_COMPLETE_VIEW_MESSAGE_NO_CHANGE.validate(seisanCompleteViewMessageNoChange)
            isSeisanCompleteViewMessageNoChangeOK = true
        } catch {
            isSeisanCompleteViewMessageNoChangeOK = false
        }
        
        // 精算完了時のメッセージ（おつりがある場合）
        do {
            try ViewSetting.SEISAN_COMPLETE_VIEW_MESSAGE_WITH_CHANGE.validate(seisanCompleteViewMessageWithChange)
            isSeisanCompleteViewMessageWithChangeOK = true
        } catch {
            isSeisanCompleteViewMessageWithChangeOK = false
        }
        
        // 精算完了時の処方箋引換券受け取り案内メッセージ（処方箋引換券を印刷した場合）
        do {
            try ViewSetting.SEISAN_COMPLETE_VIEW_SHOHOSEN_HIKIKAKEN_MESSAGE.validate(seisanCompleteViewShohosenHikikaekenMessage)
            isSeisanCompleteViewShohosenHikikaekenMessageOK = true
        } catch {
            isSeisanCompleteViewShohosenHikikaekenMessageOK = false
        }
    }
    
    func getSetting() -> ViewSetting {
        let setting = ViewSetting(
            seisanCompleteViewWaitTimeSec: seisanCompleteViewMessageDisplayTimeSec,
            seisanCompleteViewMessageNoChange: seisanCompleteViewMessageNoChange,
            seisanCompleteViewMessageWithChange: seisanCompleteViewMessageWithChange,
            seisanCompleteViewShohosenHikikaekenMessage: seisanCompleteViewShohosenHikikaekenMessage)
        return setting
    }
    
    /// 待機画面の背景画像を読み込む、かつ、デフォルト画像かどうかも取得する
    /// 　→待機画面の背景画像格納先ディレクトリに画像が、配置されている場合は画像ファイルを返す。
    /// 　　配置されていない場合はアプリに組み込んだデフォルト画像を返す
    /// 　→待機画面の背景画像格納先ディレクトリのファイルが複数ある場合、１番目に取得したファイルを返す
    ///
    /// - Parameter barcordType: バーコード種別
    /// - Returns: 「待機画面の背景画像」 と「デフォルト画像かどうかのフラグ」
    func tryLoadStanbyBGImage(barcordType: AppSetting.BarcodeType) -> (UIImage, Bool) {
        let (bgImage, isDefault) = ViewSetting.tryLoadStanbyBGImage(barcordType: barcordType)
        return (bgImage, isDefault)
    }
    
    /// アプリ動作環境の初期化処理を行う
    static func execEnvInit() {
        let dirUrl = ViewSetting.getStanbyBGImageDirURL()
        do {
            try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true)
        } catch {
            print("create ryoshuin dir in document dir error: \(error)")
            return
        }
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> ViewSettingState {
        return ViewSettingState(
            // 待機画面の背景画像は、画像ファイルから直接読み込む、もしくは、アプリに組み込んだ画像を使用するため保存しない
            seisanCompleteViewMessageDisplayTimeSec: repo.load(key: "ViewSettingState.seisanCompleteViewMessageDisplayTimeSec") ?? DEFAULT.seisanCompleteViewMessageDisplayTimeSec,
            seisanCompleteViewMessageNoChange: repo.load(key: "ViewSettingState.seisanCompleteViewMessageNoChange") ?? DEFAULT.seisanCompleteViewMessageNoChange,
            seisanCompleteViewMessageWithChange: repo.load(key: "ViewSettingState.seisanCompleteViewMessageWithChange") ?? DEFAULT.seisanCompleteViewMessageWithChange,
            seisanCompleteViewShohosenHikikaekenMessage: repo.load(key: "ViewSettingState.seisanCompleteViewShohosenHikikaekenMessage") ?? DEFAULT.seisanCompleteViewShohosenHikikaekenMessage)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: ViewSettingState) {
        // 待機画面の背景画像は、画像ファイルから直接読み込む、もしくは、アプリに組み込んだ画像を使用するため保存していない
        repo.save(key: "ViewSettingState.seisanCompleteViewMessageDisplayTimeSec", value: state.seisanCompleteViewMessageDisplayTimeSec)
        repo.save(key: "ViewSettingState.seisanCompleteViewMessageNoChange", value: state.seisanCompleteViewMessageNoChange)
        repo.save(key: "ViewSettingState.seisanCompleteViewMessageWithChange", value: state.seisanCompleteViewMessageWithChange)
        repo.save(key: "ViewSettingState.seisanCompleteViewShohosenHikikaekenMessage", value: state.seisanCompleteViewShohosenHikikaekenMessage)
    }
}
