//
//  ReceiptSeisanFinalizeView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/12/10.
//

import SwiftUI
import Logging

struct ReceiptSeisanFinalizeView: View {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel =  ReceiptSeisanFinalizeViewModel()
    /// 印刷リトライ表示ダイアログ表示を制御するフラグ
    @State var isPrintRetryAlertActive = false
    
    var body: some View {
        ZStack {
            // 背景画像
            Image("Images/haikei_3_4_5")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all) // 上下の余白まで背景色を統一
            // コンテンツ
            GeometryReader { geometry in
                // 画面の幅と高さを１００分割して、その個数で各ビューの幅と高さを決める
                // 　→単位はポイント（解像度とは異なる）
                let gridHeight = geometry.size.height / 100
                
                ZStack {
                    Text("しばらくお待ちください。")
                        .font(.appTextUI(size: 36))
                        .bold()
                        .padding()
                    ActivityIndicator()
                        .padding(.top, gridHeight * 14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            log.trace("\(type(of: self)): appear")
            appState.noticeCurrScreen(.seisanFinalize)
        }
        .onChange(of: viewModel.viewStatus, perform: { newValue in
        })
        .alert("精算は完了しましたが、スマレジへの取引結果登録中にエラーが発生しました。\n係員にお知らせください。", isPresented: $viewModel.isErrAlertActive) {
            Button("OK") {
                viewModel.errorOK()
            }
            .onAppear() {
                log.error("\(type(of: self)): display error: \(viewModel.errAlertMsg)")
            }
        } message: {
            Text(viewModel.errAlertMsg)
        }
        .alert("精算は完了しましたが、印刷中にエラーが発生しました。\n係員にお知らせください。", isPresented: $viewModel.isPrintErrAlertActive) {
            Button("OK") {
                isPrintRetryAlertActive = true
            }
            .onAppear() {
                log.error("\(type(of: self)): display print error: \(viewModel.errAlertMsg)")
            }
        } message: {
            Text(viewModel.printErrAlertMsg)
        }
        .alert("プリンタの状態を確認してください。\n印刷を再開する場合は「はい」を選択してください。", isPresented: $isPrintRetryAlertActive) {
            Button("いいえ") {
                viewModel.giveupPrint()
            }
            Button("はい") {
                viewModel.retryPrint()
            }
            .onAppear() {
                log.error("\(type(of: self)): display print retry select: \(viewModel.errAlertMsg)")
            }
        } message: {
            Text(viewModel.printErrAlertMsg)
        }
        .navigationBarBackButtonHidden(true) // ナビゲーションバーの戻るボタン非表示 & スワイプで戻る操作無効
    }
    
    struct SmaregiTransactionUploadView_Previews: PreviewProvider {
        static var previews: some View {
            ReceiptSeisanFinalizeView()
        }
    }
}
