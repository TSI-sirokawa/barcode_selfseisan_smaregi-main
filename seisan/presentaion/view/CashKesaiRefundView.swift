//
//  CashKesaiRefundView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/31.
//

import SwiftUI
import Logging

/// 出金抜き取り待機ダイアログ
struct CashKesaiRefundView: View {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    var title: String
    
    var body: some View {
        GeometryReader { geomerty in
            VStack {
                Text(title)
                    .font(.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .onAppear() {
            log.trace("\(type(of: self)): appear")
        }
    }
}

struct CashKesaiRefundView_Previews: PreviewProvider {
    static var previews: some View {
        CashKesaiRefundView(title: "previews")
    }
}
