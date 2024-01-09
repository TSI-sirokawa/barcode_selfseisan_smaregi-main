//
//  EPosPrinterSetting.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/04/30.
//

import Foundation

extension EPosPrinter {
    /// EPSON ePOS SDK で接続できるレシートプリンタの通信設定
    final class Setting: Equatable {
        /// BlueToothデバイスアドレス
        /// 　例：
        /// 　　BT:NN:NN:NN:NN:NN:NN（Nは16進数文字列）
        let bdAddress: String
        
        /// ドット密度
        let dpi: Int
        
        /// 印字幅[mm]
        let printWidthMM: Float
        
        /// 印字幅[ピクセル]
        /// ※1ドットを1インチとした時のピクセル数（UIImage.scale = 1）
        var printWidthPixel: Int {
            get {
                let inchWidth = printWidthMM / 25.4   // ミリメールからインチに変換（1ミリ=25.4インチ）
                let pixelWidth = Float(dpi) * inchWidth
                return Int(pixelWidth)
            }
        }
        
        init(bdAddress: String, dpi: Int, printWidthMM: Float) throws {
            self.bdAddress = bdAddress
            self.dpi = dpi
            self.printWidthMM = printWidthMM
            
            try Setting.BD_ADDRESS.validate(bdAddress)
            try Setting.DPI.validate(dpi)
            try Setting.PRINT_WIDTH_MM.validate(printWidthMM)
        }
        
        static let BD_ADDRESS = SettingValueAttr(
            label: "BDアドレス",
            defaultValue: "",
            placeHolder: "例：BD:NN:NN:NN:NN:NN:NN",
            errorMessage: "設定してください。",
            isValidOK: { value in return value != "" })
        
        static let DPI = SettingValueAttr(
            label: "ドット密度",
            defaultValue: 203,
            placeHolder: "例：203",
            errorMessage: "1以上の値を入力してください。例：203",
            isValidOK: { value in return value >= 1 })
        
        static let PRINT_WIDTH_MM = SettingValueAttr(
            label: "印字幅[mm]",
            defaultValue: Float(72),
            placeHolder: "例：72",
            errorMessage: "1以上の値を入力してください。例：72",
            isValidOK: { value in return value >= 1 })
        
        static func == (lhs: EPosPrinter.Setting, rhs: EPosPrinter.Setting) -> Bool {
            return lhs.bdAddress == rhs.bdAddress &&
            lhs.dpi == rhs.dpi &&
            lhs.printWidthMM == rhs.printWidthMM
        }
    }
}
