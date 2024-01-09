//
//  StanbyPatientCardView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/07/18.
//

import SwiftUI
import AudioToolbox
import Logging

/// 診察券バーコード用待機画面
/// ・ビジコムのバーコードリーダは外部キーボードとして認識されるため、TextFieldを使ってバーコード文字列を受け取る方法もあるが、
/// 　TextFeildを使うとiPadの画面に最小化状態のソフトウェアキーボードが表示されてしまう。
/// 　そのため、一時的にキー入力をフックできるUIViewControllerに遷移し、バーコードリーダからの入力を受け取る。
struct StanbyPatientCardView: View, PatientCardBarcodeInputProtorol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettingState: AppSettingState
    @StateObject var viewModel = StanbyPatientCardViewModel()
    
    var body: some View {
        //背景色を設定するためのZStack
        ZStack {
            // 背景画像
            Image("Images/haikei_1_2_6")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all) // 上下の余白まで背景色を統一
            if viewModel.isAppSettingOK {
                StanbyViewControllerRepresent(viewModel: viewModel, barcodeInput: self)
            } else {
                Text("右上のボタンを押して設定を完了させてください。")
                    .font(.title)
                    .padding()
            }
        }
        .onAppear {
            log.trace("\(type(of: self)): appear")
            appState.noticeCurrScreen(.stanby)
            
            viewModel.reloadAppSetting()
            log.info("\(type(of: self)): isAppSettingOK=\(viewModel.isAppSettingOK)")
        }
        .navigationBarBackButtonHidden(true) // ナビゲーションバーの戻るボタン非表示 & スワイプで戻る操作無効
        .navigationBarItems(
            //ナビゲーションバーの右端に設定ボタンを配置
            trailing: NavigationLink(
                destination: SettingView()){
                    HStack {
                        if !viewModel.isAppSettingOK {
                            Text("!")
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.white)
                                .background(Capsule()
                                    .fill(Color.red)
                                    .frame(minWidth: 30))
                            Spacer(minLength: 20)
                        }
                        Text("設定")
                            .foregroundColor(Color.black)
                    }
                })
    }
    
    /// バーコード入力フック付きビューコントローラからのキー入力（バーコード入力プロトコル実装）
    /// - Parameter input: 入力文字（1文字）
    func inputBarcode(input: String) {
        if input == "\r" {
            // 改行をバーコード文字列の終端とみなす
            // ・ビジコムのバーコードリーダはバーコード文字列の終端に改行コードを入力する
            let barcode = viewModel.barcodeBuf
            viewModel.barcodeBuf = ""
            log.info("\(type(of: self)): input barcord. value=\(barcode)")
            
            // バーコード入力
            viewModel.inputBarcode(barcode)
            return
        }
        viewModel.barcodeBuf += input
    }
}

/// バーコード入力を通知するプロトコル
protocol PatientCardBarcodeInputProtorol {
    /// キー入力
    /// - Parameter input: 入力文字（1文字）
    func inputBarcode(input: String)
}

extension StanbyPatientCardView {
    /// バーコード入力フック付き待機画面ビューコントローラを生成するために、UIViewControllerRepresentableを使用
    struct StanbyViewControllerRepresent: UIViewControllerRepresentable {
        var viewModel: StanbyPatientCardViewModel
        var barcodeInput: PatientCardBarcodeInputProtorol
        
