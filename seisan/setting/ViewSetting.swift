//
//  ViewSetting.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/29.
//

import Foundation
import Logging

final class ViewSetting {
    private static let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// 背景画像を配置するディレクトリ名
    static let BGIMAGE_DIRNAME = "BGImage"
    
    /// 待機画面の背景画像ファイルを配置するディレクトリ名
    static let BGIMAGE_STANBY_DIR_NAME = "\(BGIMAGE_DIRNAME)/stanby"
    
    /// 精算完了メッセージ表示時間[秒]
    let seisanCompleteViewMessageDisplayTimeSec: Int
    
    /// 精算完了時のメッセージ（おつりがない場合）
    let seisanCompleteViewMessageNoChange: String
    
    /// 精算完了時のメッセージ（おつりがある場合）
    let seisanCompleteViewMessageWithChange: String
    
    /// 精算完了時の処方箋引換券受け取り案内メッセージ
    let seisanCompleteViewShohosenHikikaekenMessage: String
    
    init(seisanCompleteViewWaitTimeSec: Int,
         seisanCompleteViewMessageNoChange: String,
         seisanCompleteViewMessageWithChange: String,
         seisanCompleteViewShohosenHikikaekenMessage: String) {
        self.seisanCompleteViewMessageDisplayTimeSec = seisanCompleteViewWaitTimeSec
        self.seisanCompleteViewMessageNoChange = seisanCompleteViewMessageNoChange
        self.seisanCompleteViewMessageWithChange = seisanCompleteViewMessageWithChange
        self.seisanCompleteViewShohosenHikikaekenMessage = seisanCompleteViewShohosenHikikaekenMessage
    }
    
    /// 待機画面の背景画像を読み込む
    /// 　→待機画面の背景画像格納先ディレクトリに画像が、配置されている場合は画像ファイルを返す。
    /// 　　配置されていない場合はアプリに組み込んだデフォルト画像を返す
    /// 　→待機画面の背景画像格納先ディレクトリのファイルが複数ある場合、１番目に取得したファイルを返す
    ///
    /// - Parameter barcordType: バーコード種別
    /// - Returns: 待機画面の背景画像
    static func loadStanbyBGImage(barcordType: AppSetting.BarcodeType) -> UIImage {
        let (bgImage, _) = ViewSetting.tryLoadStanbyBGImage(barcordType: barcordType)
        return bgImage
    }
    
    /// 待機画面の背景画像を読み込む、かつ、デフォルト画像かどうかも取得する
    /// 　→待機画面の背景画像格納先ディレクトリに画像が、配置されている場合は画像ファイルを返す。
    /// 　　配置されていない場合はアプリに組み込んだデフォルト画像を返す
    /// 　→待機画面の背景画像格納先ディレクトリのファイルが複数ある場合、１番目に取得したファイルを返す
    ///
    /// - Parameter barcordType: バーコード種別
    /// - Returns: 「待機画面の背景画像」 と「デフォルト画像かどうかのフラグ」
    static func tryLoadStanbyBGImage(barcordType: AppSetting.BarcodeType) -> (UIImage, Bool) {
        // 待機画面の背景画像格納先ディレクトリを取得
        let dirUrl = ViewSetting.getStanbyBGImageDirURL()
        
        // ファイルを列挙
        var filePathes: [String] = []
        do {
            filePathes = try FileManager.default.contentsOfDirectory(atPath: dirUrl.path)
        } catch {
            log.warning("enum stanby image file error. dir=\(dirUrl): \(error)")
            
            // デフォルト画像を取得
            let bgImage = ViewSetting.getStanbyBGImageDefault(barcordType: barcordType)
            return (bgImage, true)
        }
        
        if filePathes.isEmpty {
            // ファイルが無かった場合
            
            // デフォルト画像を取得
            let bgImage = ViewSetting.getStanbyBGImageDefault(barcordType: barcordType)
            return (bgImage, true)
        }
        
        // ファイルからUIImageを生成
        let filePathUrl = dirUrl.appendingPathComponent(filePathes[0])
        guard let bgImage = UIImage(contentsOfFile: filePathUrl.path) else {
            // UIImageを生成できなかった場合
            log.warning("load stanby image error. dir=\(filePathUrl)")
            
            // デフォルト画像を取得
            let bgImage = ViewSetting.getStanbyBGImageDefault(barcordType: barcordType)
            return (bgImage, true)
        }
        
        return (bgImage, false)
    }
    
    /// 待機画面の背景画像のデフォルトイメージを取得する
    /// - Parameter barcordType: バーコード種別
    /// - Returns: デフォルトイメージ
    private static func getStanbyBGImageDefault(barcordType: AppSetting.BarcodeType) -> UIImage {
        switch barcordType {
        case .ReceiptBarcord:
            // 領収書バーコードモード
            return UIImage(imageLiteralResourceName: "Images/1")
        case .PatientCardBarcord:
            // 診察券バーコードモード
            return UIImage(imageLiteralResourceName: "Images/2")
        }
    }
    
    /// 待機画面の背景画像格納先ディレクトリURL（端末内のパス）を取得
    /// - Returns: 待機画面の背景画像格納先ディレクトリURL
    static func getStanbyBGImageDirURL() -> URL {
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dirUrl = docURL.appendingPathComponent(ViewSetting.BGIMAGE_STANBY_DIR_NAME)
        return dirUrl
    }
}

extension ViewSetting {
    static let STANBY_BGIMAGE = SettingValueAttr(
        label: "精算待機画面の背景画像",
        defaultValue: UIImage(), // デフォルト画像はバーコード設定のモードで変わるため、ここでは設定しない
        placeHolder: "背景画像",
        errorMessage: "背景画像を設定してください。",
        isValidOK: { value in return value.size.width > 0 && value.size.height > 0 })
    
    static let SEISAN_COMPLETE_VIEW_MESSAGE_DISPLAY_TIME_SEC = SettingValueAttr(
        label: "精算完了メッセージ表示時間[秒]",
        defaultValue: 5,
        placeHolder: "精算完了メッセージ表示時間",
        errorMessage: "入力してください。",
        isValidOK: { value in return value >= 0 })
    
    static let SEISAN_COMPLETE_VIEW_MESSAGE_NO_CHANGE = SettingValueAttr(
        label: "精算完了時のメッセージ（おつりがない場合）",
        defaultValue: "精算が完了しました\n気をつけてお帰りください",
        placeHolder: "例：精算が完了しました\n気をつけてお帰りください",
        errorMessage: "入力してください。",
        isValidOK: { value in return value.count > 0 })
    
    static let SEISAN_COMPLETE_VIEW_MESSAGE_WITH_CHANGE = SettingValueAttr(
        label: "精算完了時のメッセージ（おつりがある場合）",
        defaultValue: "おつりをお受け取りの上\n気をつけてお帰りください",
        placeHolder: "例：おつりをお受け取りの上\n気をつけてお帰りください",
        errorMessage: "入力してください。",
        isValidOK: { value in return value.count > 0 })
    
    static let SEISAN_COMPLETE_VIEW_SHOHOSEN_HIKIKAKEN_MESSAGE = SettingValueAttr(
        label: "処方箋引換券の受け取り案内メッセージ（処方箋引換券を印刷した場合）",
        defaultValue: "処方箋引換券を受け取って受付へお越しください",
        placeHolder: "例：処方箋引換券を受け取って受付へお越しください",
        errorMessage: "入力してください。",
        isValidOK: { value in return value.count >= 0 })
}
