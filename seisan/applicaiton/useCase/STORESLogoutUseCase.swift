//
//  STORESLogoutUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/02/03.
//

import Foundation
import Logging

final class STORESLogoutUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// テストは画面側で実行するため、画面で実行した結果を処理する
    private let state: CregitSettingState
    
    init(state: CregitSettingState) {
        self.state = state
    }
    
    /// STORESへのログアウト結果を通知する
    func exec() {
        log.info("\(type(of: self)): STORES logiout ok")
        
        state.setSTORESLogoutOK()
    }
}
