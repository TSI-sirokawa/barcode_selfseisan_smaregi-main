//
//  StanbyView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/07/18.
//

import SwiftUI
import AudioToolbox
import Logging

/// 領収書バーコード用待機画面
/// ・ビジコムのバーコードリーダは外部キーボードとして認識されるため、TextFieldを使ってバーコード文字列を受け取る方法もあるが、
/// 　TextFeildを使うとiPadの画面に最小化状態のソフトウェアキーボードが表示されてしまう。
/// 　そのため、一時的にキー入力をフックできるUIViewControllerに遷移し、バーコードリーダからの入力を受け取る。
struct StanbyView: View, BarcodeInputProtorol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel = StanbyViewModel()
    
    var body: some View {
        ZStack {
            Image("Images/haikei_1_2_6")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all) // 上下の余白まで背景色を統一
            if viewModel.isAppSettingOK {
                StanbyViewControllerRepresent(viewModel: viewModel, barcodeInput: self)
            } else {
                Text("右上のボタンを押して設定を完了させてください。")
                    .font(.appTextUI(size: 32))
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
                            .font(.appTextUI(size: 16))
                            .foregroundColor(.black)
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
            if !viewModel.inputBarcode(barcode) {
                return
            }
            return
        }
        viewModel.barcodeBuf += input
    }
}

/// バーコード入力フック付き待機画面ビューコントローラを生成するために、UIViewControllerRepresentableを使用
struct StanbyViewControllerRepresent: UIViewControllerRepresentable {
    var viewModel: StanbyViewModel
    var barcodeInput: BarcodeInputProtorol
    
    func makeUIViewController(context: Context) -> UIViewController {
        return StanbyBarcodeInputViewController(viewModel: viewModel, barcodeInput: barcodeInput)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}

/// バーコード入力を通知するプロトコル
protocol BarcodeInputProtorol {
    /// キー入力
    /// - Parameter input: 入力文字（1文字）
    func inputBarcode(input: String)
}

/// バーコード入力フック付き待機画面ビューコントローラ
/// ・本クラスでビューコントローラでバーコードリーダからのキー入力をフックする
class StanbyBarcodeInputViewController: UIHostingController<StanbyKeyHookView> {
    private var barcodeInput: BarcodeInputProtorol
    
    init(viewModel: StanbyViewModel, barcodeInput: BarcodeInputProtorol) {
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
        // 領収書バーコードで使用する文字列のみ受け付ける
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
    
    @ObservedObject var viewModel: StanbyViewModel
    
    /// エラー表示ダイアログ表示を制御するフラグ
    /// 　→アーキテクチャとしてはviewModelに移すべきプロパティ。誤ってビュー側に定義したもの。
    /// 　→以下、@Stateについては同様 　
    @State private var isErrAlertActive = false
    /// エラー表示ダイアログに表示するエラーメッセージ
    @State private var errAlertMsg = ""
    /// エラー表示ダイアログ表示中に定期的にサウンドを鳴らすためのタイマー
    @State private var errorSoundTimer: Timer?
    
    init(viewModel: StanbyViewModel) {
        self.viewModel = viewModel
        
        // 画面遷移時のアニメーションを無効化
        UIView.setAnimationsEnabled(false)
    }
    
    var body: some View {
        // 背景を設定するためのZStack
        ZStack {
            Image(uiImage: ViewSetting.loadStanbyBGImage(barcordType: appSettingSvc.getMustAppSetting().barcodeType))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all) // 上下の余白まで背景色を統一
//            //開発用コード：ボタン遷移
//            Button {
//                let devBillingStr = "03400"
//                _ = viewModel.inputBarcode("200010\(devBillingStr)8")
//            } label: {
//                Text("3400")
//                    .font(Font.system(size: 48).bold())
//                    .frame(width: 300, height: 65.0)
//                    .background(Color.white)
//            }
            .onChange(of: viewModel.viewStatus, perform: { newValue in
                var isEAActive = false
                
                switch newValue {
                case .error(let message):
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
                
                isErrAlertActive = isEAActive
            })
            .onChange(of: scenePhase) { newValue in
                if newValue == .active {
                    // iPadホーム画面や他のアプリから本アプリに戻ってきた場合
                    viewModel.onActive()
                }
            }
            .alert("エラーが発生しました。\n係員にお知らせください。", isPresented: $isErrAlertActive) {
                Button("OK") {
                    errorSoundTimer?.invalidate()
                    errorSoundTimer = nil
                }
                .onAppear() {
                    log.error("\(type(of: self)): display error: \(errAlertMsg)")
                }
            } message: {
                Text(errAlertMsg)
            }
        }
        .onAppear {
            log.trace("\(type(of: self)): appear")
            
            viewModel.onApear()
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            StanbyView()
        }
    }
}
