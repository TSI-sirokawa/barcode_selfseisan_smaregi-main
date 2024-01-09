//
//  RoundView.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/07/08.
//

import SwiftUI

/// ビューの特定の角を丸めるためのビュー
struct RoundView: View {
    /// 色
    var color: Color
    /// 左上丸みの半径
    var topLeftRadius: CGFloat = 0
    /// 右上丸みの半径
    var topRightRadius: CGFloat = 0
    /// 左下丸みの半径
    var bottomLeftRadius: CGFloat = 0
    /// 右下丸みの半径
    var bottomRightRadius: CGFloat = 0
    
    init(color: Color,
         topLeftRadius: CGFloat = 0,
         topRightRadius: CGFloat = 0,
         bottomLeftRadius: CGFloat = 0,
         bottomRightRadius: CGFloat = 0) {
        self.color = color
        self.topLeftRadius = topLeftRadius
        self.topRightRadius = topRightRadius
        self.bottomLeftRadius = bottomLeftRadius
        self.bottomRightRadius = bottomRightRadius
    }
    
    init(color: Color, radius: CGFloat) {
        self.color = color
        self.topLeftRadius = radius
        self.topRightRadius = radius
        self.bottomLeftRadius = radius
        self.bottomRightRadius = radius
    }
    
    var body: some View {
        GeometryReader { geometry in
            RoundRectangle(
                width: geometry.size.width,
                height: geometry.size.height,
                topLeftRadius: topLeftRadius,
                topRightRadius: topRightRadius,
                bottomLeftRadius: bottomLeftRadius,
                bottomRightRadius: bottomRightRadius)
            .fill(color, strokeContent: Color.gray, strokeStyle: StrokeStyle(lineWidth: 1))
        }
    }
    
    /// 角丸の四角
    private struct RoundRectangle: Shape {
        /// 幅
        let width: CGFloat
        /// 高さ
        let height: CGFloat
        /// 左上丸みの半径
        let topLeftRadius: CGFloat
        /// 右上丸みの半径
        let topRightRadius: CGFloat
        /// 左下丸みの半径
        let bottomLeftRadius: CGFloat
        /// 右下丸みの半径
        let bottomRightRadius: CGFloat
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            // 各丸み（左上、右上、左下、右下）の半径を計算
            // 　→幅と高さの半分より大きな値が指定された場合は、幅と高さのうち最小の値を使用
            let tr = min(min(topRightRadius, height/2), width/2)
            let tl = min(min(topLeftRadius, height/2), width/2)
            let bl = min(min(bottomLeftRadius, height/2), width/2)
            let br = min(min(bottomRightRadius, height/2), width/2)
            
            // 上線の真ん中
            path.move(to: CGPoint(x: width/2.0, y: 0))
            // 右上丸みの開始位置まで線を引く
            path.addLine(to: CGPoint(x: width-tr, y: 0))
            // 右上丸みの中央
            path.addArc(center: CGPoint(x: width-tr, y: tr),
                        radius: tr,                         // 半径
                        startAngle: Angle(degrees: 270),    // 上
                        endAngle: Angle(degrees: 0),        // 右
                        clockwise: false)                   // 角度を反時計回りで指定
            // 右下丸みの開始位置まで線を引く
            path.addLine(to: CGPoint(x: width, y: height-br))
            // 右下丸みの中央
            path.addArc(center: CGPoint(x: width-br, y: height-br),
                        radius: br, startAngle: Angle(degrees: 0),
                        endAngle: Angle(degrees: 90),
                        clockwise: false)
            // 左下丸みの開始位置まで線を引く
            path.addLine(to: CGPoint(x: bl, y: height))
            // 左下丸みの中央
            path.addArc(center: CGPoint(x: bl, y: height-bl),
                        radius: bl,
                        startAngle: Angle(degrees: 90),
                        endAngle: Angle(degrees: 180),
                        clockwise: false)
            // 左上丸みの開始位置まで線を引く
            path.addLine(to: CGPoint(x: 0, y: tl))
            // 左上丸みの中央
            path.addArc(center: CGPoint(x: tl, y: tl),
                        radius: tl,
                        startAngle: Angle(degrees: 180),
                        endAngle: Angle(degrees: 270),
                        clockwise: false)
            // 最後は「上線の真ん中」まで線を引く
            path.addLine(to: CGPoint(x: width/2.0, y: 0))
            return path
        }
    }
}
