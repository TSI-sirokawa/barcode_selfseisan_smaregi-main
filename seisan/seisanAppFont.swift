//
//  seisanAppFont.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/07/08.
//

import SwiftUI

extension Font {
    /// アプリケーションテキストUIフォント
    /// - Parameter size: フォントサイズ
    /// - Returns: フォント
    static func appTextUI(size: CGFloat) -> Font {
        return Font.custom("BIZ UDGothic", size: size)
    }
    
    /// アプリケーション数値UIフォント
    /// - Parameter size: フォントサイズ
    /// - Returns: フォント
    static func appNumUI(size: CGFloat) -> Font {
        return Font.custom("Avenir Next", size: size)
    }
}
