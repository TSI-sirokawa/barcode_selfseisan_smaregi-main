//
//  SettingView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/07/20.
//

import SwiftUI
import Logging
import STORESPaymentsSDK

/// 設定画面
struct SettingView: View {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// シーンフェーズ
    /// 　→iPadホーム画面や他のアプリから本アプリに戻ってきたことを検出するための仕組み（SwiftUIの機能）
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject var infraMgr: InfraManager
    
    @StateObject var viewModel = SettingViewModel()
    
    /// 画面の再描画を強制的に行うためのID
    @State private var updateID = UUID()
    
    private static let BARCODE_TITLE = "バーコード設定"
    private static let AUTO_CASHIER_TITLE = "つり銭機通信設定"
    private static let MIU_PG_TITLE = "MIU連携プログラム通信設定"
    private static let CREDITA_TITLE = "クレジットカード支払い設定"
    private static let PATIENT_CARD_SEISAN_TITLE = "診察券精算設定"
    private static let SMAREGI_TITLE = "スマレジ通信設定"
    private static let TSISMAREGIMEDICAL_TITLE = "TSIクラウドスマレジForMedical取引履歴+α通信設定"
    private static let RECEIPT_PRINTER_TITLE = "レシートプリンタ通信設定"
    private static let ORCA_TITLE = "ORCA通信設定"
    private static let VIEW_TITLE = "画面設定"
    private static let CUSTOMER_DISPLAY_TITLE = "カスタマーディスプレイ設定"
    private static let HTTP_SERVER_TITLE = "HTTPサーバ設定"
    private static let LOG_TITLE = "ログ出力設定"
    
    var body: some View {
        ZStack {
            if viewModel.appSettingState.httpServerSettingState.isEnable {
                // HTTPサーバが有効な場合
                
                // 以下のようにすることでWiFiのIPアドレス割当状態の変更を監視できる
                // 　以下の状態を想定
                // 　　１）WiFiを有効／無効を変更
                // 　　２）ルータが起動しておらずWiFiが接続されなかった
                //
                // ※ZStackの最下層に表示することで、ここではエンドユーザに見せないようにする
                Text(
                    IPAddr.getWiFiIPAddr(
                        callback: {
                            ipAddr in
                            if ipAddr != "" {
                                // WiFiのIPアドレスを通知
                                viewModel.notifyWiFiIPAddr(ipAddr: ipAddr)
                            } else {
                                // WiFiのIPアドレス取得失敗通知
                                viewModel.notifyWiFiIPAddrNG()
                            }
                        }
                    )
                )
                .frame(alignment: .trailing)
                .foregroundColor(.clear)
            }
            NavigationSplitView {
                Form {
                    // 各設定間の整合性に問題がある場合のエラー内容表示
                    if !viewModel.appSettingState.isCompleted && !viewModel.appSettingState.settingConsistencyErrDetail.isEmpty {
                        Section {
                            HStack {
                                Text("!")
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(Color.white)
                                    .background(Capsule()
                                        .fill(Color.red)
                                        .frame(minWidth: 25))
                                    .padding(5)
                                Text(viewModel.appSettingState.settingConsistencyErrDetail)
                                    .foregroundColor(Color.red)
                            }
                        } header: {
                            // タイトルなし
                        }
                    }
                    Section {
                        // ビューの直下には10個のビューまでしか配置できないためGroupで括る
                        Group {
                            // バーコード設定
                            Button(action: {
                                viewModel.settingView = .Barcode
                            }) {
                                SettingCategoryTitle(
                                    title: SettingView.BARCODE_TITLE,
                                    summary: viewModel.appSettingState.barcodeSummary,
                                    isCompleted: $viewModel.appSettingState.isBarcodeCompleted)
                            }
                            if viewModel.appSettingState.selectedBarcodeState.selectedType == .PatientCardBarcord {
                                // 診察券バーコードモードの場合のみ有効
                                // 診察券精算設定
                                Button(action: {
                                    viewModel.settingView = .PatientCardSeisan
                                }) {
                                    SettingCategoryTitle(
                                        title: SettingView.PATIENT_CARD_SEISAN_TITLE,
                                        summary: viewModel.appSettingState.patientCardSeisanSummary,
                                        isCompleted: $viewModel.appSettingState.isPatientCardSeisanCompleted,
                                        isHStack: false)
                                }
                                if viewModel.appSettingState.patientCardSeisanSettingState.healthcareSystemType == .miu {
                                    // MIU連携の場合のみ有効
                                    // MIU連携プログラム通信設定
                                    Button(action: {
                                        viewModel.settingView = .MIUProgram
                                    }) {
                                        SettingCategoryTitle(
                                            title: SettingView.MIU_PG_TITLE,
                                            summary: viewModel.appSettingState.miuProgramSummary,
                                            isCompleted: $viewModel.appSettingState.isMIUProgramCompleted)
                                    }
                                }
                            }
                            // つり銭機通信設定
                            Button(action: {
                                viewModel.settingView = .AutoCashier
                            }) {
                                SettingCategoryTitle(
                                    title: SettingView.AUTO_CASHIER_TITLE,
                                    summary: viewModel.appSettingState.autoCashierSummary,
                                    isCompleted: $viewModel.appSettingState.isAutoCashierCompleted)
                            }
                            // クレジットカード支払い設定
                            Button(action: {
                                viewModel.settingView = .Credit
                            }) {
                                SettingCategoryTitle(
                                    title: SettingView.CREDITA_TITLE,
                                    summary: viewModel.appSettingState.creditSummary,
                                    isCompleted: $viewModel.appSettingState.isCreditCompleted)
                            }
                            // スマレジ通信設定
                            Button(action: {
                                viewModel.settingView = .Smaregi
                            }) {
                                SettingCategoryTitle(
                                    title: SettingView.SMAREGI_TITLE,
                                    summary: viewModel.appSettingState.smaregiSummary,
                                    isCompleted: $viewModel.appSettingState.isSmaregiCompleted)
                            }
                            if viewModel.appSettingState.selectedBarcodeState.selectedType == .PatientCardBarcord {
                                // 診察券バーコードモードの場合のみ有効
                                // TSIクラウドスマレジForMedical 取引履歴+α
                                Button(action: {
                                    viewModel.settingView = .TSISmaregiMedical
                                }) {
                                    SettingCategoryTitle(
                                        title: SettingView.TSISMAREGIMEDICAL_TITLE,
                                        summary: viewModel.appSettingState.tsiSmaregiMedicalSummary,
                                        isCompleted: $viewModel.appSettingState.isTSISmaregiMedicalCompleted)
                                }
                            }
                            if viewModel.appSettingState.isUseReceiptPrinter {
                                // レシートプリンタを使用する場合
                                
                                // レシートプリンタ設定
                                Button(action: {
                                    viewModel.settingView = .ReceiptPrint
                                }) {
                                    SettingCategoryTitle(
                                        title: SettingView.RECEIPT_PRINTER_TITLE,
                                        summary: viewModel.appSettingState.receiptPrinterSummary,
                                        isCompleted: $viewModel.appSettingState.isReceiptPrinterCompleted)
                                }
                            }
                            if viewModel.appSettingState.selectedBarcodeState.selectedType == .PatientCardBarcord &&
                                viewModel.appSettingState.patientCardSeisanSettingState.healthcareSystemType == .orca &&
                                viewModel.appSettingState.patientCardSeisanSettingState.isORCAPaymentEnable {
                                // 診察券バーコードモード、かつ、ORCA入金処理が有効な場合のみ
                                // ORCA通信設定
                                Button(action: {
                                    viewModel.settingView = .ORCA
                                }) {
                                    SettingCategoryTitle(
                                        title: SettingView.ORCA_TITLE,
                                        summary: viewModel.appSettingState.orcaSummary,
                                        isCompleted: $viewModel.appSettingState.isORCACompleted)
                                }
                            }
                            // 画面設定
                            Button(action: {
                                viewModel.settingView = .View
                            }) {
                                SettingCategoryTitle(
                                    title: SettingView.VIEW_TITLE,
                                    summary: viewModel.appSettingState.viewSummary,
                                    isCompleted: $viewModel.appSettingState.isViewCompleted,
                                    isHStack: false)
                            }
                            // カスタマーディスプレイ
                            Button(action: {
                                viewModel.settingView = .CustomerDisplay
                            }) {
                                SettingCategoryTitle(
                                    title: SettingView.CUSTOMER_DISPLAY_TITLE,
                                    summary: viewModel.appSettingState.customerDisplaySummary,
                                    isCompleted: $viewModel.appSettingState.isCustomerViewCompleted)
                            }
                        }
                        // ビューの直下には10個のビューまでしか配置できないためGroupで括る
                        Group {
                            if viewModel.appSettingState.httpServerSettingState.isEnable {
                                // HTTPサーバが有効な場合
                                
                                Button(action: {
                                    viewModel.settingView = .HTTPServer
                                }) {
                                    // HTTPサーバ設定
                                    SettingCategoryTitle(
                                        title: SettingView.HTTP_SERVER_TITLE,
                                        summary: viewModel.appSettingState.httpServerSummary,
                                        isCompleted: $viewModel.appSettingState.isHTTPServerCompleted)
                                }
                            }
                        }
                        // ログ出力設定
                        Button(action: {
                            viewModel.settingView = .Log
                        }) {
                            SettingCategoryTitle(
                                title: SettingView.LOG_TITLE,
                                summary: viewModel.appSettingState.logSummary,
                                isCompleted: $viewModel.appSettingState.isLogCompleted)
                        }
                    } header: {
                        Text("アプリケーション設定")
                    }
                    // バージョン表示
                    Section {
                        Text("バージョン：\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)")
                    } header: {
                        Text("アプリケーション情報")
                    }
                }
            } detail: {
                switch viewModel.settingView {
                case .Barcode:
                    BarcodeSettingView(
                        title: SettingView.BARCODE_TITLE,
                        selectedBarcodeState: $viewModel.appSettingState.selectedBarcodeState,
                        onEditEnd: { viewModel.saveAppSettingState() })
                case .PatientCardSeisan:
                    PatientCardBillingSettingView(
                        title: SettingView.PATIENT_CARD_SEISAN_TITLE,
                        state: $viewModel.appSettingState.patientCardSeisanSettingState,
                        onEditEnd: { viewModel.saveAppSettingState() })
                case .MIUProgram:
                    MIUProgramSettingView(
                        title: SettingView.MIU_PG_TITLE,
                        state: $viewModel.appSettingState.miuProgramSettingState,
                        onEditEnd: { viewModel.saveAppSettingState() },
                        onCommTestRequest: { viewModel.execMIUProgramCommTest()})
                case .AutoCashier:
                    AutoCashierSettingView(
                        title: SettingView.AUTO_CASHIER_TITLE,
                        selectedAutoCashierState: $viewModel.appSettingState.selectedAutoCashierState,
                        grolyR08SettingState: $viewModel.appSettingState.grolyR08SettingState,
                        groly300SettingState: $viewModel.appSettingState.groly300SettingState,
                        onEditEnd: { viewModel.saveAppSettingState() },
                        onCommTestRequest: { viewModel.execAutoCashierCommTest() })
                case .Credit:
                    CreditSettingView(
                        title: SettingView.CREDITA_TITLE,
                        state: $viewModel.appSettingState.creditSettingState,
                        onEditEnd: { viewModel.saveAppSettingState() },
                        onSTORESLoginOK: { viewModel.noticeSTORESLoginOK() },
                        onSTORESLoginNG: { error in viewModel.noticeSTORESLoginNG(error: error) },
                        onSTORESLogoutOK: { viewModel.noticeSTORESLogoutOK() })
                case .Smaregi:
                    SmaregiSettingView(
                        title: SettingView.SMAREGI_TITLE,
                        state: $viewModel.appSettingState.smaregiSettingState,
                        selectedBarcodeState: viewModel.appSettingState.selectedBarcodeState,
                        onEditEnd: { viewModel.saveAppSettingState() },
                        onCommTestRequest: { viewModel.execSmaregiCommTest()})
                case .TSISmaregiMedical:
                    TSISmaregiMedicalSettingView(
                        title: SettingView.TSISMAREGIMEDICAL_TITLE,
                        state: $viewModel.appSettingState.tsiSmaregiMedicalSettingState,
                        onEditEnd: { viewModel.saveAppSettingState() },
                        onCommTestRequest: { viewModel.execTSISmaregiMedicalCommTest()})
                case .ReceiptPrint:
                    ReceiptPrinterSettingView(
                        title: SettingView.RECEIPT_PRINTER_TITLE,
                        state: $viewModel.appSettingState.receiptPrinterSettingState,
                        onEditEnd: { viewModel.saveAppSettingState() },
                        onCommTestRequest: { viewModel.execReceiptPrintTest() })
                case .ORCA:
                    ORCASettingView(
                        title: SettingView.ORCA_TITLE,
                        state: $viewModel.appSettingState.orcaSettingState,
                        onEditEnd: { viewModel.saveAppSettingState() },
                        onCommTestRequest: { viewModel.execORCACommTest()})
                case .View:
                    // 画面設定
                    ViewSettingView(
                        title: SettingView.VIEW_TITLE,
                        state: $viewModel.appSettingState.viewSettingState,
                        selectedBarcodeState: viewModel.appSettingState.selectedBarcodeState,
                        onEditEnd: { viewModel.saveAppSettingState() })
                case .CustomerDisplay:
                    // カスタマーディスプレイ
                    CustomerDisplaySettingView(
                        title: SettingView.CUSTOMER_DISPLAY_TITLE,
                        state: $viewModel.appSettingState.customerDisplaySettingState,
                        onEditEnd: {
                            viewModel.saveAppSettingState()
                        })
                case .HTTPServer:
                    // HTTPサーバ
                    HTTPServerSettingView(
                        title: SettingView.HTTP_SERVER_TITLE,
                        state: $viewModel.appSettingState.httpServerSettingState,
                        onEditEnd: {
                            viewModel.saveAppSettingState()
                        },
                        onCommTestRequest: {
                            viewModel.execHTTPServerCommTest()
                        })
                case .Log:
                    LogSettingView(
                        title: SettingView.LOG_TITLE,
                        state: $viewModel.appSettingState.logSettingState,
                        onEditEnd: { viewModel.saveAppSettingState() })
                }
            }
            if viewModel.isTestExecuting {
                ActivityIndicator()
            }
        }
        .alert("通知", isPresented: $viewModel.isAlertActive) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .active {
                // iPadホーム画面や他のアプリから本アプリに戻ってきた場合
                
                // 画面の再描画を行う
                // 　→この処理で「画面設定」のサマリ表示を更新する
                // 　　→「画面設定」の「西安待機画面の背景画像」ファイルを変更した場合にサマリ表示が更新されないため
                // 　　　→ビューにバインドしたサマリプロパティ（shortSummary）のネストが深いためと思われる
                updateID = UUID()
            }
        }
        .onAppear {
            log.trace("\(type(of: self)): appear")
            viewModel.onApear()
        }
        .navigationTitle("設定")
        .id(updateID)
    }
}

