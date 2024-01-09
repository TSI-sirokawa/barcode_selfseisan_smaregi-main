//
//  SelectedAutoCashierState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/28.
//

import Foundation

final class SelectedAutoCashierState: SettingCheckProtocol {
    var selectedType: AppSetting.AutoCashierType {
        didSet {
            onChanged(selectedType)
        }
    }
    
    var onChanged: (AppSetting.AutoCashierType) -> Void = {_ in }
    
    var isSettingOK: Bool {
        // enum型で定義したつり銭機種別を扱うだけなので、設定完了のみ
        return true
    }
    
    var isTestOK: Bool {
        // enum型で定義したつり銭機種別を扱うだけなので、テスト完了のみ
        return true
    }
    
    /// 設定内容を端的に説明するサマリ
    var shortSummary: String {
        return ""
    }
    
    static let DEFAULT = SelectedAutoCashierState(selectedType: .GrolyR08)
    
    init(selectedType: AppSetting.AutoCashierType) {
        self.selectedType = selectedType
    }
    
    func validateSetting() {
        // 何もしない
    }
    
    func getSetting() -> AppSetting.AutoCashierType {
        return selectedType
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> SelectedAutoCashierState {
        let  selectedType = AppSetting.AutoCashierType.parse(
            str: repo.load(key: "SelectedAutoCashier"),
            defaultValue: .GrolyR08)
        
        return SelectedAutoCashierState(
            selectedType: selectedType)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: SelectedAutoCashierState) {
        repo.save(key: "SelectedAutoCashier", value: state.selectedType.rawValue)
    }
}
