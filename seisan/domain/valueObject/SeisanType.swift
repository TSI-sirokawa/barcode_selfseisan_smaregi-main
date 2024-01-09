//
//  SeisanType.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/13.
//

import Foundation

/// 精算種別
enum SeisanType: Codable {
    /// 領収書精算
    case ReceiptSeisan
    /// 診察券精算
    case PatientCardSeisan
    /// T.B.D: 将来的にはここに「事務端末からの精算」や「ティーエスアイ製の会計システムからの精算」などを追加予定
}
