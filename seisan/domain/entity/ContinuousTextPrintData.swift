//
//  ContinuousTextPrintData.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/06/24.
//

import Foundation

/// 切れ目なく印刷するためのテキスト印刷データ
final class ContinuousTextPrintData {
    /// テキスト印刷データ
    let textPrintDatas: [TextPrintData]
    
    init(textPrintDatas: [TextPrintData]) {
        self.textPrintDatas = textPrintDatas
    }
}
