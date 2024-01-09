//
//  TSISmaregiMedicalCommTestUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/03/26.
//

import Foundation
import Logging

final class TSISmaregiMedicalCommTestUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let state: TSISmaregiMedicalSettingState
    
    init(state: TSISmaregiMedicalSettingState) {
        self.state = state
    }
    
    /// 通信テストを実行する
    func exec() async throws {
        do {
            guard let setting = state.getSetting() else {
                throw SettingError("tsi smaregi for medical setting is incomplete")
            }
            
            let repo = TSISmaregiMedicalRepository(setting: setting)
            try await repo.execCommTest()
            
            state.setCommTestOK()
            
            log.info("\(type(of: self)): tsi smaregi for medical comm test ok")
        } catch {
            state.setCommTestNG()
            throw error
        }
    }
}