extension SettingView {
    /// バーコード設定画面
    private struct BarcodeSettingView: View {
        let title: String
        @Binding var selectedBarcodeState: SelectedBarcodeState
        var onEditEnd: () -> Void
        
        var body: some View {
            Form {
                Section {
                    // つり銭機の選択
                    Picker(selection: $selectedBarcodeState.selectedType, label: Text("モード選択"), content: {
                        ForEach(AppSetting.BarcodeType.allCases, id:\.self) { value in
                            Text("\(value.description)モード").tag(value)
                        }
                    })
                    .onChange(of: selectedBarcodeState.selectedType) { newValue in
                        onEditEnd()
                    }
                }
            }
            .navigationTitle(title)
        }
    }
    
    /// 診察券請求設定画面
    private struct PatientCardBillingSettingView: View {
        let title: String
        @Binding var state: PatientCardSeisanSettingState
        var onEditEnd: () -> Void
        
        @State private var example: String = ""
        
        /// 設定組み合わせ毎の例
        static let EXAMPLE: Dictionary<String, String> = [
            "0000": "0654321 → 0654321",
            "0001": "0654321 →  654321",
            "0010": "0654321 → 065432 ",
            "0011": "0654321 →  65432 ",
            "0100": "0004321 →   04321",
            "0101": "0004321 →    4321",
            "0110": "0004321 →   0432 ",
            "0111": "0004321 →    432 ",
            "1000": "065432A → 065432 ",
            "1001": "065432A →  65432 ",
            "1010": "065432A → 06543  ",
            "1011": "065432A →  6543  ",
            "1100": "000432A →  00432 ",
            "1101": "000432A →    432 ",
            "1110": "000432A →  0043  ",
            "1111": "000432A →    43  ",
        ]
        
