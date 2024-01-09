//
//  KesaiSelectView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/07/18.
//

import SwiftUI
import AudioToolbox
import Logging

/// 決済方法選択画面
struct KesaiSelectView: View {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel =  KesaiSelectViewModel()
    /// エラー表示ダイアログ表示中に定期的にサウンドを鳴らすためのタイマー
    @State private var errorSoundTimer: Timer?
    
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
                let gridWidth = geometry.size.width / 100
                let gridHeight = geometry.size.height / 100
                
                ZStack {
                    // 上のコンテンツ
                    VStack(spacing: 0) {
                        ZStack {
                            // 患者名や請求金額の表示部分
                            VStack(spacing: 0) {
                                if let customer = viewModel.customer {
                                    // 患者番号、患者名
                                    VStack(spacing: 0) {
                                        Text("")
                                            .padding(.top, gridHeight * 1)
                                        // 患者番号
                                        Text("\(customer.code)")
                                            .font(.appNumUI(size: 32))
                                            .bold()
                                            .kerning(2)
                                            .padding(.bottom, gridHeight * 1.2)
                                        // 患者名
                                        HStack(spacing: 0) {
                                            Text("\(customer.name)")
                                                .font(.appTextUI(size: 36))
                                                .bold()
                                                .kerning(2)
                                                .padding(.trailing, gridWidth * 0.5)
                                            Text("様")
                                                .font(.appTextUI(size: 36))
                                                .bold()
                                                .kerning(2)
                                        }
                                    }
                                    .padding(.bottom, gridHeight * 7.8)
                                }
                                // 請求額
                                Text("ご請求")
                                    .font(.appTextUI(size: 26))
                                    .bold()
                                    .kerning(2)
                                    .padding(.bottom, viewModel.customer == nil ? gridHeight * 2.8 : 1.5)
                                HStack(spacing: 0) {
                                    Text("\(viewModel.billingAmount)")
                                    //                            Text("9,999,999")
                                        .font(.appNumUI(size: 110))
                                        .lineLimit(1)               // 行数を１行に固定
                                        .minimumScaleFactor(0.5)    // ビューの大きさに合わせて文字サイズを0.x倍まで変更
                                        .fontWeight(.semibold)
                                        .padding(.trailing, gridWidth * 1)
                                    Text("円")
                                        .font(.appTextUI(size: 46))
                                        .bold()
                                        .fontWeight(.semibold)
                                        .offset(y: gridHeight * 1.5)
                                }
                                .frame(maxWidth: gridWidth * 40)
                                if viewModel.customer != nil {
                                    // 患者番号と患者名を表示する場合は上寄せ
                                    Spacer()
                                }
                            }
                            // 請求内訳
                            if appState.getSeisanType() == .PatientCardSeisan {
                                // 診察券精算の場合、請求内訳を表示
                                HStack(spacing: 0) {
                                    Spacer()
                                    HStack(spacing: 0) {
                                        Divider()
                                            .frame(height: gridHeight * 34)
                                        HStack(spacing: 0) {
                                            BillingDetailView(
                                                details: viewModel.tempTranses.map { BillingDetailView.BillingDetail(time: $0.time, amount: $0.total) },
                                                fontSize: 15)
                                            .padding(.leading, gridWidth * 2)
                                            Spacer()
                                        }
                                    }
                                    .frame(width: gridWidth * 26)
                                    .padding(.bottom, gridHeight * 11) // 底上げ
                                }
                                .padding(.trailing, gridWidth * 2.5)
                            }
                        }
                        .frame(height: gridHeight * 57)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 244/255, green: 247/255, blue: 250/255))
                        .padding(.top, gridHeight * 5)
                        Spacer()
                    }
                    // 中央のコンテンツ
                    VStack(spacing:0) {
                        Spacer()
                        HStack {
                            if appState.isCashUse {
                                // 現金ボタン
                                SelectButton(
                                    image: {
                                        Image("Images/genkin1")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: gridWidth * 14)
                                            .padding(.top, gridWidth * 3)
                                    },
                                    title: {
                                        Text("現　金")
                                            .font(.appTextUI(size: 34))
                                            .bold()
                                            .foregroundColor(Color(red: 21/255, green: 57/255, blue: 93/255))
                                    },
                                    onButton: {
                                        viewModel.selectCashKesai()
                                    }
                                )
                                .frame(width: gridWidth * 31)
                                .frame(maxHeight: .infinity)
                                .padding(.trailing, gridWidth * 6)
                                .disabled(viewModel.isIndicatorActive)
                            }
                            if appState.isCreditUse {
                                // クレジットカードボタン
                                SelectButton(
                                    image: {
                                        Image("Images/card")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: gridWidth * 8)
                                            .padding(.top, gridWidth * 4)
                                    },
                                    title: {
                                        Text("クレジットカード")
                                            .font(.appTextUI(size: 34))
                                            .bold()
                                            .foregroundColor(Color(red: 21/255, green: 57/255, blue: 93/255))
                                    },
                                    onButton: {
                                        viewModel.selectCreditKesai()
                                    }
                                )
                                .frame(width: gridWidth * 31)
                                .frame(maxHeight: .infinity)
                                .disabled(viewModel.isIndicatorActive)
                            }
                        }
                        .frame(height: gridHeight * 23)
                        .padding(.bottom, gridHeight * 26)
                    }
                    // 下のコンテンツ
                    VStack(spacing:0) {
                        Spacer()
                        ZStack {
                            Text("お支払い方法を選択してください")
                                .font(.appTextUI(size: 36))
                                .bold()
                                .kerning(2)
                                .padding()
                            HStack {
                                Button {
                                    // 決済方法選択をキャンセル
                                    viewModel.cancel()
                                } label: {
                                    HStack {
                                        Image(systemName: "chevron.backward")
                                            .font(.system(size: 30))
                                            .bold()
                                            .padding(.trailing, gridWidth * 0.5)
                                        Text("キャンセル")
                                            .font(.appTextUI(size: 20))
                                            .bold()
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: gridWidth * 19, height: gridHeight * 8)
                                    .background(
                                        // 右角を丸める
                                        RoundView(
                                            color: Color(red: 150/255, green: 167/255, blue: 189/255),
                                            topRightRadius: 40,
                                            bottomRightRadius: 40
                                        )
                                    )
                                    .shadow(color: .gray, radius: 10, x: 0, y: 0)
                                }
                                .disabled(viewModel.isIndicatorActive)
                                Spacer()
                            }
                        }
                        .frame(height: gridHeight * 18)
                        .padding(.bottom, gridHeight * 8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onChange(of: viewModel.isErrExternalAlertActive, perform: { newValue in
                if newValue {
                    // まずは即時に警告音を鳴らし、その後は一定間隔で警告音を鳴らす
                    AudioServicesPlaySystemSound(SystemSoundID(1005))
                    errorSoundTimer = Timer.scheduledTimer(
                        withTimeInterval: 10,
                        repeats: true,
                        block: { timer in
                            AudioServicesPlaySystemSound(SystemSoundID(1005))
                        })
                }
            })
            .alert("取引中にエラーが発生しました。\n係員にお知らせください。", isPresented: $viewModel.isErrExternalAlertActive) {
                Button("取引キャンセル") {
                    errorSoundTimer?.invalidate()
                    errorSoundTimer = nil
                    
                    // 外部システム連携エラー時は取引キャンセルのみ
                    viewModel.cancel()
                }
            } message: {
                Text(viewModel.errExternalAlertMsg)
            }
            if viewModel.isIndicatorActive {
                // インジケータを表示
                ActivityIndicator()
            }
        }
        .onAppear {
            log.trace("\(type(of: self)): appear")
            appState.noticeCurrScreen(.kesaiSelect)
        }
        .navigationBarBackButtonHidden(true) // ナビゲーションバーの戻るボタン非表示 & スワイプで戻る操作無効
    }
    
    /// 選択ボタン
    private struct SelectButton<Content1: View, Content2: View>: View {
        /// 画像
        @ViewBuilder var image: () -> Content1
        /// タイトル
        @ViewBuilder var title: () -> Content2
        /// ボタンがタップされた
        let onButton: () -> Void
        
        var body: some View {
            Button {
                onButton()
            } label: {
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(40)
                        .shadow(color: .gray, radius: 10, x: 0, y: 0)
                    VStack(spacing: 0) {
                        image()
                        Spacer()
                    }
                    VStack(spacing: 0) {
                        Spacer()
                        title()
                            .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}

struct PaymentSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        KesaiSelectView()
    }
}
