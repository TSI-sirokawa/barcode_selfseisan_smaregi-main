//
//  BillingDetailView.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/12.
//

import SwiftUI

/// 請求内訳ビュー
struct BillingDetailView: View {
    let details: [BillingDetail]
    let fontSize: CGFloat
    
    static let DATE_FORMAT = "y年MM月dd日"
    
    init(details: [BillingDetail], fontSize: CGFloat) {
        // 時刻降順にソート
        var sortedDetails = details
        sortedDetails.sort {
            $0.time > $1.time
        }
        
        self.details = sortedDetails
        self.fontSize = fontSize
    }
    
    var body: some View {
        GeometryReader { geometry in
            // ビューの幅と高さを１００分割して、その個数で各ビューの幅と高さを決める
            // 　→単位はポイント（解像度とは異なる）
            let gridWidth = geometry.size.width / 100
            let gridHeight = geometry.size.height / 100
            
            // 請求内訳各行の高さを計算
            // 　→各行高さを揃えるため
            //　　 →請求内訳数が増えても本ビュー内に収めるために、
            // 　　 minimumScaleFactorモディファイアでフォントサイズを動的に変更させるが、
            // 　　 高さを明示的に揃えないと請求内訳数によって高さが交互に変化することがあり、
            // 　　 文字列の縦ラインが揃わなくなることへの対応
            // 　→式：ビューの高さからタイトル「請求内訳」分の高さを引いたもの（10%程）÷ 請求内訳数
            let detailHeight: CGFloat = {
                var ret = (gridHeight * 90) / CGFloat(details.count)
                
                // 請求内訳の高さを制限することで請求数が少ない場合に縦長になることを防ぐ
                let detailMaxHeight = (gridHeight * 6)
                if ret > detailMaxHeight {
                    ret = detailMaxHeight
                }
                
                return ret
            }()
            
            // タイトル「請求内訳」と各請求内訳を垂直方向の中央に配置するためのVStack
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("請求内訳")
                    .font(.appTextUI(size: fontSize))
                    .bold()
                    .padding(.bottom, 6)
                VStack(spacing: 0) {
                    ForEach(0..<details.count, id: \.self) { i in
                        let detail = details[i]
                        HStack(spacing: 0) {
                            // 番号
                            let indexStr = String(UnicodeScalar(UnicodeScalar("①").value + UInt32(i))!)
                            Text("\(indexStr)")
                                .font(.appNumUI(size: fontSize))
                                .frame(alignment: .leading)
                                .padding(.trailing, gridWidth * 1.2)
                            // 年月日
                            Text("\(detail.time.format(BillingDetailView.DATE_FORMAT))")
                                .font(.appNumUI(size: fontSize))
                                .frame(alignment: .leading)
                            Spacer()
                            // 金額
                            HStack(spacing: 0) {
                                Text("\(detail.amount.value)")
                                    .font(.appNumUI(size: fontSize))
                                    .padding(.trailing, gridWidth * 0.5)
                                Text("円")
                                    .font(.appTextUI(size: fontSize))
                            }
                        }
                        .frame(height: detailHeight)
                        .lineLimit(1)             // 行数を1行に固定
                        .minimumScaleFactor(0.9)  // ビューの大きさに合わせて文字サイズを0.x倍まで変更
                    }
                }
                Spacer()
            }
        }
    }
}

extension BillingDetailView {
    /// 請求内訳
    final class BillingDetail {
        let time: Date
        let amount: Amount
        
        init(time: Date, amount: Amount) {
            self.time = time
            self.amount = amount
        }
        
        init(time: Date, amount: String) {
            self.time = time
            do {
                // 請求金額のマイナス値は返金を示すのでマイナス値を許容する
                self.amount = try Amount(amount, isMinusAllow: true)
            } catch {
                fatalError("amount string is invalid. value=\(amount)")
            }
        }
    }
}
