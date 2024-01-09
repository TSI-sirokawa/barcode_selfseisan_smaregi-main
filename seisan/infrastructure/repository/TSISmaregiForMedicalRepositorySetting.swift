//
//  TSISmaregiForMedicalRepository.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/18.
//

import Foundation

/// TSIクラウドスマレジForMedical 取引履歴+α項目
extension TSISmaregiMedicalRepository {
    final class Setting {
        let contractID: String
        let baseUrl: URL
        let clientID: String
        let clientSecret: String
        
        init(contractID: String, baseUrl: URL, clientID: String, clientSecret: String) {
            self.contractID = contractID
            self.baseUrl = baseUrl
            self.clientID = clientID
            self.clientSecret = clientSecret
        }
        
        static let CONTRACT_ID = SettingValueAttr(
            label: "契約ID",
            defaultValue: "",
            placeHolder: "契約ID",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
        
        static let BASE_URL = SettingValueAttr(
            label: "エンドポイントURL",
            defaultValue: "",
            placeHolder: "例：https://smaregim.jp:4430",
            errorMessage: "入力してください。",
            isValidOK: { value in return URL(string: value) != nil })
        
        static let CLIENT_ID = SettingValueAttr(
            label: "クライアントID",
            defaultValue: "",
            placeHolder: "クライアントID",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
        
        static let CLIENT_SECRET = SettingValueAttr(
            label: "クライアントシークレット",
            defaultValue: "",
            placeHolder: "クライアントシークレット",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
    }
}
