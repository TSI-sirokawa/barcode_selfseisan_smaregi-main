//
//  ReceiptSeisanUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/14.
//

import Foundation
import Logging

/// 領収書精算開始ユースケース
final class ReceiptSeisanUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private(set) var barcode: ReceiptBarcode
    
    init(barcode: ReceiptBarcode) {
        self.barcode = barcode
    }
    
    func exec() throws ->  ReceiptBilling {
        do {
            let billing = try ReceiptBilling(billingAmount: barcode.billingAmount)
            return billing
        } catch {
            throw RunError.argument("不正な請求金額です。\n\(error))")
        }
    }
}

extension ReceiptSeisanUseCase {
    enum RunError: Error {
        case argument(String)
    }
}
