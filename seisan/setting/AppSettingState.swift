//
//  AppSettingState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/25.
//

import Foundation
import Logging

final class AppSettingState: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    @Published var selectedBarcodeState: SelectedBarcodeState
    @Published var patientCardSeisanSettingState: PatientCardSeisanSettingState
    @Published var miuProgramSettingState: MIUProgramSettingState
    @Published var selectedAutoCashierState: SelectedAutoCashierState
    @Published var grolyR08SettingState: GrolyR08AutoCashierAdapterSettingState
    @Published var groly300SettingState: Groly300AutoCashierAdapterSettingState
    @Published var creditSettingState: CregitSettingState
    @Published var smaregiSettingState: SmaregiPlatformSettingState
    @Published var tsiSmaregiMedicalSettingState: TSISmaregiMedicalSettingState
    @Published var receiptPrinterSettingState: ReceiptPrinterSettingState
    @Published var orcaSettingState: ORCASettingState
    @Published var viewSettingState: ViewSettingState
    @Published var customerDisplaySettingState: CustomerDisplaySettingState
    @Published var httpServerSettingState: HTTPServerSettingState
    @Published var logSettingState: LogSettingState
    
    @Published var barcodeSummary = ""
    @Published var patientCardSeisanSummary = ""
    @Published var miuProgramSummary = ""
    @Published var autoCashierSummary = ""
    @Published var creditSummary = ""
    @Published var smaregiSummary = ""
    @Published var tsiSmaregiMedicalSummary = ""
    @Published var receiptPrinterSummary = ""
    @Published var orcaSummary = ""
    @Published var viewSummary = ""
    @Published var customerDisplaySummary = ""
    @Published var httpServerSummary = ""
    @Published var logSummary = ""
    
    @Published var isBarcodeCompleted = false
    @Published var isPatientCardSeisanCompleted = false
    @Published var isMIUProgramCompleted = false
    @Published var isSelectedAutoCashierCompleted = false
    @Published var isAutoCashierCompleted = false
    @Published var isCreditCompleted = false
    @Published var isSmaregiCompleted = false
    @Published var isTSISmaregiMedicalCompleted = false
    @Published var isReceiptPrinterCompleted = false
    @Published var isORCACompleted = false
    @Published var isViewCompleted = false
    @Published var isCustomerViewCompleted = false
    @Published var isHTTPServerCompleted = false
    @Published var isLogCompleted = false
    
    @Published var isCompleted = false
    /// 各設定間の整合性に問題がある場合のエラー内容
    @Published var settingConsistencyErrDetail = ""
    
    /// レシートプリンタを使用するかどうか
    @Published var isUseReceiptPrinter = false
    
    init(selectedBarcodeState: SelectedBarcodeState,
         patientCardSeisanSettingState: PatientCardSeisanSettingState,
         miuProgramSettingState: MIUProgramSettingState,
         selectedAutoCashierState: SelectedAutoCashierState,
         grolyR08SettingState: GrolyR08AutoCashierAdapterSettingState,
         groly300SettingState: Groly300AutoCashierAdapterSettingState,
         creditSettingState: CregitSettingState,
         smaregiSettingState: SmaregiPlatformSettingState,
         tsiSmaregiMedicalSettingState: TSISmaregiMedicalSettingState,
         receiptPrinterSettingState: ReceiptPrinterSettingState,
         orcaSettingState: ORCASettingState,
         viewSettingState: ViewSettingState,
         customerDisplaySettingState: CustomerDisplaySettingState,
         httpServerSettingState: HTTPServerSettingState,
         logSettingState: LogSettingState) {
        self.selectedBarcodeState = selectedBarcodeState
        self.patientCardSeisanSettingState = patientCardSeisanSettingState
        self.miuProgramSettingState = miuProgramSettingState
        self.selectedAutoCashierState = selectedAutoCashierState
        self.grolyR08SettingState = grolyR08SettingState
        self.groly300SettingState = groly300SettingState
        self.creditSettingState = creditSettingState
        self.smaregiSettingState = smaregiSettingState
        self.tsiSmaregiMedicalSettingState = tsiSmaregiMedicalSettingState
        self.receiptPrinterSettingState = receiptPrinterSettingState
        self.orcaSettingState = orcaSettingState
        self.viewSettingState = viewSettingState
        self.customerDisplaySettingState = customerDisplaySettingState
        self.httpServerSettingState = httpServerSettingState
        self.logSettingState = logSettingState
        
        self.selectedAutoCashierState.onChanged = { newValue in
            // つり銭機の機種が変更されたら、テスト結果をクリアする
            self.grolyR08SettingState.clearTestResult()
            self.groly300SettingState.clearTestResult()
            self.validate()
        }
        
        // 画面設定状態からバーコード設定状態を参照するため、セットする
        self.viewSettingState.selectedBarcodeState = self.selectedBarcodeState
        
        validate()
    }
    
    /// バリデーション
    func validate() {
        // バーコード設定
        isBarcodeCompleted = selectedBarcodeState.isSettingOK && selectedBarcodeState.isTestOK
        barcodeSummary = selectedBarcodeState.shortSummary
        
        if selectedBarcodeState.selectedType == .PatientCardBarcord {
            // 診察券バーコードモードの場合のみ
            
            // 診察券請求検索設定
            patientCardSeisanSettingState.validateSetting()
            isPatientCardSeisanCompleted = patientCardSeisanSettingState.isSettingOK && patientCardSeisanSettingState.isTestOK
            patientCardSeisanSummary = patientCardSeisanSettingState.shortSummary
        } else {
            isPatientCardSeisanCompleted = true
            patientCardSeisanSummary = ""
        }
        
        // つり銭機通信設定
        isSelectedAutoCashierCompleted = selectedAutoCashierState.isSettingOK && selectedAutoCashierState.isTestOK
        
        switch selectedAutoCashierState.selectedType {
        case .GrolyR08:
            grolyR08SettingState.validateSetting()
            isAutoCashierCompleted = grolyR08SettingState.isSettingOK && grolyR08SettingState.isTestOK
            autoCashierSummary = grolyR08SettingState.shortSummary
        case .Groly300:
            groly300SettingState.validateSetting()
            isAutoCashierCompleted = groly300SettingState.isSettingOK && groly300SettingState.isTestOK
            autoCashierSummary = groly300SettingState.shortSummary
        case .NoUse:
            // 使用しない
            isAutoCashierCompleted = true
            autoCashierSummary = AppSetting.AutoCashierType.NoUse.description
            break
        }
        
        // クレジットカード支払い設定
        if creditSettingState.isStoresUse {
            creditSettingState.validateSetting()
            isCreditCompleted = creditSettingState.isSettingOK && creditSettingState.isTestOK
        } else {
            isCreditCompleted = true
        }
        creditSummary = creditSettingState.shortSummary
        
        // スマレジ通信設定
        smaregiSettingState.validateSetting()
        isSmaregiCompleted = smaregiSettingState.isSettingOK && smaregiSettingState.isTestOK
        smaregiSummary = smaregiSettingState.shortSummary
        
        // 条件分岐で設定されない項目があるので、予め初期化しておく
        // TSIクラウドスマレジForMedical取引履歴+α通信設定
        isTSISmaregiMedicalCompleted = true
        tsiSmaregiMedicalSummary = ""
        // ORCA通信設定
        isORCACompleted = true
        orcaSummary = ""
        // MIU連携プログラム通信設定
        isMIUProgramCompleted = true
        miuProgramSummary = ""
        if selectedBarcodeState.selectedType == .PatientCardBarcord {
            // 診察券バーコードモードの場合のみ
            
            // TSIクラウドスマレジForMedical取引履歴+α通信設定
            tsiSmaregiMedicalSettingState.validateSetting()
            isTSISmaregiMedicalCompleted = tsiSmaregiMedicalSettingState.isSettingOK && tsiSmaregiMedicalSettingState.isTestOK
            tsiSmaregiMedicalSummary = tsiSmaregiMedicalSettingState.shortSummary
            
            switch patientCardSeisanSettingState.healthcareSystemType {
            case .orca:
                // ORCA連携
                if patientCardSeisanSettingState.isORCAPaymentEnable {
                    // ORCA入金設定が有効な場合
                    // ORCA通信設定
                    orcaSettingState.validateSetting()
                    isORCACompleted = orcaSettingState.isSettingOK && orcaSettingState.isTestOK
                    orcaSummary = orcaSettingState.shortSummary
                }
            case .miu:
                // MIU連携
                miuProgramSettingState.validateSetting()
                isMIUProgramCompleted = miuProgramSettingState.isSettingOK && miuProgramSettingState.isTestOK
                miuProgramSummary = miuProgramSettingState.shortSummary
            case .csv:
                // CSV連携
                break
            }
        }
        
        // レシートプリンタを使用するかどうか
        var isUseReceiptPrinter = false
        if (selectedBarcodeState.selectedType == .PatientCardBarcord && patientCardSeisanSettingState.isUseReceiptPrinter) ||
            creditSettingState.isUseReceiptPrinter {
            // 患者番号バーコードモード、かつ、患者番号バーコードモードの設定項目内でレシート印刷を使用するものがある場合、
            // もしくは、
            // クレジットカード決済でレシートプリンタを使用する場合
            isUseReceiptPrinter = true
        }
        self.isUseReceiptPrinter = isUseReceiptPrinter
        
        isReceiptPrinterCompleted = true
        receiptPrinterSummary = ""
        if self.isUseReceiptPrinter {
            // レシートプリンタ設定
            receiptPrinterSettingState.validateSetting()
            isReceiptPrinterCompleted = receiptPrinterSettingState.isSettingOK && receiptPrinterSettingState.isTestOK
            receiptPrinterSummary = receiptPrinterSettingState.shortSummary
        }
        
        // 画面設定
        viewSettingState.validateSetting()
        isViewCompleted = viewSettingState.isSettingOK && viewSettingState.isTestOK
        viewSummary = viewSettingState.shortSummary
        
        // カスタマーディスプレイ設定
        customerDisplaySettingState.validateSetting()
        isCustomerViewCompleted = customerDisplaySettingState.isSettingOK && customerDisplaySettingState.isTestOK
        customerDisplaySummary = customerDisplaySettingState.shortSummary
        
        // HTTPサーバの有効／無効を更新
        // 　→何かしらの機能がHTTPサーバを必要とするかどうかで決まる
        // 　→別の機能がHTTPサーバを共有する場合は、ここOR条件で追加する
        httpServerSettingState.isEnable = customerDisplaySettingState.isEnable
        
        // HTTPサーバ設定
        // 　→本チェックはHTTPサーバを必要とする機能の設定チェックの後に実行すること
        isHTTPServerCompleted = true
        httpServerSummary = ""
        if httpServerSettingState.isEnable {
            // HTTPサーバが有効な場合
            
            httpServerSettingState.validateSetting()
            isHTTPServerCompleted = httpServerSettingState.isSettingOK && httpServerSettingState.isTestOK
            httpServerSummary = httpServerSettingState.shortSummary
            
            if httpServerSettingState.isSettingOK {
                // HTTPサーバを起動する
                httpServerSettingState.startHTTPServer()
            } else {
                // HTTPサーバを停止する
                httpServerSettingState.stopHTTPServer()
            }
        } else {
            // HTTPサーバを停止する
            httpServerSettingState.stopHTTPServer()
        }
        
        // ログ出力設定
        logSettingState.validateSetting()
        isLogCompleted = logSettingState.isSettingOK && logSettingState.isTestOK
        logSummary = logSettingState.shortSummary
        
        // 決済手段（つり銭機／クレジットカード）はいずれかが有効である必要がある
        // 　→全て無効な場合は設定完了としない
        let isKesaiOK = selectedAutoCashierState.selectedType != .NoUse || creditSettingState.isStoresUse
        if !isKesaiOK {
            settingConsistencyErrDetail = "つり銭機、または、クレジットカード支払いを有効にしてください。"
        }
        
        // 設定完了確認
        isCompleted = (isKesaiOK &&
                       isBarcodeCompleted &&
                       isPatientCardSeisanCompleted &&
                       isMIUProgramCompleted &&
                       isSelectedAutoCashierCompleted &&
                       isAutoCashierCompleted &&
                       isCreditCompleted &&
                       isSmaregiCompleted &&
                       isTSISmaregiMedicalCompleted &&
                       isReceiptPrinterCompleted &&
                       isORCACompleted &&
                       isViewCompleted &&
                       isCustomerViewCompleted &&
                       isHTTPServerCompleted &&
                       isLogCompleted)
    }
    
    func isAppSettingOK() -> Bool {
        return isCompleted
    }
    
    func getAppSetting() -> AppSetting {
        let barcodeType = selectedBarcodeState.getSetting()
        
        var patientCardSeisanSetting: PatientCardSeisanSetting?
        var tsiSmaregiMedicalSetting: TSISmaregiMedicalRepository.Setting?
        var orcaSetting: ORCARepository.Setting?
        var miuProgramSetting: MIUProgram.Setting?
        switch barcodeType {
        case .PatientCardBarcord:
            // 診察券バーコードモード
            patientCardSeisanSetting = patientCardSeisanSettingState.getSetting()
            tsiSmaregiMedicalSetting = tsiSmaregiMedicalSettingState.getSetting()
            
            if let patientCardSeisanSetting = patientCardSeisanSetting {
                switch patientCardSeisanSettingState.healthcareSystemType {
                case .orca:
                    // ORCA連携
                    if patientCardSeisanSetting.isORCAPaymentEnable {
                        // ORCA入金処理が有効な場合
                        orcaSetting = orcaSettingState.getSetting()
                    }
                case .miu:
                    // MIU連携
                    miuProgramSetting = miuProgramSettingState.getSetting()
                case .csv:
                    // CSV連携
                    break
                }
            }
        default:
            break
        }
        
        var grolyR08Setting: GrolyR08AutoCashierAdapter.Setting?
        var groly300Setting: Groly300AutoCashierAdapter.Setting?
        switch selectedAutoCashierState.selectedType {
        case .GrolyR08:
            grolyR08Setting = grolyR08SettingState.getSetting()
        case .Groly300:
            groly300Setting = groly300SettingState.getSetting()
        case .NoUse:
            // 使用しない
            break
        }
        
        var httpServerSetting: HTTPServer.Setting?
        if customerDisplaySettingState.isEnable {
            // カスタマーディスプレイが有効な場合
            
            // HTTPサーバ設定
            httpServerSetting = httpServerSettingState.getSetting()
        }
        
        let (anyLogSetting, fileLogSetting) = logSettingState.getSetting()
        
        let appSetting = AppSetting(
            barcodeType: barcodeType,
            patientCardSeisanSetting: patientCardSeisanSetting,
            miuProgramSetting: miuProgramSetting,
            autoCashierType: selectedAutoCashierState.getSetting(),
            grolyR08Setting: grolyR08Setting,
            groly300Setting: groly300Setting,
            storesSetting: creditSettingState.getSetting(),
            smaregiSetting: smaregiSettingState.getSetting(),
            tsiSmaregiMedicalSetting: tsiSmaregiMedicalSetting,
            eposPrinterSetting: receiptPrinterSettingState.getSetting(),
            orcaSetting: orcaSetting,
            viewSetting: viewSettingState.getSetting(),
            customerDisplaySetting: customerDisplaySettingState.getSetting(),
            httpServerSetting: httpServerSetting,
            anyLogSetting: anyLogSetting,
            fileLogSetting: fileLogSetting,
            isUseReceiptPrinter: isUseReceiptPrinter)
        return appSetting
    }
}
