//
//  GrolyR08CommTestUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/29.
//

import Foundation
import Logging

final class GrolyR08CommTestUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let state: GrolyR08AutoCashierAdapterSettingState
    
    init(state: GrolyR08AutoCashierAdapterSettingState) {
        self.state = state
    }
    
    func exec() async throws {
        do {
            guard let setting = state.getSetting() else {
                throw SettingError("grolyR08 setting is incomplete")
            }
            
            let repo = GrolyR08AutoCashierAdapter(setting: setting)
            try await repo.execCommTest()
            
            state.setCommTestOK()
            
            log.info("\(type(of: self)): grolyR08 test ok")
        } catch {
            state.setCommTestNG()
            throw error
        }
    }
}
