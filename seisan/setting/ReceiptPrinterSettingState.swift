//
//  ReceiptPrinterSettingState.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/02.
//

import Foundation
import Logging

/// レシートプリンタ通信設定状態
final class ReceiptPrinterSettingState: SettingCheckProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    var bdAddress: String {
        didSet {
            if bdAddress != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var dpi: Int {
        didSet {
            if dpi != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    var printWidthMM: Float {
        didSet {
            if printWidthMM != oldValue {
                clearTestResult()
                validateSetting()
            }
        }
    }
    
    /// バリデーション結果
    var isBDAddressOK = false
    var isDPIOK = false
    var isPrintWidthMMOK = false
    
    /// 通信確認結果
    var isCommTestExecuted: Bool
    var isCommTestOK: Bool
    var commTestMessage: String
    
    /// 通信設定が完了したかどうか
    var isCommSettingOK: Bool {
        get {
            return isBDAddressOK
        }
    }
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        return isBDAddressOK &&
        isDPIOK &&
        isPrintWidthMMOK
    }
    /// テストが完了したかどうか
    var isTestOK: Bool {
        return isCommTestOK
    }
    
    var shortSummary: String {
        return ""
    }
    
    static let DEFAULT = ReceiptPrinterSettingState(
        bdAddress: EPosPrinter.Setting.BD_ADDRESS.defaultValue,
        dpi: EPosPrinter.Setting.DPI.defaultValue,
        printWidthMM: EPosPrinter.Setting.PRINT_WIDTH_MM.defaultValue,
        isCommTestExecuted: false,
        isCommTestOK: false,
        commTestMessage: "")
    
    init(bdAddress: String,
         dpi: Int,
         printWidthMM: Float,
         isCommTestExecuted: Bool,
         isCommTestOK: Bool,
         commTestMessage: String) {
        self.bdAddress = bdAddress
        self.dpi = dpi
        self.printWidthMM = printWidthMM
        self.isCommTestExecuted = isCommTestExecuted
        self.isCommTestOK = isCommTestOK
        self.commTestMessage = commTestMessage
    }
    
    func validateSetting() {
        do {
            try EPosPrinter.Setting.BD_ADDRESS.validate(bdAddress)
            isBDAddressOK = true
        } catch {
            isBDAddressOK = false
        }
        do {
            try EPosPrinter.Setting.DPI.validate(dpi)
            isDPIOK = true
        } catch {
            isDPIOK = false
        }
        do {
            try EPosPrinter.Setting.PRINT_WIDTH_MM.validate(printWidthMM)
            isPrintWidthMMOK = true
        } catch {
            isPrintWidthMMOK = false
        }
    }
    
    func getSetting() -> EPosPrinter.Setting? {
        do {
            return try EPosPrinter.Setting(
                bdAddress: bdAddress,
                dpi: dpi,
                printWidthMM: printWidthMM)
        } catch {
            log.error("\(type(of: self)): create setting eror: \(error)")
            return nil
        }
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> ReceiptPrinterSettingState {
        return ReceiptPrinterSettingState(
            bdAddress: repo.load(key: "ReceiptPrinterSettingState.bdAddress") ?? DEFAULT.bdAddress,
            dpi: repo.load(key: "ReceiptPrinterSettingState.dpi") ?? DEFAULT.dpi,
            printWidthMM: repo.load(key: "ReceiptPrinterSettingState.printWidthMM") ?? DEFAULT.printWidthMM,
            isCommTestExecuted: repo.load(key: "ReceiptPrinterSettingState.isCommTestExecuted") ?? DEFAULT.isCommTestExecuted,
            isCommTestOK: repo.load(key: "ReceiptPrinterSettingState.isCommTestOK") ?? DEFAULT.isCommTestOK,
            commTestMessage: repo.load(key: "ReceiptPrinterSettingState.commTestMessage") ?? DEFAULT.commTestMessage)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: ReceiptPrinterSettingState) {
        repo.save(key: "ReceiptPrinterSettingState.bdAddress", value: state.bdAddress)
        repo.save(key: "ReceiptPrinterSettingState.dpi", value: state.dpi)
        repo.save(key: "ReceiptPrinterSettingState.printWidthMM", value: state.printWidthMM)
        repo.save(key: "ReceiptPrinterSettingState.isCommTestExecuted", value: state.isCommTestExecuted)
        repo.save(key: "ReceiptPrinterSettingState.isCommTestOK", value: state.isCommTestOK)
        repo.save(key: "ReceiptPrinterSettingState.commTestMessage", value: state.commTestMessage)
    }
    
    func setCommTestOK() {
        commTestMessage = "OK（最終確認日時：\(Date().description(with: .current))）"
        isCommTestOK = true
        isCommTestExecuted = true
    }
    
    func setCommTestNG() {
        commTestMessage = "NG（最終確認日時：\(Date().description(with: .current))）"
        isCommTestOK = false
        isCommTestExecuted = true
    }
    
    private func clearTestResult() {
        commTestMessage = ""
        isCommTestOK = false
        isCommTestExecuted = false
    }
}
