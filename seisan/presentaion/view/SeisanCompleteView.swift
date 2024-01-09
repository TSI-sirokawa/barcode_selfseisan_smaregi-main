//
//  SeisanCompleteView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/07/19.
//

import SwiftUI
import Logging

/// 精算完了表示画面
struct SeisanCompleteView: View {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel = SeisanCompleteViewModel()
    
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
                
                VStack(spacing: 0) {
                    Text(viewModel.seisanCompleteMessage)
                        .font(.appTextUI(size: 36))
                        .bold()
                        .multilineTextAlignment(.center)
                        .lineSpacing(25)
                        .padding(.bottom, viewModel.shohosenHikikaekenMessage == "" ? (gridHeight * 8.5) : (gridHeight * 5))
                    if viewModel.shohosenHikikaekenMessage != "" {
                        // 処方箋引換券を印刷した場合
                        Text(viewModel.shohosenHikikaekenMessage)
                            .font(.appTextUI(size: 36))
                            .bold()
                            .multilineTextAlignment(.center)
                            .lineSpacing(25)
                            .padding(.bottom, gridHeight * 6)
                    }
                    Image("Images/jinbutu")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: viewModel.shohosenHikikaekenMessage == "" ? (gridWidth *  20.9) : (gridWidth * 18))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            log.trace("\(type(of: self)): appear")
            appState.noticeCurrScreen(.complete)
        }
    }
}

struct SettlementCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        SeisanCompleteView()
    }
}
