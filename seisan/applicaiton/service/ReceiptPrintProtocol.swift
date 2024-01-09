//
//  ReceiptPrintProtocol.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/02.
//

import Foundation

/// レシート印刷プロトコル
protocol ReceiptPrintProtocol {
    func connect() throws
    func disconnect()
    func printText(textPrintDatas: [TextPrintData]) throws
    func printContinuousText(textContinuousPrintData: ContinuousTextPrintData) throws
    func printImage(image: UIImage) throws
}
