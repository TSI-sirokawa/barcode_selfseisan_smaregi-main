//
//  CustomerDisplaySetting.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/09/24.
//

import Foundation

/// カスタマーディスプレイ設定
final class CustomerDisplaySetting {
    // カスタマーディスプレイが有効化どうか
    let isEnable: Bool
    
    init(isEnable: Bool) {
        self.isEnable = isEnable
    }
    
    // カスタマーディスプレイが有効化どうか
    static let ENABLE = SettingValueAttr(
        label: "カスタマーディスプレイを使用する",
        defaultValue: false,
        placeHolder: "カスタマーディスプレイが有効化どうか",
        errorMessage: "true/falseを設定してください。",
        isValidOK: { value in return true })
}
