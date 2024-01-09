//
//  KesaiUseCaseProtocol.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/20.
//

import Foundation

/// 決済ユースケースプロトコル
protocol KesaiUseCaseProtocol {
    /// 決済を開始する
    func start()
    
    /// 入金を確定する
    func fix()
    
    /// 決済をキャンセルする
    func cancel()
    
    /// 決済エラーから復帰する
    /// ・エラー発生中のみ有効
    func errorRestore()
    
    /// エラーキャンセルを要求する
    /// ・エラー発生中のみ有効
    func errorCancel()
}
