//
//  KesaiSelectUseCase.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/31.
//

import Foundation
import Logging

final class KesaiSelectUseCase {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// 現金決済を選択する
    func selectCashKesai() {
        log.info("\(type(of: self)): cash is selected")
    }
    
    /// クレジット決済を選択する
    func selectCreditKesai() {
        log.info("\(type(of: self)): credit is selected")
    }
    
    /// 決済方法選択をキャンセルする
    func cancel() {
        log.info("\(type(of: self)): cancel")
    }
}