        var body: some View {
            Form {
                Section {
                    // 数値のみ使用
                    HStack {
                        Text(PatientCardSeisanSetting.PATIENT_NO_DECIMAL_ONLY_ENABLE.label)
                            .frame(maxWidth: 250, alignment: .leading)
                        Toggle(isOn: $state.isPatientNoDecimalOnlyEnable){}
                            .frame(alignment: .trailing)
                            .onChange(of: state.isPatientNoDecimalOnlyEnable) { newValue in
                                onEditEnd()
                            }
                    }
                    // 下位N桁使用
                    HStack {
                        Text(PatientCardSeisanSetting.PATIENT_NO_LOWER_DIGITS_ENABLE.label)
                            .frame(maxWidth: 250, alignment: .leading)
                        Toggle(isOn: $state.isPatientNoLowerDigitsEnable){}
                            .frame(alignment: .trailing)
                            .onChange(of: state.isPatientNoLowerDigitsEnable) { newValue in
                                onEditEnd()
                            }
                    }
                    if state.isPatientNoLowerDigitsEnable {
                        // 下位N桁使用が有効な場合
                        
                        // 下位N桁使用の桁数
                        StringSettingField(
                            valueAttr: PatientCardSeisanSetting.PATIENT_NO_LOWER_DIGITS,
                            titlePrefix: "　",
                            value: $state.patientNoLowerDigitsStr,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $state.isPatientNoLowerDigitsStrOK,
                            onEditEnd: { onEditEnd() },
                            labelMaxWidth: 140,
                            errMsgMaxWidth: 170)
                    }
                    // 下位X桁削除
                    HStack {
                        Text(PatientCardSeisanSetting.PATIENT_NO_REMOVE_LOWER_DIGITS_ENABLE.label)
                            .frame(maxWidth: 250, alignment: .leading)
                        Toggle(isOn: $state.isPatientNoRemoveLowerDigitsEnable){}
                            .frame(alignment: .trailing)
                            .onChange(of: state.isPatientNoRemoveLowerDigitsEnable) { newValue in
                                onEditEnd()
                            }
                    }
                    if state.isPatientNoRemoveLowerDigitsEnable {
                        // 下位X桁削除が有効な場合
                        
                        // 下位X桁削除の桁数
                        StringSettingField(
                            valueAttr: PatientCardSeisanSetting.PATIENT_NO_REMOVE_LOWER_DIGITS,
                            titlePrefix: "　",
                            value: $state.patientNoRemoveLowerDigitsStr,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $state.isPatientNoRemoveLowerDigitsStrOK,
                            onEditEnd: { onEditEnd() },
                            labelMaxWidth: 140,
                            errMsgMaxWidth: 170)
                    }
                    // 前ゼロ削除
                    HStack {
                        Text(PatientCardSeisanSetting.PATIENT_NO_REMOVE_ZERO_PREFIX_ENABLE.label)
                            .frame(maxWidth: 250, alignment: .leading)
                        Toggle(isOn: $state.isPatientNoRemoveZeroPrefixEnable){}
                            .frame(alignment: .trailing)
                            .onChange(of: state.isPatientNoRemoveZeroPrefixEnable) { newValue in
                                onEditEnd()
                            }
                    }
                    // 下位X桁削除が下位N桁使用以上の場合のエラーメッセージ表示
                    if !state.isPatientNoLowerDigitsAndRemoveLowerDigitsOK {
                        Text(PatientCardSeisanSettingState.PATIENT_NO_LOWER_DIGITS_AND_REMOVE_LOWER_DIGITS_ERR_MSG)
                            .frame(alignment: .leading)
                            .foregroundColor(Color.red)
                            .background(Color.yellow)
                            .cornerRadius(5)
                    }
                    // 例示
                    Text(getPatientNoUseExample())
                        .foregroundColor(.gray)
                } header: {
                    Text("患者番号取り扱い設定　※複数項目が有効な場合は上から順に適用")
                }
                Section {
                    // 検索対象期間
                    StringSettingField(
                        valueAttr: PatientCardSeisanSetting.TEMP_TRANS_PERIOD_MONTH,
                        value: $state.tempTransPeriodMonthStr,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isTempTransPeriodMonthStrOK,
                        onEditEnd: { onEditEnd() },
                        labelMaxWidth: 140,
                        errMsgMaxWidth: 170)
                } header: {
                    Text("請求データ検索設定")
                }
                Section {
                    Picker(selection: $state.healthcareSystemType, label: Text(PatientCardSeisanSetting.HEALTHCARE_SYSTEM.label), content: {
                        ForEach(PatientCardSeisanSetting.HealthcareSystemType.allCases, id:\.self) { value in
                            Text("\(value.description)").tag(value)
                        }
                    })
                    .onChange(of: state.healthcareSystemType) { newValue in
                        onEditEnd()
                    }
                    if state.healthcareSystemType == .orca {
                        HStack {
                            Text(PatientCardSeisanSetting.ORCA_PAYMENT_ENABLE.label)
                                .frame(maxWidth: 250, alignment: .leading)
                            Toggle(isOn: $state.isORCAPaymentEnable){}
                                .frame(alignment: .trailing)
                                .onChange(of: state.isORCAPaymentEnable) { newValue in
                                    onEditEnd()
                                }
                        }
                    }
                } header: {
                    Text("医療システム連携設定")
                }
                Section {
                    // 診療費請求書兼領収書と診療費明細書を印刷するかどうか
                    HStack {
                        Text(PatientCardSeisanSetting.REPORT_AND_BILL_PRINT_ENABLE.label)
                            .frame(maxWidth: 300, alignment: .leading)
                        Toggle(isOn: $state.isReportAndBillPrintEnable){}
                            .frame(alignment: .trailing)
                            .onChange(of: state.isReportAndBillPrintEnable) { newValue in
                                onEditEnd()
                            }
                    }
                    if state.isReportAndBillPrintEnable {
                        // 診療費請求書兼領収書と診療費明細書を印刷する場合
                        
                        // 領収印を印刷するかどうか
                        HStack {
                            Text(PatientCardSeisanSetting.RYOSHUIN_PRINT_ENABLE.label)
                                .frame(maxWidth: 300, alignment: .leading)
                            Toggle(isOn: $state.isRyoshuinPrintEnable){}
                                .frame(alignment: .trailing)
                                .onChange(of: state.isRyoshuinPrintEnable) { newValue in
                                    onEditEnd()
                                }
                        }
                        if state.isRyoshuinPrintEnable {
                            // 領収印を印刷する場合
                            
                            // 領収印画像を表示
                            if let image = PatientCardSeisanSettingState.loadRyoshuinImage() {
                                HStack {
                                    // Spacerで右寄せにする
                                    Spacer()
                                    Image(uiImage: image)
                                        .onAppear {
                                            onEditEnd()
                                        }
                                }
                            } else {
                                Text("画像の読み込みに失敗しました。\n※\(PatientCardSeisanSettingState.RYOSHUIN_IMAGE_DIR_NAME)ディレクトリ直下に\(PatientCardSeisanSettingState.RYOSHUIN_IMAGE_FILE_NAME)ファイルを配置してください。")
                                    .frame(alignment: .trailing)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                                    .onAppear {
                                        onEditEnd()
                                    }
                            }
                        }
                        
                        // 診療費請求書兼領収書と診療費明細書の間で紙を切るかどうか
                        HStack {
                            Text(PatientCardSeisanSetting.REPORT_BETWEEN_BILL_CUT_ENABLE.label)
                                .frame(maxWidth: 300, alignment: .leading)
                            Toggle(isOn: $state.isReportBetweenBillCutEnable){}
                                .frame(alignment: .trailing)
                                .onChange(of: state.isReportBetweenBillCutEnable) { newValue in
                                    onEditEnd()
                                }
                        }
                        
                    }
                } header: {
                    Text("診療費請求書兼領収書と診療費明細書の設定")
                }
                Section {
                    // 処方箋引換券を印刷するかどうか
                    HStack {
                        Text(PatientCardSeisanSetting.SHOHOSEN_PRINT_ENABLE.label)
                            .frame(maxWidth: 300, alignment: .leading)
                        Toggle(isOn: $state.isShohosenPrintEnable){}
                            .frame(alignment: .trailing)
                            .onChange(of: state.isShohosenPrintEnable) { newValue in
                                onEditEnd()
                            }
                    }
                } header: {
                    Text("処方箋引換券印刷設定")
                }
            }
            .navigationTitle(title)
        }
        
        /// 設定組み合わせ毎の例を取得する
        /// - Returns: 例
        private func getPatientNoUseExample() -> String {
            var key = ""
            key += state.isPatientNoDecimalOnlyEnable ? "1": "0"
            key += state.isPatientNoLowerDigitsEnable ? "1": "0"
            key += state.isPatientNoRemoveLowerDigitsEnable ? "1": "0"
            key += state.isPatientNoRemoveZeroPrefixEnable ? "1": "0"
            
            var example = "例："
            
            example += PatientCardBillingSettingView.EXAMPLE[key]!
            
            if state.isPatientNoLowerDigitsEnable {
                example += "\n　※下位N桁使用「5桁」の場合"
            }
            
            if state.isPatientNoRemoveLowerDigitsEnable {
                example += "\n　※下位X桁削除「1桁」の場合"
            }
            
            return example
        }
    }
    
    /// MIU連携プログラム設定画面
    private struct MIUProgramSettingView: View {
        let title: String
        @Binding var state: MIUProgramSettingState
        var onEditEnd: () -> Void
        var onCommTestRequest: () -> Void
        