        func makeUIViewController(context: Context) -> UIViewController {
            return StanbyBarcodeInputViewController(viewModel: viewModel, barcodeInput: barcodeInput)
        }
        
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            
        }
    }
    
    /// バーコード入力フック付き待機画面ビューコントローラ
    /// ・本クラスでビューコントローラでバーコードリーダからのキー入力をフックする
    class StanbyBarcodeInputViewController: UIHostingController<StanbyKeyHookView> {
        private let log = Logger(label: Bundle.main.bundleIdentifier!)
        
        /// アプリ設定取得サービス
        private let appSetGetSvc: AppSettingGetService = AppSettingGetService.shared
        
        @ObservedObject var viewModel: StanbyPatientCardViewModel
        private var barcodeInput: PatientCardBarcodeInputProtorol
        
        init(viewModel: StanbyPatientCardViewModel, barcodeInput: PatientCardBarcodeInputProtorol) {
            self.viewModel = viewModel
            self.barcodeInput = barcodeInput
            super.init(rootView: StanbyKeyHookView(viewModel: viewModel))
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init?(coder aDecoder: NSCoder) no implemented")
        }
        
        override func becomeFirstResponder() -> Bool {
            true
        }
        
        override var keyCommands: [UIKeyCommand]? {
            if !viewModel.isAppSettingOK {
                return []
            }
            
            let setting = self.appSetGetSvc.getMustAppSetting().patientCardSeisanSetting!
            
            if setting.isPatientNoDecimalOnlyEnable {
                // 数値のみ使用する設定が有効な場合
                // 　→既存環境との互換性を考慮し残しておく
                log.info("input barcode decimal only")
                return [
                    UIKeyCommand(input: "1", modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: "2", modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: "3", modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: "4", modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: "5", modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: "6", modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: "7", modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: "8", modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: "9", modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: "0", modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: "\r" ,modifierFlags: [], action: #selector(inputKey)),
                    UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(inputKey))
                ]
            } else {
                // 数値のみ使用する設定が無効な場合
                log.info("input barcode decimal only")
                
                var commands: [UIKeyCommand] = []
                
                // アスキーコードのうち、表示文字列を追加
                // 　→ アルファベットの大文字（A〜Z）はmodifierFlagsに「.shift」を指定する必要があるため、後で登録する
                for asciiCodes in [32...64, 91...126] {
                    for asciiCode in asciiCodes {
                        if let char = UnicodeScalar(asciiCode) {
                            commands.append(UIKeyCommand(input: String(char), modifierFlags: [], action: #selector(inputKey)))
                        }
                    }
                }
                
                // アルファベットの大文字（A〜Z）は、modifierFlagsに「.shift」を指定する必要がある
                // 　→UIKeyCommandの仕様である模様
                for asciiCode in 65...90 {
                    if let char = UnicodeScalar(asciiCode) {
                        commands.append(UIKeyCommand(input: String(char), modifierFlags: [.shift], action: #selector(inputKey)))
                    }
                }
                
                // 改行（CR）を追加
                commands.append(UIKeyCommand(input: "\r" ,modifierFlags: [], action: #selector(inputKey)))
                
                // 不要の可能性もあるが、開発初期から実装しており、影響範囲が読み切れないためそのまま残す
                commands.append(UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(inputKey)))
                
                return commands
            }
        }
        
        @objc func inputKey(_ sender: UIKeyCommand) {
            let input = sender.input ?? ""
            barcodeInput.inputBarcode(input: input)
        }
    }
    
    /// バーコード入力フック付き待機画面
    struct StanbyKeyHookView: View {
        private let log = Logger(label: Bundle.main.bundleIdentifier!)
        
        /// シーンフェーズ
        /// 　→iPadホーム画面や他のアプリから本アプリに戻ってきたことを検出するための仕組み（SwiftUIの機能）
        @Environment(\.scenePhase) private var scenePhase
        
        @EnvironmentObject var appSettingSvc: AppSettingGetService
        
        @ObservedObject var viewModel: StanbyPatientCardViewModel
        
        /// 返金ダイアログ表示を制御するフラグ
        /// 　→アーキテクチャとしてはviewModelに移すべきプロパティ。誤ってビュー側に定義したもの。
        /// 　→以下、@Stateについては同様
        @State private var isRefundAlertActive = false
        /// 返金ダイアログ表示中に定期的にサウンドを鳴らすためのタイマー
        @State private var refundSoundTimer: Timer?
        /// エラー表示ダイアログ表示を制御するフラグ
        @State private var isErrAlertActive = false
        /// エラー表示ダイアログに表示するエラーメッセージ
        @State private var errAlertMsg = ""
        /// エラー表示ダイアログ表示中に定期的にサウンドを鳴らすためのタイマー
        @State private var errorSoundTimer: Timer?
        
        init(viewModel: StanbyPatientCardViewModel) {
            self.viewModel = viewModel
            
            // 画面遷移時のアニメーションを無効化
            UIView.setAnimationsEnabled(false)
        }
        
        var body: some View {
            // 背景を設定するためのZStack
            ZStack {
                Image(uiImage: viewModel.bgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all) // 上下の余白まで背景色を統一
//                //開発用コード：ボタン遷移
//                VStack {
//                    Button {
//                        viewModel.inputBarcode("00002")
//                    } label: {
//                        Text("00002")
//                            .font(Font.system(size: 48).bold())
//                            .frame(width: 300, height: 65.0)
//                            .background(Color.white)
//                    }
//                    Button {
//                        viewModel.inputBarcode("00007")
//                    } label: {
//                        Text("00007")
//                            .font(Font.system(size: 48).bold())
//                            .frame(width: 300, height: 65.0)
//                            .background(Color.white)
//                    }
//                }
                .onChange(of: viewModel.viewStatus, perform: { newValue in
                    var isRAActive = false
                    var isEAActive = false
                    
                    switch newValue {
                    case .refund:
                        // 返金案内中
                        isRAActive = true
                        
                        // まずは即時に警告音を鳴らし、その後は一定間隔で警告音を鳴らす
                        AudioServicesPlaySystemSound(SystemSoundID(1005))
                        refundSoundTimer = Timer.scheduledTimer(
                            withTimeInterval: 10,
                            repeats: true,
                            block: { timer in
                                AudioServicesPlaySystemSound(SystemSoundID(1005))
                            })
                    case .error(let message):
                        // エラー中
                        errAlertMsg = message
                        isEAActive = true
                        
                        // まずは即時に警告音を鳴らし、その後は一定間隔で警告音を鳴らす
                        AudioServicesPlaySystemSound(SystemSoundID(1005))
                        errorSoundTimer = Timer.scheduledTimer(
                            withTimeInterval: 10,
                            repeats: true,
                            block: { timer in
                                AudioServicesPlaySystemSound(SystemSoundID(1005))
                            })
                    default:
                        break
                    }
                    
                    isRefundAlertActive = isRAActive
                    isErrAlertActive = isEAActive
                })
                .onChange(of: scenePhase) { newValue in
                    if newValue == .active {
                        // iPadホーム画面や他のアプリから本アプリに戻ってきた場合
                        viewModel.onActive()
                    }
                }
                .alert("返金の手続きが必要となります。窓口へお越し下さい。", isPresented: $isRefundAlertActive) {
                    Button("OK") {
                        refundSoundTimer?.invalidate()
                        refundSoundTimer = nil
                        
                        viewModel.refundOK()
                    }
                    .onAppear() {
                        log.error("\(type(of: self)): display refund")
                    }
                } message: {
                }
                .alert("エラーが発生しました。\n係員にお知らせください。", isPresented: $isErrAlertActive) {
                    Button("OK") {
                        errorSoundTimer?.invalidate()
                        errorSoundTimer = nil
                        
                        viewModel.errorOK()
                    }
                    .onAppear() {
                        log.error("\(type(of: self)): display error: \(errAlertMsg)")
                    }
                } message: {
                    Text(errAlertMsg)
                }
                if viewModel.isIndicatorActive {
                    // インジケーター表示
                    ActivityIndicator()
                }
            }
            .onAppear {
                log.trace("\(type(of: self)): appear")
                viewModel.onApear()
            }
        }
        
        struct ContentView_Previews: PreviewProvider {
            static var previews: some View {
                StanbyPatientCardView()
            }
        }
    }
}
