//
//  CreditKesaiView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/09/17.
//

import SwiftUI
import Logging
import STORESPaymentsSDK

// クレジット決済画面
struct CreditKesaiView: View {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// STORESに申請して取得したトークン（本アプリ用に発行したもの）
    static let STORES_SDK_TOKEN = "41c66de0-62f6-40a5-96fa-647b90b108ea"
    
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CreditKesaiViewModel()
    
    var body: some View {
        // 背景色を設定するためのZStack
        ZStack {
            // 背景画像
            Image("Images/haikei_1_2_6")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all) // 上下の余白まで背景色を統一
            VStack {
                CreditKesaiViewControllerRepresent(
                    billingAmount: viewModel.getBilling().amount,
                    onComplete: { viewModel.completeKesai() },
                    onCancel: { viewModel.cancelledKesai() },
                    onError: { error in
                        viewModel.errorKesai(message: "クレジット決済中にエラーが発生しました。\n\(error))")
                    })
            }
            if viewModel.viewStatus == .completed {
                // 完了後の遷移に失敗することがあるため、
                // 画面遷移復旧の仕組みでリカバリされるまでインジケータを表示
                ActivityIndicator()
            }
        }
        .onAppear {
            log.trace("\(type(of: self)): appear")
            appState.noticeCurrScreen(.creditKesai)
        }
        .navigationBarBackButtonHidden(true) // ナビゲーションバーの戻るボタン非表示 & スワイプで戻る操作無効
        .alert("エラーが発生しました。\n係員にお知らせください。", isPresented: $viewModel.isErrAlertActive) {
            Button("取引継続") {
                viewModel.restoreKesai()
            }
            Button("取引キャンセル") {
                viewModel.errorCancelKesai()
            }
            .onAppear() {
                log.error("\(type(of: self)): display error: \(viewModel.errAlertMsg)")
            }
        } message: {
            Text(viewModel.errAlertMsg)
        }
    }
}

/// STORESのログイン画面を表示するためのクラス
/// 　→STORESPaymentSDKライブラリがUIKitで作成されているため、ビューコントローラを扱う
struct CreditKesaiViewControllerRepresent: UIViewControllerRepresentable {
    let billingAmount: BillingAmount
    let onComplete: () -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void
    
    init(billingAmount: BillingAmount, onComplete: @escaping () -> Void, onCancel: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        self.billingAmount = billingAmount
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onError = onError
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        return CreditKesaiViewController(
            billingAmount: billingAmount,
            onComplete: onComplete,
            onCancel: onCancel,
            onError: onError)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}

/// STORESのログイン画面を表示するためのクラス
/// 　→STORESPaymentSDKライブラリがUIKitで作成されているため、ビューコントローラを扱う
class CreditKesaiViewController: UIViewController {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState: AppState = AppState.shared
    /// アプリ設定取得サービス
    private let appSetGetSvc: AppSettingGetService = AppSettingGetService.shared
    
    let billingAmount: BillingAmount
    let onComplete: () -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void
    
    private var isTryLogin = false
    
