//
//  ReceiptBarcode.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/09/13.
//

import Foundation
import Logging

/// 領収書バーコード
final class ReceiptBarcode {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// 請求金額
    let billingAmount: BillingAmount
    
    init(_ barcodeText: String) throws {
        // バーコード長を確認
        if barcodeText.count < 12 {
            throw ReceiptBarcordValidationError.length(message: "barcode=\(barcodeText), length=\(barcodeText.count)")
        }
        
        // バーコード文字列から各種データを取り出す
        let flag = barcodeText[barcodeText.startIndex...barcodeText.index(barcodeText.startIndex, offsetBy: 0)]
        let code = barcodeText[barcodeText.index(barcodeText.startIndex, offsetBy: 1)...barcodeText.index(barcodeText.startIndex, offsetBy: 4)]
        let price = barcodeText[barcodeText.index(barcodeText.startIndex, offsetBy: 5)...barcodeText.index(barcodeText.startIndex, offsetBy: 10)]
        let checkDegit = barcodeText[barcodeText.index(barcodeText.startIndex, offsetBy: 11)...barcodeText.index(barcodeText.startIndex, offsetBy: 11)]
         
        // バリデーションを実施
        // ・バーコードリーダはチェックデジットが正しいバーコードしか出力しないため、チェックデジットの検証は行わない
        if String(flag) != "2" {
            throw ReceiptBarcordValidationError.flag(message: "barcode=\(barcodeText), flag[want:actual]=[2:\(flag)]")
        }
        
        if String(code) != "0001" {
            throw ReceiptBarcordValidationError.code(message: "barcode=\(barcodeText), code[want:actual]=[0001:\(code)]")
        }
        
        // プライスを数値変換して返す
        guard let retPrice = Int(String(price)) else {
            throw ReceiptBarcordValidationError.price(message: "barcode=\(barcodeText), price=\(price)")
        }
        
        log.info("\(type(of: self)): receipt barcode ok. flag=\(flag), code=\(code), price=\(price), checkDegit=\(checkDegit)")
        
        billingAmount = try BillingAmount(retPrice, isMinusAllow: false)
    }
}

extension ReceiptBarcode {
    /// 領収書バーコード文字列バリデーションエラー
    enum ReceiptBarcordValidationError: Error {
        ///  バーコード長エラー
        case length(message: String)
        
        /// フラグエラー
        case flag(message: String)
        
        /// 商品コードエラー
        case code(message: String)
        
        /// プライスエラー
        case price(message: String)
    }

}
