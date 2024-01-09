//
//  CreditKesaiMockView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/04/02.
//

import SwiftUI
import Logging

// クレジット決済モック画面
struct CreditKesaiMockView: View {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CreditKesaiViewModel()
    
    var body: some View {
        // 背景色を設定するためのZStack
        ZStack {
            Color(.seisanAppBackground).edgesIgnoringSafeArea(.all) // 上下の余白まで背景色を統一
            Button {
                viewModel.completeKesai()
            } label: {
                 Text("決済")
                    .font(Font.system(size: 48).bold())
                    .frame(width: 300, height: 65.0)
                    .background(Color.white)
            }
        }
        .onAppear {
            log.trace("\(type(of: self)): appear")
            appState.noticeCurrScreen(.creditKesai)
        }
    }
}

struct CreditKesaiMockView_Previews: PreviewProvider {
    static var previews: some View {
        CreditKesaiView()
    }
}