    init(billingAmount: BillingAmount, onComplete: @escaping () -> Void, onCancel: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        self.billingAmount = billingAmount
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onError = onError
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        let msg = "\(type(of: self)): init(coder:) has not been implemented"
        log.critical(Logger.Message(stringLiteral: msg))
        fatalError(msg)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        STP.configure(applicationToken: CreditKesaiView.STORES_SDK_TOKEN) { result in
            self.log.info("\(type(of: self)): STP.configure result = \(result)")
            
            STP.setup(.init(
                isPrintReceiptEnabled: false,
                isSendReceiptMailEnabled: false,
                mode: .semiSelfCheckout)
            )
        } terminalErrorHandler: { [weak self] terminalError in
            // 決済端末初期化エラーなどが発生した際にはこちらのクロージャが呼ばれる
            self?.log.error("\(type(of: self)): \(terminalError.title)")
            self?.onError(terminalError)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        log.debug("\(type(of: self)): appear. isSDKDisplay=\(isTryLogin)")
        if !isTryLogin {
            isTryLogin = true
            // STORES 決済のログイン画面を表示
            STP.login(presentOn: self) { [weak self] result in
                switch result {
                case .success:
                    self?.log.info("\(type(of: self)): STP.login success")
                case let .failure(error):
                    var isErrOccured = true
                    if let sdkError = error as? STORESPaymentsSDKError {
                        switch sdkError {
                        case .alreadyAuthenticated:
                            // 既にログイン済みの場合はエラーではないので処理を継続する
                            self?.log.info("\(type(of: self)): STP.login already login")
                            isErrOccured = false
                        default:
                            // ログイン画面をキャンセル（userCancelled）した場合はこのパスを通るため、そのままエラーとする。
                            // 精算中にログイン画面が表示されてはいけないので、エラーケースである。
                            break
                        }
                    }
                    
                    if isErrOccured {
                        self?.log.error("\(type(of: self)): STP.login Error = \(error)")
                        self?.onError(error)
                        return
                    }
                }
                
                self?.execPayment(self)
            }
        }
    }
    
    private func execPayment(_ viewCtrl: UIViewController?) {
        guard let viewCtrl = viewCtrl else {
            return
        }
        
        // 決済処理を実行
        STP.payment(
            presentOn: viewCtrl,
            amount: billingAmount.value,
            memo: "") { [weak self] transactionType in
                // 決済完了（STORES Payments SDKの画面は表示中）
                self?.log.info("\(type(of: self)): Payment finished type = \(transactionType)")
                
                // 印刷機能については、印刷シーケンスをアプリ層で実装しているため、レシート印刷サービスをアプリ層から取得
                let receptPrintSvc = AppState.shared.getMustReceiptPrintService()
                
                // レシートの印刷イメージを取得
                let pixelWidth = AppSettingGetService.shared.getMustAppSetting().eposPrinterSetting!.printWidthPixel
                if let receiptImage: UIImage = transactionType.receiptImage(with: Float(pixelWidth)) {
                    self?.log.info("\(type(of: self)): get credit receipt ok. pixelWidth=\(pixelWidth), receiptImage.size.width=\(receiptImage.size.width), receiptImage.scale=\(receiptImage.scale)")
                    
                    // レシートの印刷イメージを印刷を開始
                    CreditReceiptPrintService(receiptImage: receiptImage,
                                              receiptPrintSvc: receptPrintSvc).exec()
                } else {
                    // クレジットレシートイメージの取得失敗はほぼ起こり得ないとして処理を続ける
                    self?.log.error("\(type(of: self)): get credit receipt image error")
                }
                
                if self?.appState.getSeisanType() == .PatientCardSeisan ,
                   let appSetting = self?.appSetGetSvc.getMustAppSetting(), appSetting.isUseReceiptPrinter {
                    // 診察券精算、かつ、レシートプリンタを使用する場合
                    
                    // 仮販売追加項目を取得し、各種帳票の印刷をつり銭機の入金完了処理と並列に行う
                    // ・診療費請求書兼領収書
                    // ・診療費明細書
                    // ・処方箋引換券
                    let tempTransBGGetSvc = AppState.shared.getMustTempTransAddItemBackgroundGetService()
                    
                    // バックグラウンドで取得済みの仮販売追加項目を取得
                    let addItems = tempTransBGGetSvc.getMustResult()
                    
                    // 診察券請求モデルを取得
                    let billing = self?.appState.getMustBilling()
                    let patientCardBilling = billing as! PatientCardBilling
                    
                    // アプリ設定を取得
                    if let appSetting = self?.appSetGetSvc.getMustAppSetting() {
                        // コールバック実行後にしか画面遷移を行わないため、
                        // nilになることはありえないがnilチェックで括った方が見通しが良いため、
                        // 当実装とした
                        
                        // 印刷を開始
                        TempTransactionAddItemPrintService(
                            setting: appSetting.patientCardSeisanSetting!,
                            patientCardBilling: patientCardBilling,
                            addItems: addItems,
                            receiptPrintSvc: receptPrintSvc).exec()
                    }
                }
            } completion: { [weak self] result in
                // 決済完了（STORES Payments SDKの画面は表示中）
                switch result {
                case let .success(transactionType):
                    self?.log.info("\(type(of: self)): Payment Completion type = \(transactionType)")
                    
                    self?.onComplete()
                case let .failure(error):
                    var isErrorOccured = true
                    if let sdkError = error as? STORESPaymentsSDKError {
                        switch sdkError {
                        case .userCancelled:
                            // キャンセルボタン押下
                            isErrorOccured = false
                            self?.log.info("\(type(of: self)): Payment Cancel")
                            self?.onCancel()
                        default:
                            self?.log.error("\(type(of: self)): Payment Error = \(error)")
                            break
                        }
                    }
                    
                    if isErrorOccured {
                        self?.onError(error)
                    }
                }
            }
    }
}

extension CreditKesaiViewController {
    /// エラー
    enum RunError: Error {
        /// 外部連携エラー
        case external(String)
    }
}

struct CreditKesaiView_Previews: PreviewProvider {
    static var previews: some View {
        CreditKesaiView()
    }
}
