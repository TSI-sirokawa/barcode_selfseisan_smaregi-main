//
//  TextPrintData.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/06/24.
//

import Foundation

/// テキスト印刷データ
final class TextPrintData {
    /// テキスト印刷データ
    let text: String
    /// テキストのフォント
    let font: String
    /// 領収印画像
    let ryoshuinImage: UIImage?
    
    init(text: String, font: String = "", ryoshuinImage: UIImage? = nil) {
        self.text = text
        self.font = font
        self.ryoshuinImage = ryoshuinImage
    }
}
