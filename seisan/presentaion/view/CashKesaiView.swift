//
//  CashKesaiView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/07/18.
//

import SwiftUI
import Logging

/// 現金決済処理画面
struct CashKesaiView: View {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var announceMgr: AnnounceManager
    
    @StateObject var viewModel: CashKesaiViewModel =  CashKesaiViewModel()
    
    /// つり銭機への投入状態を表示する文字列の文字サイズ
    private static let PAYMENT_STATE_FONT_SIZE: CGFloat = 30
    
    var body: some View {
        //背景色を設定するためのZStack
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
                            // 「現金でのお支払い」とアイコンの表示部分
                            HStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    Text("現金でのお支払い")
                                        .font(.appTextUI(size: 24))
                                        .bold()
                                        .kerning(1)
                                        .padding(.bottom, gridHeight * 5)
                                    Image("Images/genkin _2")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: gridWidth * 20)
                                }
                                .padding(.leading, gridWidth * 5)
                                Spacer()
                            }
                            // 患者名や請求金額や投入金額の表示部分
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
                                    .padding(.bottom, viewModel.customer == nil ? gridHeight * 6 : gridHeight * 3)
                                }
                                Text("ご請求")
                                    .font(.appTextUI(size: 26))
                                    .bold()
                                    .kerning(2)
                                    .padding(.bottom, viewModel.customer == nil ? gridHeight * 1.8 : gridHeight * 0.8)
                                HStack(spacing: 0) {
                                    Text("\(viewModel.billingAmount)")
                                    //                                    Text("1,999,999")
                                        .font(.appNumUI(size: 110))
                                        .font(.largeTitle)
                                        .fontWeight(.semibold)
                                        .padding(.trailing, gridWidth * 1.1)
                                        .frame(height: gridHeight * 11)
                                        .lineLimit(1)               // 行数を１行に固定
                                        .minimumScaleFactor(0.1)    // ビューの大きさに合わせて文字サイズを0.x倍まで変更
                                    Text("円")
                                        .font(.appTextUI(size: 46))
                                        .bold()
                                        .fontWeight(.semibold)
                                }
                                .padding(.bottom, viewModel.customer == nil ? gridHeight * 1.6 : gridHeight * 0.4)
                                Divider()
                                    .padding(.bottom, gridHeight * 1.6)
                                HStack(spacing: 0) {
                                    Text("投入金額")
                                        .font(.appTextUI(size: CashKesaiView.PAYMENT_STATE_FONT_SIZE))
                                        .bold()
                                    Spacer()
                                    HStack(spacing: 0) {
                                        Text("\(viewModel.depositAmount)")
                                            .font(.appNumUI(size: CashKesaiView.PAYMENT_STATE_FONT_SIZE))
                                            .fontWeight(.semibold)
                                            .padding(.trailing, gridWidth * 1.1)
                                        Text("円")
                                            .font(.appTextUI(size: CashKesaiView.PAYMENT_STATE_FONT_SIZE))
                                            .bold()
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding(.bottom, gridHeight * 1)
                                HStack(spacing: 0) {
                                    Text("不足金額")
                                        .font(.appTextUI(size: CashKesaiView.PAYMENT_STATE_FONT_SIZE))
                                        .bold()
                                    Spacer()
                                    HStack(spacing: 0) {
                                        Text("\(viewModel.minusAmount)")
                                            .font(.appNumUI(size: CashKesaiView.PAYMENT_STATE_FONT_SIZE))
                                            .fontWeight(.semibold)
                                            .padding(.trailing, gridWidth * 1.1)
                                        Text("円")
                                            .font(.appTextUI(size: CashKesaiView.PAYMENT_STATE_FONT_SIZE))
                                            .bold()
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding(.bottom, gridHeight * 1.6)
                                Divider()
                                    .padding(.bottom, gridHeight * 1.6)
                                HStack(spacing: 0) {
                                    Text("おつり")
                                        .font(.appTextUI(size: CashKesaiView.PAYMENT_STATE_FONT_SIZE))
                                        .bold()
                                    Spacer()
                                    HStack(spacing: 0) {
                                        Text("\(viewModel.changeAmount)")
                                            .font(.appNumUI(size: CashKesaiView.PAYMENT_STATE_FONT_SIZE))
                                            .fontWeight(.semibold)
                                            .padding(.trailing, gridWidth * 1.1)
                                        Text("円")
                                            .font(.appTextUI(size: CashKesaiView.PAYMENT_STATE_FONT_SIZE))
                                            .bold()
                                            .fontWeight(.semibold)
                                    }
                                }
                                if viewModel.customer != nil {
                                    // 患者番号と患者名を表示する場合は上寄せ
                                    Spacer()
                                }
                            }
                            .frame(width: gridWidth * 30)
                            // 請求内訳
                            if appState.getSeisanType() == .PatientCardSeisan {
                                // 診察券精算の場合、請求内訳を表示
                                HStack(spacing: 0) {
                                    Spacer()
                                    HStack(spacing: 0) {
                                        Divider()
                                            .frame(height: gridHeight * 50)
                                        HStack(spacing: 0) {
                                            BillingDetailView(
                                                details: viewModel.tempTranses.map { BillingDetailView.BillingDetail(time: $0.time, amount: $0.total) },
                                                fontSize: 15)
                                            .padding(.leading, gridWidth * 2)
                                            Spacer()
                                        }
                                    }
                                    .frame(width: gridWidth * 26)
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
                    // 下のコンテンツ
                    VStack(spacing:0) {
                        Spacer()
                        HStack(spacing: 0) {
                            // お支払い選択に戻るボタン
                            Button {
                                viewModel.cancelKesai()
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.backward")
                                        .font(.system(size: 30))
                                        .bold()
                                        .padding(.trailing, gridWidth * 0.5)
                                    Text("お支払い\n選択に戻る")
                                        .font(.appTextUI(size: 20))
                                        .bold()
                                        .lineSpacing(gridHeight * 0.4)    // 行間の高さ調整
                                        .multilineTextAlignment(.leading) // テキストの内容を左寄せにする
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
                            .disabled(!viewModel.isCanelButtonEnable)
                            .padding(.trailing, gridWidth * 4)
                            Spacer()
                            // 案内表示
                            Text(viewModel.announce)
                                .font(.appTextUI(size: 34))
                                .bold()
                                .lineSpacing(gridHeight * 2.4)   // 行間の高さ調整
                                .multilineTextAlignment(.center) // テキストの中央寄せ
                                .lineLimit(2)                    // 行数を２行に固定
                                .minimumScaleFactor(0.8)         // ビューの大きさに合わせて文字サイズを0.x倍まで変更
                                .padding(.trailing, gridWidth * 5)
                                .padding(.bottom, gridWidth * 5.5) // 少し上に上げる（デザイン仕様）
                            Spacer()
                            // 精算ボタン
                            Button (){
                                viewModel.fixKesai()
                            } label: {
                                VStack(spacing: 0) {
                                    Group {
                                        if viewModel.isSeisanButtonEnable {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(red: 21/255, green: 57/255, blue: 93/255))
                                                .padding(.top, gridWidth * 0.5)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.gray)
                                                .padding(.top, gridWidth * 0.5)
                                        }
                                    }
                                    .font(.largeTitle)
                                    .padding(.bottom, gridHeight * 2)
                                    Text("精算")
                                        .font(.appTextUI(size: 40))
                                        .bold()
                                        .kerning(10)     // 文字間の幅
                                        .offset(x: 10/2) //  文字間の幅は最後の文字の右側にも適用されるため、文字が水平方向の中央に表示されるように調整
                                        .foregroundColor(viewModel.isSeisanButtonEnable ? Color(red: 21/255, green: 57/255, blue: 93/255) : Color(red: 114/255, green: 114/255, blue: 114/255))
                                        .padding(.bottom, gridWidth * 1.5)
                                }
                            }
                            .frame(width: gridWidth * 15, height: gridHeight * 19)
                            .background(
                                RoundView(
                                    color: viewModel.isSeisanButtonEnable ? Color.white : Color(UIColor.lightGray),
                                    radius: 30
                                )
                            )
                            .shadow(color: .gray, radius: 10, x: 0, y: 0)
                            .padding(.bottom, gridHeight * 0.5)
                            .padding(.trailing, gridHeight * 10)
                            .padding(.bottom, gridWidth * 7) // 少し上に上げる（デザイン仕様）
                            .disabled(!viewModel.isSeisanButtonEnable)
                        }
                        .frame(height: gridHeight * 18)
                        .padding(.bottom, gridHeight * 8)
                    }
                    if viewModel.isRefundDialogActive {
                        // 出金抜き取り待機ダイアログ表示
                        // 　→　まず背景に「透明な灰色の背景」を重ね、その上に「出金抜き取り待機ダイアログ」を重ねる
                        Rectangle()
                            .fill(.gray.opacity(0.5))
                            .edgesIgnoringSafeArea(.all) // 上下の余白まで背景色を統一
                        Image("Images/mrejiap_7")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: gridWidth * 50, height: gridHeight * 50)
                            .compositingGroup() // 背景のみに影を適用
                            .shadow(color: .gray, radius: 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onChange(of: viewModel.viewStatus) { newViewStatus in
                if newViewStatus == .change {
                    // おつりがある場合のアナウンス音声を再生
                    announceMgr.play(situation: .changeExist)
                }
            }
            .alert("取引中にエラーが発生しました。\n係員にお知らせください。", isPresented: $viewModel.isErrAlertActive) {
                Button("取引継続") {
                    viewModel.restoreKesai()
                }
                Button("取引キャンセル") {
                    viewModel.errorCancelKesai()
                }
            } message: {
                Text(viewModel.errAlertMsg)
            }
            if viewModel.isIndicatorActive {
                // インジケーター表示
                ActivityIndicator()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            log.trace("\(type(of: self)): appear")
            appState.noticeCurrScreen(.cashKesai)
            
            if viewModel.viewStatus == .`init` {
                // 初回の画面表示時に決済を開始
                // ・画面が描画される度にonApearが呼ばれるため、初期化中の場合のみ
                // ・画面遷移をNavigationViewからNavigationStackに切り替えたため、何度も画面描画が走る状況は改善されたかもしれないが、
                // 　確証はないため実装は変更しない
                viewModel.startKesai()
            }
        }
    }
}

struct CashSettlementView_Previews: PreviewProvider {
    static var previews: some View {
        CashKesaiView()
    }
}
