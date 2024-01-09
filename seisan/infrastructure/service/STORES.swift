//
//  STORES.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/27.
//

import Foundation

/// クレジット支払いはSTORESのクレジット端末とクラウドサービスを利用する
///     →STORESPaymentSDKを介して決済を行う
///         →SDK内に画面表示が含まれるため、実装は「CreditKesaiView」で行なっている
///         →ここでは設定のみ定義する
final class STORES {
    final class Setting {
        let isStoresUse: Bool
        
        static let STORES_USE_DEFAULT = SettingValueAttr(
            label: "STORES決済を利用する",
            defaultValue: false,
            placeHolder: "",
            errorMessage: "設定してください。",
            isValidOK: { value in return true })
        
        // 現バージョンでは設定値なし
        init(isStoresUse: Bool) {
            self.isStoresUse = isStoresUse
        }
    }
}
