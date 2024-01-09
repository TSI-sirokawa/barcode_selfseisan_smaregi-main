//
//  ReceiptPrintTestUseCase.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/03.
//

import Foundation
import Logging

final class ReceiptPrintTestUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let state: ReceiptPrinterSettingState
    
    init(state: ReceiptPrinterSettingState) {
        self.state = state
    }
    
    func exec() async throws {
        do {
            guard let setting = state.getSetting() else {
                throw SettingError("receipt setting is incomplete")
            }
            
            let printer = EPosPrinter(setting: setting)
            printer.initialize()
            defer { printer.close() }
            
            try await printer.execCommTest()
            
            state.setCommTestOK()
            
            log.info("\(type(of: self)): receipt print test comm ok")
        } catch {
            state.setCommTestNG()
            throw error
        }
    }
}
