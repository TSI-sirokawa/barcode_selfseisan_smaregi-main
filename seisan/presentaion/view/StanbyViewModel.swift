//
//  StanbyViewModel.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/22.
//

import Foundation
import SwiftUI
import Logging

/// 領収書バーコード用待機画面ビューモデル
final class StanbyViewModel: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState: AppState = AppState.shared
    /// アプリ設定取得サービス
    private let appSetGetSvc: AppSettingGetService = AppSettingGetService.shared
    /// 待機画面表示ステータス
    @Published private(set) var viewStatus = ViewStatusType.`init`
    /// アプリケーション設定が完了しているかどうか
    @Published private(set) var isAppSettingOK = false
    /// バーコード入力フック用待機画面ビューコントローラ
    @Published var barcodeInputViewCtrl: UIViewController?
    /// バーコード文字列読み込み用バッファ
    @Published var barcodeBuf = ""
    /// 背景画像
    @Published var bgImage: UIImage
    
    init() {
        viewStatus = .wait
        
        // 背景画像を読み込む
        bgImage = ViewSetting.loadStanbyBGImage(barcordType: appSetGetSvc.getMustAppSetting().barcodeType)
    }
    
    /// アプリ設定を読み込む
    func reloadAppSetting() {
        // アプリ設定状態を読み込んで、現在のアプリ設定をアプリ設定取得サービスにセット
        let appSettingState = AppSettingStateService.shared.load()
        AppSettingGetService.shared.update(appSettingState.isAppSettingOK(), appSettingState.getAppSetting())
        
        isAppSettingOK = appSetGetSvc.isAppSettingOK()
    }
    
    /// iPadホーム画面や他のアプリから本アプリに戻ってきた
    func onActive() {
        // 背景画像を読み込む
        bgImage = ViewSetting.loadStanbyBGImage(barcordType: appSetGetSvc.getMustAppSetting().barcodeType)
    }
    
    /// 画面表示
    func onApear() {
        // 背景画像を読み込む
        bgImage = ViewSetting.loadStanbyBGImage(barcordType: appSetGetSvc.getMustAppSetting().barcodeType)
    }
    
    
    /// バーコード文字列を入力する
    /// - Parameter barcode: バーコード文字列
    /// - Returns: バーコード文字列を受け付けたかどうか
    func inputBarcode(_ barcode: String) -> Bool {
        log.debug("\(type(of: self)): barcode input start. value=\(barcode)")
        
        viewStatus = .barcord
        
        do {
            var receiptBarcode: ReceiptBarcode
            do {
                receiptBarcode = try ReceiptBarcode(barcode)
            } catch {
                throw LocalError.argument("不正なバーコードです\n\(error))")
            }
            
            let billing = try ReceiptSeisanUseCase(barcode: receiptBarcode).exec()
            log.info("\(type(of: self)): barcode input ok. value=\(billing)")
            
            appState.setSeisan(billing: billing)
        } catch {
            log.error("\(type(of: self)): error has occurred: \(error)")
            viewStatus = .error(message: "\(error)")
            return false
        }
        
        // 次画面に遷移
        appState.nextScreen()
        return true
    }
}

extension StanbyViewModel {
    /// 待機画面表示ステータス種別
    enum ViewStatusType: Equatable {
        ///  初期化中
        case `init`
        /// 待機中
        case wait
        /// バーコード入力中
        case barcord
        /// エラー中
        case error(message: String)
    }
    
    enum LocalError: Error {
        case argument(String)
    }
}
