//
//  ORCACommTestUseCase.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/04/10.
//

import Foundation

import Foundation
import Logging

final class ORCACommTestUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let state: ORCASettingState
    
    init(state: ORCASettingState) {
        self.state = state
    }
    
    /// 通信テストを実行する
    func exec() async throws {
        do {
            guard let setting = state.getSettingForCommTest() else {
                throw SettingError("orca setting is incomplete")
            }
            
            let repo = ORCARepository(setting: setting)
            try await repo.execCommTest()
            
            state.setCommTestOK()
            
            log.info("\(type(of: self)): orca comm test ok")
        } catch {
            state.setCommTestNG()
            throw error
        }
    }
}
