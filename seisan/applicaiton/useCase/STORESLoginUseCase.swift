//
//  STORESLoginUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/29.
//

import Foundation
import Logging

final class STORESLoginUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// テストは画面側でしか実行できない（STORESPaymentSDKが画面を仕様するため）ため、
    /// 画面で実行した結果を受け取る
    private let result: Bool
    private let state: CregitSettingState
    
    init(result: Bool, state: CregitSettingState) {
        self.result = result
        self.state = state
    }
    
    /// STORESへのログイン結果を通知する
    func exec() {
        log.info("\(type(of: self)): STORES login. result=\(result)")
        
        if result {
            state.setSTORESLoginOK()
        } else {
            state.setSTORESLoginNG()
        }
    }
}
