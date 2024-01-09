//
//  SmaregiPlatformRepositorySetting.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/24.
//

import Foundation

extension SmaregiPlatformRepository {
    final class Setting {
        /// 契約ID
        let contractID: String
        /// アクセストークンAPIのエンドポイントURL
        let accessTokenBaseUrl: URL
        /// クライアントID
        let clientID: String
        /// クライアントシークレット
        let clientSecret: String
        /// プラットフォームAPIのエンドポイントURL
        let platformAPIBaseUrl: URL
        /// 最大検索期間[日]/リクエスト
        let maxDayPerRequest: Int
        /// 店舗ID
        let storeID: Int?
        /// 端末ID
        let terminalID: Int
        /// 商品ID
        let productID: Int64?
        
        init(contractID: String,
             accessTokenBaseUrl: URL,
             clientID: String,
             clientSecret: String,
             platformAPIBaseUrl: URL,
             maxDayPerRequest: Int,
             storeID: Int?,
             terminalID: Int,
             productID: Int64?) throws {
            self.contractID = contractID
            self.accessTokenBaseUrl = accessTokenBaseUrl
            self.clientID = clientID
            self.clientSecret = clientSecret
            self.platformAPIBaseUrl = platformAPIBaseUrl
            self.maxDayPerRequest = maxDayPerRequest
            self.storeID = storeID
            self.terminalID = terminalID
            self.productID = productID
            
            try Setting.CONTRACT_ID.validate(contractID)
            // アクセストークンAPIのエンドポイントURLは、URLオブジェクトとして正しいものしか受け取れないためチェックしない
            try Setting.CLIENT_ID.validate(clientID)
            try Setting.CLIENT_SECRET.validate(clientSecret)
            // プラットフォームAPIのエンドポイントURLは、URLオブジェクトとして正しいものしか受け取れないためチェックしない
            try Setting.MAX_DAY_PER_REQUEST.validate(maxDayPerRequest)
            if storeID != nil {
                try Setting.STORE_ID.validate(storeID!)
            }
            try Setting.TERMINAL_ID.validate(terminalID)
            if productID != nil {
                try Setting.PRODUCT_ID.validate(productID!)
            }
        }
        
        static let CONTRACT_ID = SettingValueAttr(
            label: "契約ID",
            defaultValue: "",
            placeHolder: "契約ID",
            errorMessage: "入力してください。",
            isValidOK: { value in return value != "" })
        
        static let ACCESS_TOKEN_BASE_URL = SettingValueAttr(
            label: "アクセストークンAPIのエンドポイントURL",
            defaultValue: "",
            placeHolder: "例：https://id.smaregi.jp",
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
        
        static let PLATFORM_API_BASE_URL = SettingValueAttr(
            label: "プラットフォームAPIのエンドポイントURL",
            defaultValue: "",
            placeHolder: "例：https://api.smaregi.jp",
            errorMessage: "入力してください。",
            isValidOK: { value in return URL(string: value) != nil })
        
        static let MAX_DAY_PER_REQUEST = SettingValueAttr(
            label: "最大検索期間[日]/リクエスト\n※スマレジ仕様",
            defaultValue: 31,
            placeHolder: "例：31",
            errorMessage: "1〜31の値を入力してください。",
            isValidOK: { value in return (value >= 1 && value <= 31) })
        
        static let STORE_ID = SettingValueAttr(
            label: "店舗ID",
            defaultValue: 1,
            placeHolder: "例：1",
            errorMessage: "1以上の値を入力してください。",
            isValidOK: { value in return value >= 1 })
        
        static let TERMINAL_ID = SettingValueAttr(
            label: "端末ID",
            defaultValue: 1,
            placeHolder: "例：1",
            errorMessage: "1以上の値を入力してください。",
            isValidOK: { value in return value >= 1 })
        
        static let PRODUCT_ID = SettingValueAttr(
            label: "商品ID",
            defaultValue: Int64(1),
            placeHolder: "例：8000001",
            errorMessage: "1以上の値を入力してください。",
            isValidOK: { value in return value >= 1 })
    }
}

