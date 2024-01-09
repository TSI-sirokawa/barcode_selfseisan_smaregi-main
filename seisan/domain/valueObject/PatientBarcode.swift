//
//  ReceiptBarcode.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/09/13.
//

import Foundation
import Logging

/// 診察券バーコード
final class PatientBarcode: CustomStringConvertible {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// 患者番号
    let patientNo: String
    
    init(_ barcodeText: String) throws {
        patientNo = barcodeText
    }
    
    var description: String {
        return patientNo
    }
}
