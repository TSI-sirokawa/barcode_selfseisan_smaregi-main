//
//  CreditReceiptPrintService.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/08/27.
//

import Foundation
import Logging

/// クレジットレシート印刷サービス
final class CreditReceiptPrintService {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    let receiptImage: UIImage
    let receiptPrintSvc: ReceiptPrintService
    
    init(receiptImage: UIImage, receiptPrintSvc: ReceiptPrintService) {
        self.receiptImage = receiptImage
        self.receiptPrintSvc = receiptPrintSvc
    }
    
    /// 印刷を開始する
    func exec() {
        receiptPrintSvc.printImage(image: receiptImage)
    }
}
