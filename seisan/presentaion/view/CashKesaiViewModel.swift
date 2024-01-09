//
//  CashKesaiViewModel.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/21.
//

import Foundation
import Logging
import AudioToolbox

/// 現金決済処理画面ビューモデル
final class CashKesaiViewModel: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState: AppState = AppState.shared
    /// アプリ設定取得サービス
    private let appSetGetSvc: AppSettingGetService = AppSettingGetService.shared
    /// 現金決済ユースケースプロトコル
    private var kesaiUseCase: CashKesaiUseCase?
    /// 現金決済画面表示ステータス
    @Published private(set) var viewStatus = ViewStatusType.`init` {
        didSet {
            if oldValue != self.viewStatus {
                self.log.debug("\(type(of: self)): update state. prev=\(oldValue), new=\(self.viewStatus)")
            }
            
            var isEnoughDeposit = false
            var canPayoutChange: Bool?
            if let cashKesaiState = appState.getCashKesaiState() {
                isEnoughDeposit = cashKesaiState.isEnoughDeposit
                canPayoutChange = cashKesaiState.canPayoutChange;
            }
            
            // 画面表示を更新
            updateViewProperty(
                        self.viewStatus,
                        isEnoughDeposit: isEnoughDeposit,
                        canPayoutChange: canPayoutChange)
        }
    }
    /// 顧客
    @Published var customer: Customer?
    /// 請求金額[円]
    @Published private(set) var billingAmount = 0
    /// 仮販売配列
    @Published var tempTranses: [TemporaryTransaction] = []
    /// 投入金額[円]
    @Published private(set) var depositAmount = 0
    /// 不足金額[円]
    @Published private(set) var minusAmount = 0
    /// おつり[円]
    @Published private(set) var changeAmount = 0
    /// おつり払出し可否
    @Published private(set) var announce = ""
    /// 精算ボタンが有効かどうかを示すフラグ
    @Published var isSeisanButtonEnable = false
    /// キャンセルボタンが有効かどうかを示すフラグ
    @Published var isCanelButtonEnable = false
    /// インジケーター表示を制御するフラグ
    @Published var isIndicatorActive = false
    /// 出金抜き取り待機ダイアログ表示を制御するためのフラグ
    @Published var isRefundDialogActive = false
    /// 現金決済エラー表示ダイアログ表示を制御するフラグ
    @Published var isErrAlertActive = false
    /// 現金決済エラー表示ダイアログに表示するエラーメッセージ
    @Published var errAlertMsg = ""
    /// エラー表示ダイアログ表示中に定期的にサウンドを鳴らすためのタイマー
    @Published var errorSoundTimer: Timer?
    
    init() {
        let billing = self.appState.getMustBilling()
        customer = billing.customer
        
        if appState.getSeisanType() == .PatientCardSeisan {
            // 診察券精算の場合、請求内訳を表示
            let patientCardBilling = appState.getMustBilling() as! PatientCardBilling
            tempTranses = patientCardBilling.tempTranses
        }
        
        let cashKesaiState = CashKesaiState(billing: billing)
        cashKesaiState.didChange = { newCashKesaiState in
            // 現金決済状態更新通知
            DispatchQueue.main.async {
                self.depositAmount = newCashKesaiState.depositAmount
                self.minusAmount = newCashKesaiState.minusAmount
                self.changeAmount = newCashKesaiState.changeAmount
                
                // 現金決済画面表示ステータスを更新
                // 　→呼び出し後に、現金決済画面表示ステータス更新されたかどうかを確認するため、現在の現金決済画面表示ステータスを保持
                let prevViewStatus = self.viewStatus
                self.updateViewStatus(cashKesaiState: newCashKesaiState)
                
                // 画面表示を更新
                // ※現金決済画面表示ステータス変更時はdidSetで呼び出すが、
                //  画面表示以外でも表示を更新することがあるため、ここでも画面表示更新メソッドを呼び出す
                self.updateViewProperty(
                            self.viewStatus,
                            isEnoughDeposit: newCashKesaiState.isEnoughDeposit,
                            canPayoutChange: newCashKesaiState.canPayoutChange)
                
                if prevViewStatus != self.viewStatus {
                    self.transitionScreen()
                }
                
                if self.depositAmount != newCashKesaiState.depositAmount ||
                    self.minusAmount != newCashKesaiState.minusAmount ||
                    self.changeAmount != newCashKesaiState.changeAmount ||
                    prevViewStatus != self.viewStatus {
                    self.log.debug("\(type(of: self)): update state. prev=\(prevViewStatus), new=\(self.viewStatus), kesai=\(newCashKesaiState)")
                }
            }
        }
        self.appState.setCashKesaiState(cashKesaiState)
        billingAmount = self.appState.getCashKesaiState()!.billing.amount.value
        minusAmount = self.appState.getCashKesaiState()!.minusAmount
    }
    
    /// 現金決済状態を現金決済画面表示ステータスに反映する
    /// - Parameter cashKesaiState: 現金決済状態
    private func updateViewStatus(cashKesaiState: CashKesaiState) {
        switch viewStatus {
        case .`init`:
            break
        case .start:
            switch cashKesaiState.cashKesaiStatus {
            case  .payment:
                viewStatus = .payment
            case .error(let message):
                viewStatus = .error(message: message)
            default:
                break
            }
        case .payment:
            switch cashKesaiState.cashKesaiStatus {
            case  .fixWait:
                viewStatus = .fixWait
            case .error(let message):
                viewStatus = .error(message: message)
            default:
                break
            }
        case .fixWait:
            switch cashKesaiState.cashKesaiStatus {
            case .error(let message):
                viewStatus = .error(message: message)
            default:
                break
            }
        case .change:
            break
        case .fix:
            switch cashKesaiState.cashKesaiStatus {
            case .change:
                viewStatus = .change
            case .completed:
                viewStatus = .completed
            case .error(let message):
                viewStatus = .error(message: message)
            default:
                break
            }
        case .completed:
            break
        case .cancel:
            switch cashKesaiState.cashKesaiStatus {
            case .refund:
                viewStatus = .refund
            case .cancelled:
                viewStatus = .cancelled
            case .error(let message):
                viewStatus = .error(message: message)
            default:
                break
            }
        case .cancelled:
            break
        case .refund:
            switch cashKesaiState.cashKesaiStatus {
            case .cancelled:
                viewStatus = .cancelled
            case .error(let message):
                viewStatus = .error(message: message)
            default:
                break
            }
        case .error:
            break
        case .errorRestore:
            switch cashKesaiState.cashKesaiStatus {
            case .errorRestored:
                viewStatus = .errorRestored
                break
            default:
                break
            }
        case .errorRestored:
            // 初回の画面表示時に決済を再開
            startKesai()
            break
        case .errorCancel:
            switch cashKesaiState.cashKesaiStatus {
            case .errorCancelled:
                viewStatus = .errorCancelled
            default:
                break
            }
        case .errorCancelled:
            break
        }
    }
    
    /// 画面表示ステータスに応じた画面遷移を行う
    private func transitionScreen() {
        switch viewStatus {
        case .change, .completed:
            // 次画面に遷移
            appState.nextScreen()
        case .cancelled:
            // 前画面に遷移
            appState.prevScreen()
        case .errorCancelled:
            // 待機画面に遷移
            appState.returnStanbyScreen()
        default:
            break
        }
    }
    
    /// 現金決済を開始する
    func startKesai() {
        log.debug("\(type(of: self)): start. curr=\(viewStatus)")
        
        viewStatus = .start
        
        let cashTrans: CashTransactionProtocol = {
            switch appSetGetSvc.getMustAppSetting().autoCashierType {
            case .GrolyR08:
                return GrolyR08AutoCashierAdapter(setting: appSetGetSvc.getMustAppSetting().grolyR08Setting!)
            case .Groly300:
                return Groly300AutoCashierAdapter(setting: appSetGetSvc.getMustAppSetting().groly300Setting!)
            case .NoUse:
                // 使用しない
                fatalError("このパスを通ることはありえない")
            }
        }()
//        let cashTrans = StubAutoCashierAdapter()
        log.info("\(type(of: self)): auto cashier=\(appSetGetSvc.getMustAppSetting().autoCashierType)")
        
        kesaiUseCase = CashKesaiUseCase(
            billing: appState.getMustBilling(),
            cashKesai: appState.getCashKesaiState()!,
            cashTrans: cashTrans)
        
        kesaiUseCase!.start()
    }
    
    /// 入金を確定する
    func fixKesai() {
        log.debug("\(type(of: self)): fix. curr=\(viewStatus)")
        
        viewStatus = .fix
        
        if appState.getSeisanType() == .PatientCardSeisan && appSetGetSvc.getMustAppSetting().isUseReceiptPrinter {
            // 診察券精算、かつ、レシートプリンタを使用する場合
            
            // 仮販売追加項目を取得し、各種帳票の印刷をつり銭機の入金完了処理と並列に行う
            // ・診療費請求書兼領収書
            // ・診療費明細書
            // ・処方箋引換券
            let tempTransBGGetSvc = AppState.shared.getMustTempTransAddItemBackgroundGetService()
            
            // バックグラウンドで取得済みの仮販売追加項目を取得
            let addItems = tempTransBGGetSvc.getMustResult()
            
            // 印刷機能については、印刷シーケンスをアプリ層で実装しているため、レシート印刷サービスをアプリ層から取得
            let receptPrintSvc = AppState.shared.getMustReceiptPrintService()
            
            // 診察券請求モデルを取得
            let billing = self.appState.getMustBilling()
            let patientCardBilling = billing as! PatientCardBilling
            
            // 印刷を開始
            TempTransactionAddItemPrintService(
                setting: appSetGetSvc.getMustAppSetting().patientCardSeisanSetting!,
                patientCardBilling: patientCardBilling,
                addItems: addItems,
                receiptPrintSvc: receptPrintSvc).exec()
        }
        
        kesaiUseCase!.fix()
    }
    
    /// 現金決済をキャンセルする
    func cancelKesai() {
        log.debug("\(type(of: self)): cancel. curr=\(viewStatus)")
        
        viewStatus = .cancel
        
        // 決済をキャンセル
        kesaiUseCase!.cancel()
    }
    
    /// エラー状態から復帰する
    func restoreKesai() {
        log.debug("\(type(of: self)): restore. curr=\(viewStatus)")
        
        stopErrSoundTimer()
        
        viewStatus = .errorRestore
        
        kesaiUseCase!.errorRestore()
    }
    
    /// エラーキャンセルを行う
    func errorCancelKesai() {
        log.debug("\(type(of: self)): error cancel. curr=\(viewStatus)")
        
        stopErrSoundTimer()
        
        viewStatus = .errorCancel
        
        kesaiUseCase!.errorCancel()
    }
    
    /// 画面表示を更新する
    /// ・ボタン有効/無効
    /// ・ダイアログ表示
    /// ・画面遷移
    /// - Parameter newValue: 現金決済画面表示ステータス
    /// - Parameter cashKesaiState: 現金決済状態
    /// - Parameter isEnoughDeposit: 投入金額が足りているかどうか
    /// - Parameter canPayoutChange: おつり払出し可否
    private func updateViewProperty(_ newValue: CashKesaiViewModel.ViewStatusType, isEnoughDeposit: Bool, canPayoutChange: Bool?) {
        var isSeisanButtonEnable = false
        var isCancelButtonEnable = false
        var isIndicatorActive = false
        var isRefundDialogActive = false
        var errAlertMsg = ""
        var isErrAlertActive = false
        
        switch newValue {
        case .`init`:
            isIndicatorActive = true
        case .start:
            isIndicatorActive = true
        case .payment:
            isCancelButtonEnable = true
        case .fixWait:
            if canPayoutChange != nil && (canPayoutChange!) {
                isSeisanButtonEnable = true
            }
            isCancelButtonEnable = true
        case .fix:
            isIndicatorActive = true
        case .change, .completed:
            break
        case .cancel:
            isIndicatorActive = true
        case .cancelled:
            break
        case .refund:
            isRefundDialogActive = true
        case .error(let message):
            errAlertMsg = message
            isErrAlertActive = true
            
            // エラー通知音タイマーを開始
            stopErrSoundTimer()
            startErrSoundTimer()
        case .errorRestore:
            isIndicatorActive = true
        case .errorRestored:
            break
        case .errorCancel:
            isIndicatorActive = true
        case .errorCancelled:
            break
        }
        
        self.isSeisanButtonEnable = isSeisanButtonEnable
        self.isCanelButtonEnable = isCancelButtonEnable
        self.isIndicatorActive = isIndicatorActive
        self.isRefundDialogActive = isRefundDialogActive
        self.errAlertMsg = errAlertMsg
        self.isErrAlertActive = isErrAlertActive
        
        // 説明音声を更新
        var announce: String
        if isEnoughDeposit && canPayoutChange != nil {
            // 投入金額が足りている、かつ、おつり払出し可否確認が済んでいる場合
            if canPayoutChange! {
                announce = "表示金額に誤りがなければ\n精算ボタンを押して下さい"
            } else {
                announce = "おつりが不足しています"
            }
        } else {
            announce = "お金を投入したら\n精算ボタンを押して下さい"
        }
        self.announce = announce
    }
    
    /// エラー通知音タイマーを開始する
    private func startErrSoundTimer() {
        // まずは即時に通知音を鳴らし、その後は一定間隔で通知音を鳴らす
        AudioServicesPlaySystemSound(SystemSoundID(1005))
        errorSoundTimer = Timer.scheduledTimer(
            withTimeInterval: 10,
            repeats: true,
            block: { timer in
                AudioServicesPlaySystemSound(SystemSoundID(1005))
            })
    }
    
    /// エラー通知音タイマーを停止する
    private func stopErrSoundTimer() {
        errorSoundTimer?.invalidate()
        self.errorSoundTimer = nil
    }
}

extension CashKesaiViewModel {
    /// 現金決済画面表示ステータス種別
    enum ViewStatusType: Equatable {
        ///  初期化中
        case `init`
        /// 決済開始中
        case start
        ///  入金中
        case payment
        /// 入金確定待機中
        case fixWait
        /// 入金確定中
        case fix
        /// おつり払い出し中
        case change
        /// 決済完了
        case completed
        /// 入金キャンセル中
        case cancel
        /// 入金キャンセル完了
        case cancelled
        /// 払い戻し中
        case refund
        /// 決済エラー中
        case error(message: String)
        /// エラー復帰中
        case errorRestore
        /// エラー復帰完了
        case errorRestored
        /// エラーキャンセル中
        case errorCancel
        /// エラーキャンセル完了
        case errorCancelled
    }
}
