//
//  SmaregiCommTestUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/29.
//

import Foundation
import Logging

final class SmaregiCommTestUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let state: SmaregiPlatformSettingState
    
    init(state: SmaregiPlatformSettingState) {
        self.state = state
    }
    
    /// スマレジ通信テストを実行する
    func exec() async throws {
        do {
            guard let setting = state.getSettingForCommTest() else {
                throw SettingError("smaregi setting is incomplete")
            }
            
            let smaregiRepo = SmaregiPlatformRepository(setting: setting)
            try await smaregiRepo.execCommTest()
            
            state.setCommTestOK()
            
            log.info("\(type(of: self)): smaregi comm test ok")
        } catch {
            state.setCommTestNG()
            throw error
        }
    }
}