        var body: some View {
            Form {
                Section {
                    StringSettingField(
                        valueAttr: MIUProgram.Setting.BASE_URL,
                        value: $state.baseUrlStr,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isBaseUrlStrOK,
                        onEditEnd: { onEditEnd() })
                    NumberSettingField(
                        valueAttr: MIUProgram.Setting.HTTP_RES_WAIT_SEC,
                        value: $state.httpResWaitSec,
                        formatter: NumberFormatter(),
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isHTTPResWaitSecOK,
                        onEditEnd: { onEditEnd() })
                } header: {
                    Text("通信設定")
                }
                Section {
                    HStack {
                        Button("MIU連携プログラム通信確認") {
                            onCommTestRequest()
                        }
                        .disabled(!state.isCommSettingOK) // 通信設定値入力が未完了の場合はボタンを無効にする
                        if (state.isCommTestExecuted) {
                            if (state.isCommTestOK) {
                                Text(state.commTestMessage)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(state.commTestMessage)
                                    .frame(alignment: .leading)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        } else if (state.isSettingOK) {
                            Text("MIU連携プログラム通信確認をクリックしてください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        } else {
                            Text("通信設定を入力後に通信確認を行なってください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        }
                    }
                } header: {
                    Text("通信設定確認")
                }
            }
            .navigationTitle(title)
        }
    }
    
    /// 自動つり銭機通信設定画面
    private struct AutoCashierSettingView: View {
        let title: String
        @Binding var selectedAutoCashierState: SelectedAutoCashierState
        @Binding var grolyR08SettingState: GrolyR08AutoCashierAdapterSettingState
        @Binding var groly300SettingState: Groly300AutoCashierAdapterSettingState
        var onEditEnd: () -> Void
        var onCommTestRequest: () -> Void
        
        private let decimalFormatter: NumberFormatter = {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.generatesDecimalNumbers = true
            return f
        }()
        
        var body: some View {
            Form {
                Section {
                    // つり銭機の選択
                    Picker(selection: $selectedAutoCashierState.selectedType, label: Text("機種選択"), content: {
                        ForEach(AppSetting.AutoCashierType.allCases, id:\.self) { value in
                            Text(value == .NoUse ? value.description : "\(value.description)を使う").tag(value)
                        }
                    })
                    .onChange(of: selectedAutoCashierState.selectedType) { newValue in
                        onEditEnd()
                    }
                }
                switch selectedAutoCashierState.selectedType {
                case .GrolyR08:
                    Section {
                        StringSettingField(
                            valueAttr: GrolyR08AutoCashierAdapter.Setting.IPADDR,
                            value: $grolyR08SettingState.ipAddr,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $grolyR08SettingState.isIPAddrOK,
                            onEditEnd: { onEditEnd() })
                        NumberSettingField(
                            valueAttr: GrolyR08AutoCashierAdapter.Setting.PORT,
                            value: $grolyR08SettingState.port,
                            formatter: NumberFormatter(),
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $grolyR08SettingState.isPortOK,
                            onEditEnd: { onEditEnd() })
                        NumberSettingField(
                            valueAttr: GrolyR08AutoCashierAdapter.Setting.COMM_TIMEOUT_SEC,
                            value: $grolyR08SettingState.commTimeoutSec,
                            formatter: NumberFormatter(),
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $grolyR08SettingState.isCommTimeoutSecOK,
                            onEditEnd: { onEditEnd() })
                    } header: {
                        Text("通信設定")
                    }
                    Section {
                        HStack {
                            Button("通信確認") {
                                onCommTestRequest()
                            }
                            .disabled(!grolyR08SettingState.isSettingOK) // 設定値入力が未完了の場合はボタンを無効にする
                            if (grolyR08SettingState.isCommTestExecuted) {
                                if (grolyR08SettingState.isCommTestOK) {
                                    Text(grolyR08SettingState.commTestMessage)
                                        .multilineTextAlignment(.leading)
                                } else {
                                    Text(grolyR08SettingState.commTestMessage)
                                        .frame(alignment: .leading)
                                        .foregroundColor(Color.red)
                                        .background(Color.yellow)
                                        .cornerRadius(5)
                                }
                            } else if (grolyR08SettingState.isSettingOK) {
                                Text("通信確認をクリックしてください。")
                                    .frame(alignment: .leading)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            } else {
                                Text("通信設定を入力後に通信確認を行なってください。")
                                    .frame(alignment: .leading)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        }
                    } header: {
                        Text("通信設定確認")
                    }
                case .Groly300:
                    Section {
                        StringSettingField(
                            valueAttr: Groly300AutoCashierAdapter.Setting.IPADDR,
                            value: $groly300SettingState.ipAddr,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $groly300SettingState.isIPAddrOK,
                            onEditEnd: { onEditEnd() })
                        NumberSettingField(
                            valueAttr: Groly300AutoCashierAdapter.Setting.PORT,
                            value: $groly300SettingState.port,
                            formatter: NumberFormatter(),
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $groly300SettingState.isPortOK,
                            onEditEnd: { onEditEnd() })
                        NumberSettingField(
                            valueAttr: Groly300AutoCashierAdapter.Setting.CONNECTION_TIMEOUT_SEC,
                            value: $groly300SettingState.connectionTimeoutSec,
                            formatter: NumberFormatter(),
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $groly300SettingState.isConnectionTimeoutOK,
                            onEditEnd: { onEditEnd() })
                    } header: {
                        Text("通信設定")
                    }
                    Section {
                        NumberSettingField(
                            valueAttr: Groly300AutoCashierAdapter.Setting.COMMAND_INTERVAL_SEC,
                            value: $groly300SettingState.commandIntervalSec,
                            formatter: decimalFormatter,    // 小数点フォーマット
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $groly300SettingState.isCommandIntervalSecOK,
                            onEditEnd: { onEditEnd() })
                    } header: {
                        Text("コマンド詳細設定")
                    }
                    // レスポンスサイズが小さいコマンドの設定
                    Section {
                        NumberSettingField(
                            valueAttr: Groly300AutoCashierAdapter.RespSizeSetting.SMALL_RESP_BASE_WAIT_SEC,
                            value: $groly300SettingState.smallRespBaseWaitSec,
                            formatter: decimalFormatter,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $groly300SettingState.isSmallRespBaseWaitSecOK,
                            onEditEnd: { onEditEnd() })
                        NumberSettingField(
                            valueAttr: Groly300AutoCashierAdapter.RespSizeSetting.SMALL_RESP_RETRY_COUNT,
                            value: $groly300SettingState.smallRespRetryCount,
                            formatter: NumberFormatter(),
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $groly300SettingState.isSmallRespRetryCountOK,
                            onEditEnd: { onEditEnd() })
                        NumberSettingField(
                            valueAttr: Groly300AutoCashierAdapter.RespSizeSetting.SMALL_RESP_INC_TIME_SEC,
                            value: $groly300SettingState.smallRespIncTimeSec,
                            formatter: decimalFormatter,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $groly300SettingState.isSmallRespIncTimeSecOK,
                            onEditEnd: { onEditEnd() })
                    } header: {
                        Text("レスポンスサイズが小さいコマンドの詳細設定")
                    }
                    // レスポンスサイズが大きいコマンドの設定
                    Section {
                        NumberSettingField(
                            valueAttr: Groly300AutoCashierAdapter.RespSizeSetting.LARGE_RESP_BASE_WAIT_SEC,
                            value: $groly300SettingState.largeRespBaseWaitSec,
                            formatter: decimalFormatter,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $groly300SettingState.isLargeRespBaseWaitSecOK,
                            onEditEnd: { onEditEnd() })
                        NumberSettingField(
                            valueAttr: Groly300AutoCashierAdapter.RespSizeSetting.LARGE_RESP_RETRY_COUNT,
                            value: $groly300SettingState.largeRespRetryCount,
                            formatter: NumberFormatter(),
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $groly300SettingState.isLargeRespRetryCountOK,
                            onEditEnd: { onEditEnd() })
                        NumberSettingField(
                            valueAttr: Groly300AutoCashierAdapter.RespSizeSetting.LARGE_RESP_INC_TIME_SEC,
                            value: $groly300SettingState.largeRespIncTimeSec,
                            formatter: decimalFormatter,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $groly300SettingState.isLargeRespIncTimeSecOK,
                            onEditEnd: { onEditEnd() })
                    } header: {
                        Text("レスポンスサイズが大きいコマンドの詳細設定")
                    }
                    Section {
                        HStack {
                            Button("通信確認") {
                                onCommTestRequest()
                            }
                            .disabled(!groly300SettingState.isSettingOK) // 設定値入力が未完了の場合はボタンを無効にする
                            if (groly300SettingState.isCommTestExecuted) {
                                if (groly300SettingState.isCommTestOK) {
                                    Text(groly300SettingState.commTestMessage)
                                        .multilineTextAlignment(.leading)
                                } else {
                                    Text(groly300SettingState.commTestMessage)
                                        .frame(alignment: .leading)
                                        .foregroundColor(Color.red)
                                        .background(Color.yellow)
                                        .cornerRadius(5)
                                }
                            } else if (groly300SettingState.isSettingOK) {
                                Text("通信確認をクリックしてください。")
                                    .frame(alignment: .leading)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            } else {
                                Text("通信設定とコマンド詳細設定を入力後に通信確認を行なってください。")
                                    .frame(alignment: .leading)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        }
                    } header: {
                        Text("通信設定確認")
                    }
                case .NoUse:
                    // 使用しない
                    EmptyView()
                }
            }
            .navigationTitle(title)
        }
    }
    
    /// クレジットカード支払い設定画面
    private struct CreditSettingView: View {
        let title: String
        @Binding var state: CregitSettingState
        @State private var isTryLogin = false
        @State private var isAlertActive = false
        @State private var alertMessage: String = ""
        var onEditEnd: () -> Void
        var onSTORESLoginOK: () -> Void
        var onSTORESLoginNG: (Error) -> Void
        var onSTORESLogoutOK: () -> Void
        
        var body: some View {
            if isTryLogin {
                STORESLoginViewControllerRepresent(
                    onComplete: {
                        isTryLogin = false
                        onSTORESLoginOK()
                    },
                    onCancel: {
                        isTryLogin = false
                    },
                    onError: { error in
                        isTryLogin = false
                        
                        if let sdkError = error as? STORESPaymentsSDKError {
                            switch sdkError {
                            case .applicationTokenUnauthorized:
                                // 認証失敗
                                if (!state.isSTORESLoginOK) {
                                    // 初回は必ず失敗するので、再試行。
                                    // 直ぐにログイン画面に遷移すると失敗するため、0.5秒待機してからログイン画面に遷移
                                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                                        isTryLogin = true
                                    }
                                }
                                return
                            case .userCancelled:
                                // キャンセルボタン押下時はアラートメッセージは表示しない
                                return
                            case .alreadyAuthenticated:
                                // 既にログイン済みの場合
                                onSTORESLoginOK()
                                return
                            default:
                                break
                            }
                        }
                        onSTORESLoginNG(error)
                    })
                .alert("STORESログイン結果", isPresented: $isAlertActive) {
                    Button("OK") {}
                } message: {
                    Text(alertMessage)
                }
            } else {
                Form {
                    Section {
                        HStack {
                            Text(STORES.Setting.STORES_USE_DEFAULT.label)
                                .frame(maxWidth: 250, alignment: .leading)
                            Toggle(isOn: $state.isStoresUse){}
                                .frame(alignment: .trailing)
                                .onChange(of: state.isStoresUse) { newValue in
                                    if !newValue {
                                        // STORE決済を使用しないに変更した場合はSTORESログアウトを行う
                                        STP.logout()
                                        onSTORESLogoutOK()
                                    }
                                    onEditEnd()
                                }
                        }
                        if state.isStoresUse {
                            HStack {
                                Button("STORESログイン") {
                                    isTryLogin = true
                                }
                                if (state.isSTORESLoginExecuted) {
                                    if (state.isSTORESLoginOK) {
                                        Text(state.storesLoginMessage)
                                            .multilineTextAlignment(.leading)
                                    } else {
                                        Text(state.storesLoginMessage)
                                            .frame(alignment: .leading)
                                            .foregroundColor(Color.red)
                                            .background(Color.yellow)
                                            .cornerRadius(5)
                                    }
                                } else {
                                    Text("STORESログインを行なってください。")
                                        .frame(alignment: .leading)
                                        .foregroundColor(Color.red)
                                        .background(Color.yellow)
                                        .cornerRadius(5)
                                }
                            }
                            HStack {
                                Button("STORESログアウト") {
                                    STP.logout()
                                    onSTORESLogoutOK()
                                }
                            }
                        }
                    } header: {
                        Text("STORE利用設定")
                    }
                }
                .navigationTitle(title)
            }
        }
    }
    
    /// STORESのログイン画面を表示するためのクラス
    /// 　→STORESPaymentSDKライブラリがUIKitで作成されているため、UIViewControllerRepresentableを使う
    struct STORESLoginViewControllerRepresent: UIViewControllerRepresentable {
        let onComplete: () -> Void
        let onCancel: () -> Void
        let onError: (Error) -> Void
        
        init(onComplete: @escaping () -> Void, onCancel: @escaping () -> Void, onError: @escaping (Error) -> Void) {
            self.onComplete = onComplete
            self.onCancel = onCancel
            self.onError = onError
        }
        
        func makeUIViewController(context: Context) -> UIViewController {
            return STORESLoginViewController(
                onComplete: onComplete,
                onCancel: onCancel,
                onError: onError)
        }
        
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            
        }
    }
    
    /// STORESのログイン画面を表示するためのクラス
    /// 　→STORESPaymentSDKライブラリが UIKitで作成されているため、ビューコントローラを扱う
    private class STORESLoginViewController: UIViewController {
        private let log = Logger(label: Bundle.main.bundleIdentifier!)
        
        let onComplete: () -> Void
        let onCancel: () -> Void
        let onError: (Error) -> Void
        
        private var isTryLogin = false
        
        init(onComplete: @escaping () -> Void, onCancel: @escaping () -> Void, onError: @escaping (Error) -> Void) {
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
                        var isErrorOccured = true
                        if let sdkError = error as? STORESPaymentsSDKError {
                            switch sdkError {
                            case .userCancelled:
                                // キャンセルボタン押下
                                self?.log.info("\(type(of: self)): STP.login cancel")
                                self?.onCancel()
                                return
                            case .alreadyAuthenticated:
                                // 既にログイン済み
                                self?.log.info("\(type(of: self)): STP.login already login")
                                isErrorOccured = false
                            default:
                                break
                            }
                        }
                        
                        if isErrorOccured {
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
                amount: 100,
                memo: "設定テスト") { transactionType in
                    // 決済完了（STORES Payments SDKの画面は表示中）
                    self.log.info("\(type(of: self)): Payment finished type = \(transactionType)")
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
                                // ログインに成功しているので既にログイン試行はOKな状態であるため、決済画面のキャンセルはエラーにしない
                                isErrorOccured = false
                                self?.log.info("\(type(of: self)): Payment Cancel")
                            default:
                                self?.log.error("\(type(of: self)): Payment Error = \(error)")
                                break
                            }
                        }
                        
                        if isErrorOccured {
                            self?.onError(error)
                        } else {
                            self?.onComplete()
                        }
                    }
                }
        }
    }
    
