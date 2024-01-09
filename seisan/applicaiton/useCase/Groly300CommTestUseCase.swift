//
//  Groly300CommTestUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/29.
//

import Foundation
import Logging

final class Groly300CommTestUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let state: Groly300AutoCashierAdapterSettingState
    
    init(state: Groly300AutoCashierAdapterSettingState) {
        self.state = state
    }
    
    func exec() async throws {
        do {
            guard let setting = state.getSetting() else {
                throw SettingError("groly300 setting is incomplete")
            }
            
            let repo = Groly300AutoCashierAdapter(setting: setting)
            try await repo.execCommTest()
            
            state.setCommTestOK()
            
            log.info("\(type(of: self)): groly300 test ok")
        } catch {
            state.setCommTestNG()
            throw error
        }
    }
}
