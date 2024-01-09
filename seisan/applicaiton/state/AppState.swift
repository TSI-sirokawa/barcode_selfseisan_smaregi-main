//
//  AppState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/19.
//

import Foundation
import Combine
import Logging

/// アプリ状態
/// ・以下の状態を管理
/// 　・アプリがどう動いているか
/// 　・アプリがどう動いたか
final class AppState: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// シングルトンインスタンス
    static let shared: AppState = .init()
    
    /// 表示画面
    private var screenID: ScreenRouter.ScreenID = .rooting
    /// 精算種別
    private var seisanType: SeisanType = .ReceiptSeisan
    /// 現金決済を利用可能かどうか
    private(set) var isCashUse = false
    /// クレジット決済を利用可能かどうか
    private(set) var isCreditUse = false
    /// レシート印刷サービス
    private var receiptPrintService: ReceiptPrintService?
    /// 請求
    private var billing: BillingProtocol?
    /// 仮販売追加項目取得サービス
    private var tempTransAddItemBGGetSvc: TempTransAddItemBackgroundGetService?
    /// 現金決済状態
    private var cashKesaiState: CashKesaiState?
    /// 決済結果
    private var kesaiResult: KesaiResult?
    // 処方箋の引換券印刷を印刷したかどうか
    private(set) var isShohosenPrinted = false
    
    /// 精算毎の情報をクリアする
    func clearSeisanVariables() {
        billing = nil
        cashKesaiState = nil
        kesaiResult = nil
        isShohosenPrinted = false
    }
    
    /// 次画面に遷移する
    func nextScreen() {
        switch screenID {
        case .rooting:
            updateDisplayScreen(.stanby)
        case .stanby:
            updateDisplayScreen(.kesaiSelect)
        case .kesaiSelect:
            // 決済方法選択画面からの遷移は、ユーザの操作次第なので個別の遷移メソッドを呼び出してもらう
            break
        case .cashKesai:
            updateDisplayScreen(.seisanFinalize)
        case .creditKesai:
            updateDisplayScreen(.seisanFinalize)
        case .seisanFinalize:
            updateDisplayScreen(.complete)
        case .complete:
            returnStanbyScreen()
        }
    }
    
    /// 前画面に戻る
    func prevScreen() {
        switch screenID {
        case .rooting:
            // ルーティング画面から戻る遷移は無い
            break
        case .stanby:
            // 待機画面から戻る遷移は無い
            break
        case .kesaiSelect:
            returnStanbyScreen()
        case .cashKesai:
            updateDisplayScreen(.kesaiSelect)
        case .creditKesai:
            updateDisplayScreen(.kesaiSelect)
        case .seisanFinalize:
            // 精算終了処理画面から戻る遷移は無い
            break
        case .complete:
            // 精算完了画面から戻る遷移は無い
            break
        }
    }
    
    /// 現金決済画面に遷移する
    func selectCashKesaiScreen() {
        updateDisplayScreen(.cashKesai)
    }
    
    ///クレジット決済画面に遷移する
    func selectCreditKesaiScreen() {
        updateDisplayScreen(.creditKesai)
    }
    
    /// 待機画面に戻る
    func returnStanbyScreen() {
        updateDisplayScreen(.stanby)
    }
    
    /// 画面遷移を行う
    /// - Parameter screenID: 画面ID
    private func updateDisplayScreen(_ screenID: ScreenRouter.ScreenID) {
        let preScreenID = self.screenID
        self.screenID = screenID
        
        log.debug("\(type(of: self)): \(preScreenID) -> \(screenID)")
        ScreenRouter.shared.transition(prev: preScreenID, next: screenID)
    }
    
    /// 現在表示中の画面の通知する
    /// - Parameter screenID: 画面ID
    func noticeCurrScreen(_ screenID: ScreenRouter.ScreenID) {
        ScreenRouter.shared.noticeCurrScreen(screenID)
    }
    
    /// アプリの動作に影響を与える設定パラメータを設定する
    /// - Parameters:
    ///   - seisanType: 精算種別
    ///   - isCashUse: 現金決済を利用可能かどうか
    ///   - isCreditUse: クレジット決済を利用可能かどうか
    func setBehavior(seisanType: SeisanType, isCashUse: Bool, isCreditUse: Bool) {
        self.seisanType = seisanType
        self.isCashUse = isCashUse
        self.isCreditUse = isCreditUse
        log.info("\(type(of: self)): set behavior. seisanType=\(seisanType), isCreditUse=\(isCreditUse)")
    }
    
    func setReceiptPrintService(receiptPrintService: ReceiptPrintService) {
        self.receiptPrintService = receiptPrintService
    }
    
    func getReceiptPrintService() -> ReceiptPrintService? {
        return receiptPrintService
    }
    
    func getMustReceiptPrintService() -> ReceiptPrintService {
        return receiptPrintService!
    }
    
    func setSeisan(billing: BillingProtocol) {
        self.billing = billing
    }
    
    func getSeisanType() -> SeisanType {
        return seisanType
    }
    
    func getMustBilling() -> BillingProtocol {
        return billing!
    }
    
    func getBilling() -> BillingProtocol? {
        return billing
    }
    
    func setTempTransAddItemBackgroundGetService(tempTransAddItemBGGetSvc: TempTransAddItemBackgroundGetService) {
        self.tempTransAddItemBGGetSvc = tempTransAddItemBGGetSvc
    }
    
    /// 仮販売追加項目取得サービスを取得する
    /// - Returns: 仮販売追加項目取得サービス　※本サービスを利用しないフローではnilが返す
    func getMustTempTransAddItemBackgroundGetService() -> TempTransAddItemBackgroundGetService {
        return tempTransAddItemBGGetSvc!
    }
    
    func setCashKesaiState(_ cashKesaiState: CashKesaiState) {
        self.cashKesaiState = cashKesaiState
    }
    
    func getCashKesaiState() -> CashKesaiState? {
        return cashKesaiState
    }
    
    func setKesaiResult(kesaiResult: KesaiResult) {
        self.kesaiResult = kesaiResult
    }
    
    func getKesaiResult() -> KesaiResult {
        return kesaiResult!
    }
    
    func setIsShohosenPrinted(isShohosenPrinted: Bool) {
        self.isShohosenPrinted = isShohosenPrinted
    }
}
