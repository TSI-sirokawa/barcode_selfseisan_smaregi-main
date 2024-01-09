//
//  SelectedBarcodeState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/03/14.
//

import Foundation

/// バーコード設定状態
final class SelectedBarcodeState: SettingCheckProtocol {
    var selectedType: AppSetting.BarcodeType {
        didSet {
            onChanged(selectedType)
        }
    }
    
    var onChanged: (AppSetting.BarcodeType) -> Void = {_ in }
    
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
        return selectedType.description
    }
    
    static let DEFAULT = SelectedBarcodeState(selectedType: .ReceiptBarcord)
    
    init(selectedType: AppSetting.BarcodeType) {
        self.selectedType = selectedType
    }
    
    func validateSetting() {
        // 何もしない
    }
    
    func getSetting() -> AppSetting.BarcodeType {
        return selectedType
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> SelectedBarcodeState {
        let  selectedType = AppSetting.BarcodeType.parse(
            str: repo.load(key: "SelectedBarcodeState.selectedType"),
            defaultValue: .ReceiptBarcord)
        
        return SelectedBarcodeState(
            selectedType: selectedType)
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: SelectedBarcodeState) {
        repo.save(key: "SelectedBarcodeState.selectedType", value: state.selectedType.rawValue)
    }
}