    /// スマレジ取引登録設定画面
    private struct SmaregiSettingView: View {
        let title: String
        @Binding var state: SmaregiPlatformSettingState
        var selectedBarcodeState: SelectedBarcodeState
        var onEditEnd: () -> Void
        var onCommTestRequest: () -> Void
        
        var body: some View {
            Form {
                Section {
                    StringSettingField(
                        valueAttr: SmaregiPlatformRepository.Setting.CONTRACT_ID,
                        value: $state.contractID,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isContractIDOK,
                        onEditEnd: { onEditEnd() })
                    StringSettingField(
                        valueAttr: SmaregiPlatformRepository.Setting.ACCESS_TOKEN_BASE_URL,
                        value: $state.accessTokenBaseUrlStr,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isAccessTokenBaseUrlStrOK,
                        onEditEnd: { onEditEnd() })
                    StringSettingField(
                        valueAttr: SmaregiPlatformRepository.Setting.CLIENT_ID,
                        value: $state.clientID,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isClientIDOK,
                        onEditEnd: { onEditEnd() })
                    // クライアントシークレットは画面に「*」で表示する
                    PasswordSettingField(
                        valueAttr: SmaregiPlatformRepository.Setting.CLIENT_SECRET,
                        value: $state.clientSecret,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isClientSecretOK,
                        onEditEnd: { onEditEnd() })
                    StringSettingField(
                        valueAttr: SmaregiPlatformRepository.Setting.PLATFORM_API_BASE_URL,
                        value: $state.platformAPIBaseUrlStr,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isPlatformAPIBaseUrlStrOK,
                        onEditEnd: { onEditEnd() })
                    StringSettingField(
                        valueAttr: SmaregiPlatformRepository.Setting.MAX_DAY_PER_REQUEST,
                        value: $state.maxDayPerRequestStr,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isMaxDayPerRequestStrOK,
                        onEditEnd: { onEditEnd() })
                } header: {
                    Text("通信設定")
                }
                Section {
                    HStack {
                        Button("スマレジ通信確認") {
                            onCommTestRequest()
                        }
                        .disabled(!state.isCommSettingOK) // 通信設定値入力が未完了の場合はボタンを無効にする
                        if (state.isCommTestExecuted) {
                            if (state.isCommTestOK) {
                                Text(state.commTestMessage)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(state.commTestMessage)
                                    .frame(alignment: .leading)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        } else if (state.isSettingOK) {
                            Text("スマレジ通信確認をクリックしてください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        } else {
                            Text("通信設定を入力後に通信確認を行なってください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        }
                    }
                } header: {
                    Text("通信設定確認")
                }
                Section {
                    if selectedBarcodeState.selectedType == .ReceiptBarcord {
                        // 領収書バーコードモード時のみ
                        StringSettingField(
                            valueAttr: SmaregiPlatformRepository.Setting.STORE_ID,
                            value: $state.storeIDStr,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $state.isStoreIDOK,
                            onEditEnd: { onEditEnd() })
                    }
                    StringSettingField(
                        valueAttr: SmaregiPlatformRepository.Setting.TERMINAL_ID,
                        value: $state.terminalIDStr,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isTerminalIDOK,
                        onEditEnd: { onEditEnd() })
                    if selectedBarcodeState.selectedType == .ReceiptBarcord {
                        // 領収書バーコードモード時のみ
                        StringSettingField(
                            valueAttr: SmaregiPlatformRepository.Setting.PRODUCT_ID,
                            value: $state.productIDStr,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $state.isProductIDOK,
                            onEditEnd: { onEditEnd() })
                    }
                } header: {
                    Text("取引登録設定")
                }
            }
            .navigationTitle(title)
        }
    }
    
    /// TSIクラウドスマレジForMedical取引履歴+α通信設定画面
    private struct TSISmaregiMedicalSettingView: View {
        let title: String
        @Binding var state: TSISmaregiMedicalSettingState
        var onEditEnd: () -> Void
        var onCommTestRequest: () -> Void
        
        var body: some View {
            Form {
                Section {
                    StringSettingField(
                        valueAttr: TSISmaregiMedicalRepository.Setting.CONTRACT_ID,
                        value: $state.contractID,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isContractIDOK,
                        onEditEnd: { onEditEnd() })
                    StringSettingField(
                        valueAttr: TSISmaregiMedicalRepository.Setting.BASE_URL,
                        value: $state.baseUrlStr,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isBaseUrlStrOK,
                        onEditEnd: { onEditEnd() })
                    StringSettingField(
                        valueAttr: TSISmaregiMedicalRepository.Setting.CLIENT_ID,
                        value: $state.clientID,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isClientIDOK,
                        onEditEnd: { onEditEnd() })
                    // クライアントシークレットは画面に「*」で表示する
                    PasswordSettingField(
                        valueAttr: TSISmaregiMedicalRepository.Setting.CLIENT_SECRET,
                        value: $state.clientSecret,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isClientSecretOK,
                        onEditEnd: { onEditEnd() })
                } header: {
                    Text("通信設定")
                }
                Section {
                    HStack {
                        Button("通信確認") {
                            onCommTestRequest()
                        }
                        .disabled(!state.isCommSettingOK) // 通信設定値入力が未完了の場合はボタンを無効にする
                        if (state.isCommTestExecuted) {
                            if (state.isCommTestOK) {
                                Text(state.commTestMessage)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(state.commTestMessage)
                                    .frame(alignment: .leading)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        } else if (state.isSettingOK) {
                            Text("通信確認をクリックしてください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        } else {
                            Text("通信設定を入力後に通信確認を行なってください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        }
                    }
                } header: {
                    Text("通信設定確認")
                }
            }
            // タイトルが長いため末尾が省略されるので、フォントサイズを小さくする
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text(title)
                            .font(.title)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            }
        }
    }
    
    /// レシートプリンタ通信設定
    private struct ReceiptPrinterSettingView: View {
        let title: String
        @Binding var state: ReceiptPrinterSettingState
        var onEditEnd: () -> Void
        var onCommTestRequest: () -> Void
        
        var body: some View {
            Form {
                Section {
                    EPosPrinterLoadSettingField(
                        valueAttr: EPosPrinter.Setting.BD_ADDRESS,
                        value: $state.bdAddress,
                        isValueOK: $state.isBDAddressOK,
                        onEditEnd: { onEditEnd() })
                } header: {
                    Text("Bluetooth通信設定")
                }
                Section {
                    HStack {
                        Button("通信確認") {
                            onCommTestRequest()
                        }
                        .disabled(!state.isCommSettingOK) // 通信設定値入力が未完了の場合はボタンを無効にする
                        if (state.isCommTestExecuted) {
                            if (state.isCommTestOK) {
                                Text(state.commTestMessage)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(state.commTestMessage)
                                    .frame(alignment: .leading)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        } else if (state.isSettingOK) {
                            Text("通信確認をクリックしてください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        } else {
                            Text("通信設定を入力後に通信確認を行なってください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        }
                    }
                } header: {
                    Text("通信設定確認")
                }
                Section {
                    NumberSettingField(
                        valueAttr: EPosPrinter.Setting.DPI,
                        value: $state.dpi,
                        formatter: NumberFormatter(),
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isDPIOK,
                        onEditEnd: { onEditEnd() })
                    NumberSettingField(
                        valueAttr: EPosPrinter.Setting.PRINT_WIDTH_MM,
                        value: $state.printWidthMM,
                        formatter: NumberFormatter(),
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isPrintWidthMMOK,
                        onEditEnd: { onEditEnd() })
                } header: {
                    Text("プリンタ設定値")
                }
            }
            // タイトルが長いため末尾が省略されるので、フォントサイズを小さくする
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text(title)
                            .font(.title)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            }
        }
    }
    
    /// ORCA通信画面
    private struct ORCASettingView: View {
        let title: String
        @Binding var state: ORCASettingState
        var onEditEnd: () -> Void
        var onCommTestRequest: () -> Void
        
        var body: some View {
            Form {
                Section {
                    Section {
                        // WebORCA と オンプレORCAの選択
                        // 　→オンプレORCAは、
                        // 　 　・URLのパス戦闘に「/apiが付かない」
                        // 　 　・Basic認証のAPIキーをパスワードと呼ぶ
                        // 　 　・クライアント証明書が不要
                        Picker(selection: $state.orcaEnvType, label: Text(ORCARepository.Setting.ORCA_ENV_TYPE.label), content: {
                            ForEach(ORCARepository.ORCAEnvType.allCases, id:\.self) { value in
                                Text("\(value.description)").tag(value)
                            }
                        })
                        .onChange(of: state.orcaEnvType) { newValue in
                            onEditEnd()
                        }
                    }
                } header: {
                    Text("稼働環境")
                }
                Section {
                    StringSettingField(
                        valueAttr: ORCARepository.Setting.BASE_URL,
                        value: $state.baseUrlStr,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isBaseUrlStrOK,
                        onEditEnd: { onEditEnd() },
                        errMsgMaxWidth: 80)
                    switch state.orcaEnvType {
                    case .Web:
                        // クライアント証明書はWebORCAの場合のみ必要
                        FileLoadSettingField(
                            valueAttr: ORCARepository.Setting.CLIENT_CERT_FILE,
                            value: $state.clientCertFile,
                            dialogTitle: title,
                            isValueOK: $state.isClientCertFileOK,
                            onEditEnd: { onEditEnd() })
                        // クライアント証明書のパスワードは画面に「*」で表示する
                        PasswordSettingField(
                            valueAttr: ORCARepository.Setting.CLIENT_CERT_PASSWORD,
                            value: $state.clientCertPassword,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $state.isClientCertPasswordOK,
                            onEditEnd: { onEditEnd() })
                    default:
                        EmptyView()
                    }
                    StringSettingField(
                        valueAttr: ORCARepository.Setting.CLIENT_ID,
                        value: $state.clientID,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isClientIDOK,
                        onEditEnd: { onEditEnd() })
                    switch state.orcaEnvType {
                    case .Web:
                        StringSettingField(
                            valueAttr: ORCARepository.Setting.API_KEY,
                            value: $state.apiKey,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $state.isApiKeyOK,
                            onEditEnd: { onEditEnd() })
                    case .OnPremises:
                        StringSettingField(
                            valueAttr: ORCARepository.Setting.CLIENT_PASSWORD,
                            value: $state.clientPassword,
                            keyboard: .asciiCapableNumberPad,
                            isValueOK: $state.isClientPasswordOK,
                            onEditEnd: { onEditEnd() })
                    }
                    StringSettingField(
                        valueAttr: ORCARepository.Setting.KARTE_UID,
                        value: $state.karteUid,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isKarteUidOK,
                        onEditEnd: { onEditEnd() },
                        readOnly: true)
                } header: {
                    Text("通信設定")
                }
                Section {
                    HStack {
                        Button("通信確認") {
                            onCommTestRequest()
                        }
                        .disabled(!state.isCommSettingOK) // 通信設定値入力が未完了の場合はボタンを無効にする
                        if (state.isCommTestExecuted) {
                            if (state.isCommTestOK) {
                                Text(state.commTestMessage)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(state.commTestMessage)
                                    .frame(alignment: .leading)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        } else if (state.isSettingOK) {
                            Text("通信確認をクリックしてください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        } else {
                            Text("通信設定を入力後に通信確認を行なってください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        }
                    }
                } header: {
                    Text("通信設定確認")
                }
                Section {
                    StringSettingField(
                        valueAttr: ORCARepository.Setting.SHUNO_CASH_ID,
                        value: $state.shunoCashID,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isShunoCashIDOK,
                        onEditEnd: { onEditEnd() })
                    StringSettingField(
                        valueAttr: ORCARepository.Setting.SHUNO_CREDIT_ID,
                        value: $state.shunoCreditID,
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isShunoCreditIDOK,
                        onEditEnd: { onEditEnd() })
                } header: {
                    Text("入金登録設定")
                }
            }
            // タイトルが長いため末尾が省略されるので、フォントサイズを小さくする
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text(title)
                            .font(.title)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            }
        }
    }
    
    /// ログ出力設定
    private struct LogSettingView: View {
        let title: String
        @Binding var state: LogSettingState
        var onEditEnd: () -> Void
        
        var body: some View {
            Form {
                Section {
                    // 保守のため、ログ出力はONから変更できないようにする
                    //                    HStack {
                    //                        Text(AnyLogger.Setting.OUTPUT_ENABLE.label)
                    //                            .frame(maxWidth: 250, alignment: .leading)
                    //                        Toggle(isOn: $state.isOutputEnable){}
                    //                            .frame(alignment: .trailing)
                    //                            .onChange(of: state.isOutputEnable) { newValue in
                    //                                onEditEnd()
                    //                            }
                    //                    }
                    Picker(selection: $state.logLevel, label: Text(AnyLogger.Setting.LOG_LEVEL.label), content: {
                        ForEach(Logger.Level.allCases, id:\.self) { value in
                            if value.number() < Logger.Level.warning.number() {
                                // trace / debug / info / notice / warning / error / critical のうち、
                                // warning / error / critical は必ず出力したいので選択肢から外す
                                Text("\(value.rawValue)").tag(value)
                            }
                        }
                    })
                    .onChange(of: state.logLevel) { newValue in
                        onEditEnd()
                    }
                    NumberSettingField(
                        valueAttr: FileLogger.Setting.ROTATION_COUNT,
                        value: $state.rotationCount,
                        formatter: NumberFormatter(),
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isRotationCountOK,
                        onEditEnd: { onEditEnd() })
                } header: {
                    Text("ログ出力設定")
                }
            }
            .navigationTitle(title)
        }
    }
    
    // カスタマーディスプレイ設定画面
    private struct CustomerDisplaySettingView: View {
        let title: String
        @Binding var state: CustomerDisplaySettingState
        var onEditEnd: () -> Void
        
        var body: some View {
            Form {
                Section {
                    // カスタマーディスプレイを使用するかどうか
                    HStack {
                        Text(CustomerDisplaySetting.ENABLE.label)
                            .frame(maxWidth: 300, alignment: .leading)
                        Toggle(isOn: $state.isEnable){}
                            .frame(alignment: .trailing)
                            .onChange(of: state.isEnable) { newValue in
                                onEditEnd()
                            }
                    }
                    // URL表示
                    if state.isEnable {
                        // カスタマーディスプレイが有効な場合
                        if state.url != "" {
                            Text(state.url)
                                .foregroundColor(.gray)
                        } else {
                            Text(state.urlErrMsg)
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        }
                    }
                } header: {
                    Text("使用設定")
                }
            }
            .navigationTitle(title)
        }
    }
    
    // HTTPサーバ設定画面
    private struct HTTPServerSettingView: View {
        let title: String
        @Binding var state: HTTPServerSettingState
        var onEditEnd: () -> Void
        var onCommTestRequest: () -> Void
        
        // WiFiのIPアドレスを取得する
        // 　→WiFi設定変更のトリガーを拾うために、IPアドレスはここで取得する
        @State var ipAddr: String = ""
        
        var body: some View {
            Form {
                Section {
                    // IPアドレス
                    HStack {
                        Text("IPアドレス（自動入力）")
                            .frame(alignment: .leading)
                        Spacer()
                        Text(state.wifiIPAddr)
                        .frame(alignment: .trailing)
                        .foregroundColor(.gray)
                    }
                    // ポート番号
                    NumberSettingField(
                        valueAttr: HTTPServer.Setting.LISTEN_PORT,
                        value: $state.listenPort,
                        formatter: NumberFormatter(),
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isListenPortOK,
                        onEditEnd: {
                            onEditEnd()
                        })
                    if state.listenErrMsg != "" {
                        Text(state.listenErrMsg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.red)
                            .background(Color.yellow)
                            .cornerRadius(5)
                    }
                } header: {
                    Text("待ち受け設定")
                }
                Section {
                    HStack {
                        Button("HTTPサーバ通信確認") {
                            onCommTestRequest()
                        }
                        .disabled(!state.isCommSettingOK) // 通信設定値入力が未完了の場合はボタンを無効にする
                        if (state.isCommTestExecuted) {
                            if (state.isCommTestOK) {
                                Text(state.commTestMessage)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(state.commTestMessage)
                                    .frame(alignment: .leading)
                                    .foregroundColor(Color.red)
                                    .background(Color.yellow)
                                    .cornerRadius(5)
                            }
                        } else if (state.isSettingOK) {
                            Text("HTTPサーバ通信確認をクリックしてください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        } else {
                            Text("HTTPサーバ設定を入力後に通信確認を行なってください。")
                                .frame(alignment: .leading)
                                .foregroundColor(Color.red)
                                .background(Color.yellow)
                                .cornerRadius(5)
                        }
                    }
                } header: {
                    Text("通信設定確認")
                }
            }
            .navigationTitle(title)
        }
    }
    
    // 画面設定画面
    private struct ViewSettingView: View {
        let title: String
        @Binding var state: ViewSettingState
        /// バーコード設定状態を参照する
        let selectedBarcodeState: SelectedBarcodeState
        var onEditEnd: () -> Void
        
        var body: some View {
            Form {
                Section {
                    HStack {
                        VStack {
                            HStack {
                                Text(ViewSetting.STANBY_BGIMAGE.label)
                                    .padding(.bottom, 10)
                                Spacer()
                            }
                            HStack {
                                Text("※画像を変更する場合は、\(ViewSetting.BGIMAGE_STANBY_DIR_NAME)ディレクトリ直下に画像ファイルを１つだけ配置してください（ファイル名は任意）")
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                        .frame(maxWidth: 250)
                        Spacer()
                        VStack {
                            // 背景画像を表示
                            let (bgImage, isDefault) = state.tryLoadStanbyBGImage(barcordType: selectedBarcodeState.selectedType)
                            if isDefault {
                                Text("標準画像を使用します")
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(.gray)
                            } else {
                                Text("配置された画像ファイルを使用します")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(.gray)
                            }
                            HStack {
                                // Spacerで右寄せにする
                                Spacer()
                                Image(uiImage: bgImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit) // アスペクト比を保ったままリサイズ
                                    .frame(maxWidth: 200)
                                    .onAppear {
                                        onEditEnd()
                                    }
                            }
                        }
                    }
                } header: {
                    Text("精算待機画面設定")
                }
                Section {
                    // 精算完了メッセージ表示時間[秒]
                    NumberSettingField(
                        valueAttr: ViewSetting.SEISAN_COMPLETE_VIEW_MESSAGE_DISPLAY_TIME_SEC,
                        value: $state.seisanCompleteViewMessageDisplayTimeSec,
                        formatter: NumberFormatter(),
                        keyboard: .asciiCapableNumberPad,
                        isValueOK: $state.isSeisanCompleteViewMessageDisplayTimeSecOK,
                        onEditEnd: { onEditEnd() })
                    // 精算完了時のメッセージ（おつりがない場合）
                    MultiLineStringSettingField(
                        valueAttr: ViewSetting.SEISAN_COMPLETE_VIEW_MESSAGE_NO_CHANGE,
                        value: $state.seisanCompleteViewMessageNoChange,
                        keyboard: .default,
                        isValueOK: $state.isSeisanCompleteViewMessageNoChangeOK,
                        onEditEnd: { onEditEnd() })
                    // 精算完了時のメッセージ（おつりがある場合）
                    MultiLineStringSettingField(
                        valueAttr: ViewSetting.SEISAN_COMPLETE_VIEW_MESSAGE_WITH_CHANGE,
                        value: $state.seisanCompleteViewMessageWithChange,
                        keyboard: .default,
                        isValueOK: $state.isSeisanCompleteViewMessageWithChangeOK,
                        onEditEnd: { onEditEnd() })
                    // 精算完了時の処方箋引換券受け取り案内メッセージ（処方箋引換券を印刷した場合）
                    MultiLineStringSettingField(
                        valueAttr: ViewSetting.SEISAN_COMPLETE_VIEW_SHOHOSEN_HIKIKAKEN_MESSAGE,
                        value: $state.seisanCompleteViewShohosenHikikaekenMessage,
                        keyboard: .default,
                        isValueOK: $state.isSeisanCompleteViewShohosenHikikaekenMessageOK,
                        onEditEnd: { onEditEnd() })
                } header: {
                    Text("精算完了画面設定")
                }
            }
            .navigationTitle(title)
        }
    }
    
    // 設定カテゴリタイトルビュー
    private struct SettingCategoryTitle: View {
        let title: String
        let summary: String
        @Binding var isCompleted: Bool
        var isHStack: Bool = true
        
        var body: some View {
            if isCompleted {
                if isHStack {
                    // サマリをタイトルの右横に表示
                    HStack {
                        Text(title)
                        Spacer()
                        Text(summary)
                            .foregroundColor(Color.gray)
                            .font(.subheadline)
                            .frame(alignment: .leading)
                    }
                } else {
                    // サマリをタイトルの下に表示
                    VStack(alignment: .leading) {
                        Text(title)
                        Text(summary)
                            .foregroundColor(Color.gray)
                            .font(.subheadline)
                            .frame(alignment: .leading)
                    }
                }
            } else {
                // エラーマークをタイトルの右横に右寄せで表示
                HStack {
                    Text(title)
                    Spacer()
                    Text("!")
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color.white)
                        .background(
                            Capsule()
                                .fill(Color.red)
                                .frame(minWidth: 25))
                }
            }
        }
    }
    
    // 数値設定フィールド
    // 　→設定入力ビューの共通化
    private struct NumberSettingField<S,T>: View {
        let valueAttr: SettingValueAttr<S>
        @Binding var value: T
        let formatter: Formatter
        let keyboard: UIKeyboardType
        @Binding var isValueOK: Bool
        let onEditEnd: () -> Void
        var labelMaxWidth: CGFloat = 250
        
        var body: some View {
            HStack {
                Text(valueAttr.label)
                    .frame(maxWidth: labelMaxWidth, alignment: .leading)
                if (!isValueOK) {
                    Text(valueAttr.errorMessage)
                        .frame(alignment: .leading)
                        .foregroundColor(Color.red)
                        .background(Color.yellow)
                        .cornerRadius(5)
                }
                TextField(valueAttr.placeHolder,
                          value: $value,
                          formatter: formatter,
                          onEditingChanged: { editing in
                    if !editing {
                        onEditEnd()
                    }
                })
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)
                .foregroundColor(isValueOK ? Color.black : Color.red)
            }
        }
    }
    
    // 文字列設定フィールド
    // 　→設定入力ビューの共通化
    private struct StringSettingField<T>: View {
        let valueAttr: SettingValueAttr<T>
        var titlePrefix: String = ""
        @Binding var value: String
        let keyboard: UIKeyboardType
        @Binding var isValueOK: Bool
        let onEditEnd: () -> Void
        var readOnly = false
        var labelMaxWidth: CGFloat = 250
        var errMsgMaxWidth: CGFloat?
        
        var body: some View {
            HStack {
                Text(titlePrefix + valueAttr.label)
                    .frame(maxWidth: labelMaxWidth, alignment: .leading)
                if (!isValueOK) {
                    Text(valueAttr.errorMessage)
                        .frame(maxWidth: errMsgMaxWidth ?? .infinity, alignment: .leading)
                        .foregroundColor(Color.red)
                        .background(Color.yellow)
                        .cornerRadius(5)
                }
                TextField(valueAttr.placeHolder,
                          text: $value,
                          onEditingChanged: { editing in
                    if !editing {
                        onEditEnd()
                    }
                })
                .disabled(readOnly)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)
                .foregroundColor(isValueOK ? Color.black : Color.red)
            }
        }
    }
    
    // 複数行文字列設定フィールド
    private struct MultiLineStringSettingField<T>: View {
        let valueAttr: SettingValueAttr<T>
        @Binding var value: String
        let keyboard: UIKeyboardType
        @Binding var isValueOK: Bool
        let onEditEnd: () -> Void
        
        var body: some View {
            HStack {
                Text(valueAttr.label)
                    .frame(maxWidth: 250, alignment: .leading)
                if (!isValueOK) {
                    Text(valueAttr.errorMessage)
                        .frame(alignment: .leading)
                        .foregroundColor(Color.red)
                        .background(Color.yellow)
                        .cornerRadius(5)
                }
                ZStack {
                    if value.isEmpty {
                        // プレースホルダ表示
                        Text(valueAttr.placeHolder)
                            .foregroundColor(Color(UIColor.lightGray))
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    TextEditor(text: $value)
                        .keyboardType(keyboard)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(isValueOK ? Color.black : Color.red)
                        .onChange(of: value) { newValue in
                            // TextEditorはTextFieldのように変更検出（onEditingChanged）できないので、
                            // onChangeで変更検出する
                            onEditEnd()
                        }
                }
            }
        }
    }
    
    // パスワード設定フィールド
    // 　→設定入力ビューの共通化
    private struct PasswordSettingField<T>: View {
        let valueAttr: SettingValueAttr<T>
        @Binding var value: String
        let keyboard: UIKeyboardType
        @Binding var isValueOK: Bool
        let onEditEnd: () -> Void
        
        var body: some View {
            HStack {
                Text(valueAttr.label)
                    .frame(maxWidth: 250, alignment: .leading)
                if (!isValueOK) {
                    Text(valueAttr.errorMessage)
                        .frame(alignment: .leading)
                        .foregroundColor(Color.red)
                        .background(Color.yellow)
                        .cornerRadius(5)
                }
                SecureField(valueAttr.placeHolder,
                            text: $value,
                            onCommit: { onEditEnd() })
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)
                .foregroundColor(isValueOK ? Color.black : Color.red)
            }
        }
    }
    
    // ファイル読み込み設定フィールド
    private struct FileLoadSettingField<T: FileSetting>: View {
        let valueAttr: SettingValueAttr<T>
        @Binding var value: FileSetting
        let dialogTitle: String
        @Binding var isValueOK: Bool
        let onEditEnd: () -> Void
        
        @State private var isFileSelctViewShow = false
        
        var body: some View {
            HStack {
                Text(valueAttr.label)
                    .frame(maxWidth: 250, alignment: .leading)
                if (!isValueOK) {
                    Text(valueAttr.errorMessage)
                        .frame(alignment: .leading)
                        .foregroundColor(Color.red)
                        .background(Color.yellow)
                        .cornerRadius(5)
                }
                HStack {
                    Spacer()
                    Text(value.name)
                        .frame(alignment: .trailing)
                    Spacer()
                    Button {
                        isFileSelctViewShow.toggle()
                    } label: {
                        HStack {
                            Text("設定")
                                .foregroundColor(.gray)
                                .frame(alignment: .trailing)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .opacity(0.5)
                        }
                    }
                }
            }
            // 元々sheetモディファイア実装にしていたが、FileSelectViewのイニシャライザに本構造体のプロパティを渡すと、
            // FileSelectViewの描画が何度も実行されるため、それを抑止するため、
            // fullScreenCoverモディファイア実装に変更
            .fullScreenCover(isPresented: $isFileSelctViewShow) {
                NavigationStack {
                    FileSelectView(title: dialogTitle,
                                   description: "クライアント証明書ファイルを選択してください。",
                                   dirUrl: ORCASettingState.getClientCertDirUrl(),
                                   selectedFile: $value)
                }
                .presentationDetents([.height(100)])
            }
            .onChange(of: value) { newValue in
                onEditEnd()
            }
        }
    }
    
    /// ファイル選択ビュー
    struct FileSelectView : View {
        private let log = Logger(label: Bundle.main.bundleIdentifier!)
        
        @Environment(\.presentationMode) var presentationMode
        
        let title: String
        let description: String
        let dirUrl: URL
        @Binding var selectedFile: FileSetting
        
        @State private var isFileLoading = true
        
        private struct File: Identifiable, Hashable {
            var id = UUID()
            var url: URL
            var name: String
        }
        @State private var files: [File] = []
        
        @State private var errAlertMsg = ""
        @State private var isErrAlertActive = false
        
        var body: some View {
            Form {
                Section {
                    if isFileLoading {
                        EmptyView()
                    } else if files.count == 0 {
                        Text("ファイルが見つかりません。\nドキュメントディレクトリ > Certディレクトリ 直下にクライアント証明書ファイルを配置してください。")
                            .font(.title2)
                            .frame(alignment: .leading)
                            .foregroundColor(Color.red)
                            .background(Color.yellow)
                            .cornerRadius(5)
                    } else {
                        List(files, id: \.self) { file in
                            Button(action: {
                                do {
                                    let data = try Data(contentsOf: file.url)
                                    selectedFile = FileSetting(name: file.name, data: data)
                                } catch {
                                    errAlertMsg = "証明書ファイルの読み込みに失敗しました。: \(error)"
                                    isErrAlertActive = true
                                    return
                                }
                                
                                closeView()
                            }) {
                                HStack {
                                    Text(file.name)
                                        .foregroundColor(.black)
                                    if file.name == selectedFile.name {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(description)
                        if isFileLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.leading)
                            Spacer()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.title2)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Spacer()
                    Button("閉じる", role: .cancel) {
                        closeView()
                    }
                }
            }
            // ナビゲーションタイトルを非表示にする
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                DispatchQueue.main.async {
                    defer {
                        isFileLoading = false
                    }
                    
                    do {
                        let fileURLs = try FileManager.default.contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: nil)
                        files = fileURLs.map { File(url: $0, name: $0.lastPathComponent) }
                    } catch {
                        errAlertMsg = "証明書ファイルの読み込みに失敗しました。: \(error)"
                        isErrAlertActive = true
                    }
                }
            }
            .alert("エラーが発生しました。", isPresented: $isErrAlertActive) {
                Button("OK") {
                    closeView()
                }
                .onAppear() {
                    log.error("\(type(of: self)): file select view error: \(errAlertMsg)")
                }
            } message: {
                Text(errAlertMsg)
            }
        }
        
        func closeView() {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// ePos接続プリンタ設定フィールド
    private struct EPosPrinterLoadSettingField<T>: View {
        let valueAttr: SettingValueAttr<T>
        @Binding var value: String
        @Binding var isValueOK: Bool
        let onEditEnd: () -> Void
        
        @State private var isSelectViewShow = false
        
        var body: some View {
            HStack {
                Text(valueAttr.label)
                    .frame(maxWidth: 250, alignment: .leading)
                if (!isValueOK) {
                    Text(valueAttr.errorMessage)
                        .frame(alignment: .leading)
                        .foregroundColor(Color.red)
                        .background(Color.yellow)
                        .cornerRadius(5)
                }
                HStack {
                    Spacer()
                    Text(value)
                        .frame(alignment: .trailing)
                    Spacer()
                    Button {
                        isSelectViewShow.toggle()
                    } label: {
                        HStack {
                            Text("設定")
                                .foregroundColor(.gray)
                                .frame(alignment: .trailing)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .opacity(0.5)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $isSelectViewShow) {
                NavigationStack {
                    EPosPrinterSelectView(selectedValue: $value)
                }
                .presentationDetents([.height(100)])
            }
            .onChange(of: value) { newValue in
                onEditEnd()
            }
        }
    }
    
    /// ePos接続プリンタ選択ビュー
    struct EPosPrinterSelectView : View {
        private let log = Logger(label: Bundle.main.bundleIdentifier!)
        
        @Environment(\.presentationMode) var presentationMode
        
        let title = "プリンタ選択"
        let description = "プリンタを選択してください。"
        @Binding var selectedValue: String
        
        @State private var isLoading = true
        
        @State private var deviceInfos: [Epos2DeviceInfo] = []
        @State private var discovery: EPosPrinter.Descovery?
        @State private var errAlertMsg = ""
        @State private var isErrAlertActive = false
        
        var body: some View {
            Form {
                Section {
                    if isLoading {
                        EmptyView()
                    } else {
                        List(deviceInfos, id: \.self) { deviceInfo in
                            Button(action: {
                                selectedValue = deviceInfo.target
                                closeView()
                            }) {
                                HStack {
                                    VStack {
                                        Text("\(deviceInfo.deviceName)")
                                            .foregroundColor(.black)
                                            .font(.title2)
                                            .frame(alignment: .leading)
                                        Text("    \(deviceInfo.target)")
                                            .foregroundColor(.gray)
                                            .font(.title3)
                                    }
                                    if deviceInfo.target == selectedValue {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(description)
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.leading)
                            Spacer()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.title2)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Spacer()
                    Button("閉じる", role: .cancel) {
                        closeView()
                    }
                }
            }
            // ナビゲーションタイトルを非表示にする
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if discovery == nil {
                    discovery = EPosPrinter.Descovery(portType: EPOS2_PORTTYPE_BLUETOOTH,
                                                      discoveryCallback: { deviceInfo in discoveryCallback(deviceInfo) })
                    discovery!.start()
                }
            }
            .alert("エラーが発生しました。", isPresented: $isErrAlertActive) {
                Button("OK") {
                    closeView()
                }
                .onAppear() {
                    log.error("\(type(of: self)): epos printer select view error: \(errAlertMsg)")
                }
            } message: {
                Text(errAlertMsg)
            }
        }
        
        func discoveryCallback(_ deviceInfo: Epos2DeviceInfo) {
            DispatchQueue.main.async {
                for di in deviceInfos {
                    if di == deviceInfo {
                        // 既に追加されているデバイスは追加しない
                        return
                    }
                }
                
                deviceInfos.append(deviceInfo)
                
                for deviceInfo in deviceInfos {
                    log.info("\(type(of: self)): discover printer. target=\(String(describing: deviceInfo.target)), deviceName=\(String(describing: deviceInfo.deviceName)), macAddress=\(String(describing: deviceInfo.macAddress)), ipAddress=\(String(describing: deviceInfo.ipAddress)), leBdAddress=\(String(describing: deviceInfo.leBdAddress))")
                }
                
                isLoading = false
            }
        }
        
        func closeView() {
            discovery?.stop()
            discovery = nil
            
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
