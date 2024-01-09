//
//  TempTransAddItemBackgroundGetService.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/08/26.
//

import Foundation
import Logging

/// 仮販売追加項目取得サービス
final class TempTransAddItemBackgroundGetService {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    let setting: PatientCardSeisanSetting
    let patientCardBilling: PatientCardBilling
    let tempTransAddItemRepo: TemporaryTransacitonAddItemProtocol
    
    private(set) var occuredErr: Error? = nil
    private(set) var addItems : [TemporaryTransacitonAddItem]? = nil
    
    /// 最大リトライ数
    static let RETRY_COUNT = 3
    
    init(setting: PatientCardSeisanSetting,
         patientCardBilling: PatientCardBilling,
         tempTransAddItemRepo: TemporaryTransacitonAddItemProtocol) {
        self.setting = setting
        self.patientCardBilling = patientCardBilling
        self.tempTransAddItemRepo = tempTransAddItemRepo
    }
    
    // バックグラウンド取得を開始する
    func start() {
        Task {
            var retryCount = 0
            while true {
                do {
                    // 仮販売追加項目取得
                    let procStart = Date()
                    addItems = try await tempTransAddItemRepo.loadTempTransAddItems(tempTranses: patientCardBilling.tempTranses)
                    let procElapsed = Date().timeIntervalSince(procStart)
                    log.info("\(type(of: self)): get temporary transaction add items ok. elapsed=\(procElapsed)")
                } catch {
                    if retryCount >= TempTransAddItemBackgroundGetService.RETRY_COUNT {
                        // リトライ最大数に達した場合
                        occuredErr = error
                        log.error("\(type(of: self)): get temporary transaction add items: \(error)")
                        break
                    }
                    retryCount += 1
                    
                    // 取得に失敗したら少し待ってからリトライ
                    do {
                        try await Task.sleep(for: .milliseconds(1000))
                    } catch {}
                    continue
                }
                
                // 取得に成功したらループから抜ける
                break
            }
        }
    }
    
    /// 結果を取得する
    /// - Returns: 仮販売追加項目
    func getResult() throws -> [TemporaryTransacitonAddItem]? {
        if let occuredErr = occuredErr {
            throw occuredErr
        }
        
        return addItems
    }
    
    /// 結果を取得する
    /// - Returns: 仮販売追加項目
    func getMustResult() -> [TemporaryTransacitonAddItem] {
        return addItems!
    }
}
