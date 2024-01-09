//
//  MIUProgramTestUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/08/02.
//

import Foundation
import Logging

final class MIUProgramTestUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let state: MIUProgramSettingState
    
    init(state: MIUProgramSettingState) {
        self.state = state
    }
    
    func exec() async throws {
        do {
            guard let setting = state.getSetting() else {
                throw SettingError("miu program setting is incomplete")
            }
            
            let repo = MIUProgram(setting: setting)
            try await repo.execCommTest()
            
            state.setCommTestOK()
            
            log.info("\(type(of: self)): miu program test ok")
        } catch {
            state.setCommTestNG()
            throw error
        }
    }
}
