//
//  PatientCardSeisanSetting.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/06/08.
//

import Foundation

/// 診察券精算設定
final class PatientCardSeisanSetting: Codable {
    /// 数値のみ使用の有効／無効
    let isPatientNoDecimalOnlyEnable: Bool
    /// 下位N桁使用の有効／無効
    let isPatientNoLowerDigitsEnable: Bool
    /// 下位N桁使用 - 桁数
    let patientNoLowerDigits: Int
    /// 下位X桁削除の有効／無効
    let isPatientNoRemoveLowerDigitsEnable: Bool
    /// 下位X桁削除 - 桁数
    let patientNoRemoveLowerDigits: Int
    /// 前ゼロ削除の有効／無効
    let isPatientNoRemoveZeroPrefixEnable: Bool
    /// 仮販売データの検索対象期間[月]（0: 当日のみ、1〜: (N-1)カ月前の月初から当日まで）
    let tempTransPeriodMonth: Int
    /// 医療システム連携種別
    let healthcareSystemType: PatientCardSeisanSetting.HealthcareSystemType
    /// ORCAへの入金を行うかどうか
    let isORCAPaymentEnable: Bool
    /// 診療費請求書兼領収書と診療費明細書を印刷するかどうか
    let isReportAndBillPrintEnable: Bool
    /// 診療費請求書兼領収書の領収印画像
    var ryoshuinImage: UIImage?
    /// 診療費請求書兼領収書と診療費明細書の間で紙を切るかどうか
    let isReportBetweenBillCutEnable: Bool
    /// 処方箋引換券の印刷が有効化どうか
    let isShohosenPrintEnable: Bool
    /// 診療費請求書兼領収書の印刷フォント（固定）
    let reportFont: String
    /// 診療費明細書の印刷フォント（固定）
    let billFont: String
    
    /// Codableプロトコルに対応できないUIImageを省くためにCodingKeyを定義
    enum CodingKeys: String, CodingKey {
        case isPatientNoDecimalOnlyEnable
        case isPatientNoLowerDigitsEnable
        case patientNoLowerDigits
        case isPatientNoRemoveLowerDigitsEnable
        case patientNoRemoveLowerDigits
        case isPatientNoRemoveZeroPrefixEnable
        case tempTransPeriodMonth
        case healthcareSystemType
        case isORCAPaymentEnable
        case isReportAndBillPrintEnable
        // UIImageはCodableプロトコルに対応できないためryoshuinImageは定義しない
        case isReportBetweenBillCutEnable
        case isShohosenPrintEnable
        case reportFont
        case billFont
    }
    
    init(isPatientNoDecimalOnlyEnable: Bool,
         isPatientNoLowerDigitsEnable: Bool,
         patientNoLowerDigits: Int,
         isPatientNoRemoveLowerDigitsEnable: Bool,
         patientNoRemoveLowerDigits: Int,
         isPatientNoRemoveZeroPrefixEnable: Bool,
         tempTransPeriodMonth: Int,
         healthcareSystemType: PatientCardSeisanSetting.HealthcareSystemType,
         isORCAPaymentEnable: Bool,
         isReportAndBillPrintEnable: Bool,
         ryoshuinImage: UIImage?,
         isReportBetweenBillCutEnable: Bool,
         isShohosenPrintEnable: Bool) throws {
        self.isPatientNoDecimalOnlyEnable = isPatientNoDecimalOnlyEnable
        self.isPatientNoLowerDigitsEnable = isPatientNoLowerDigitsEnable
        self.patientNoLowerDigits = patientNoLowerDigits
        self.isPatientNoRemoveLowerDigitsEnable = isPatientNoRemoveLowerDigitsEnable
        self.patientNoRemoveLowerDigits = patientNoRemoveLowerDigits
        self.isPatientNoRemoveZeroPrefixEnable = isPatientNoRemoveZeroPrefixEnable
        self.tempTransPeriodMonth = tempTransPeriodMonth
        self.healthcareSystemType = healthcareSystemType
        self.isORCAPaymentEnable = isORCAPaymentEnable
        self.isReportAndBillPrintEnable = isReportAndBillPrintEnable
        self.ryoshuinImage = ryoshuinImage
        self.isReportBetweenBillCutEnable = isReportBetweenBillCutEnable
        self.isShohosenPrintEnable = isShohosenPrintEnable
        
        // 数値のみ使用の有効／無効
        try PatientCardSeisanSetting.PATIENT_NO_DECIMAL_ONLY_ENABLE.validate(isPatientNoDecimalOnlyEnable)
        
        // 下位N桁使用の有効／無効
        try PatientCardSeisanSetting.PATIENT_NO_LOWER_DIGITS_ENABLE.validate(isPatientNoLowerDigitsEnable)
        
        if isPatientNoLowerDigitsEnable {
            // 下位N桁使用が有効な場合
            try PatientCardSeisanSetting.PATIENT_NO_LOWER_DIGITS.validate(patientNoLowerDigits)
        }
        
        // 下位X桁削除の有効／無効
        try PatientCardSeisanSetting.PATIENT_NO_REMOVE_LOWER_DIGITS_ENABLE.validate(isPatientNoRemoveLowerDigitsEnable)
        
        if isPatientNoRemoveLowerDigitsEnable {
            // 下位X桁削除が有効な場合
            try PatientCardSeisanSetting.PATIENT_NO_REMOVE_LOWER_DIGITS.validate(patientNoRemoveLowerDigits)
        }
        
        // 前ゼロ削除の有効／無効
        try PatientCardSeisanSetting.PATIENT_NO_REMOVE_ZERO_PREFIX_ENABLE.validate(isPatientNoRemoveZeroPrefixEnable)
        
        try PatientCardSeisanSetting.TEMP_TRANS_PERIOD_MONTH.validate(tempTransPeriodMonth)
        try PatientCardSeisanSetting.HEALTHCARE_SYSTEM.validate(healthcareSystemType)
        try PatientCardSeisanSetting.ORCA_PAYMENT_ENABLE.validate(isORCAPaymentEnable)
        
        if isReportAndBillPrintEnable {
            // 診療費請求書兼領収書と診療費明細書の印刷設定が有効な場合
            
            try PatientCardSeisanSetting.REPORT_AND_BILL_PRINT_ENABLE.validate(isReportAndBillPrintEnable)
            
            if let ryoshuinImage = ryoshuinImage {
                // 領収印を印刷する場合
                try PatientCardSeisanSetting.RYOSHUIN_IMAGE.validate(ryoshuinImage)
            }
            
            try PatientCardSeisanSetting.REPORT_BETWEEN_BILL_CUT_ENABLE.validate(isReportBetweenBillCutEnable)
        }
        try PatientCardSeisanSetting.SHOHOSEN_PRINT_ENABLE.validate(isShohosenPrintEnable)
        
        // フォントは固定
        reportFont = "EPOS2_FONT_A"
        billFont = "EPOS2_FONT_B"
    }
    
    // 数値のみ使用の有効／無効
    static let PATIENT_NO_DECIMAL_ONLY_ENABLE = SettingValueAttr(
        label: "数値のみ使用",
        defaultValue: false,
        placeHolder: "数値のみ使用が有効かどうか",
        errorMessage: "true/falseを設定してください。",
        isValidOK: { value in return true })
    
    // 下位N桁使用の有効／無効
    static let PATIENT_NO_LOWER_DIGITS_ENABLE = SettingValueAttr(
        label: "下位N桁使用",
        defaultValue: false,
        placeHolder: "下位N桁使用が有効かどうか",
        errorMessage: "true/falseを設定してください。",
        isValidOK: { value in return true })
    
    // 下位N桁使用 - 桁数
    static let PATIENT_NO_LOWER_DIGITS = SettingValueAttr(
        label: "桁数",
        defaultValue: 0,
        placeHolder: "例：5",
        errorMessage: "1以上の値を入力してください。",
        isValidOK: { value in return value >= 1 })
    
    // 下位X桁削除の有効／無効
    static let PATIENT_NO_REMOVE_LOWER_DIGITS_ENABLE = SettingValueAttr(
        label: "下位X桁削除",
        defaultValue: false,
        placeHolder: "下位X桁削除が有効かどうか",
        errorMessage: "true/falseを設定してください。",
        isValidOK: { value in return true })
    
    // 下位X桁削除 - 桁数
    static let PATIENT_NO_REMOVE_LOWER_DIGITS = SettingValueAttr(
        label: "桁数",
        defaultValue: 0,
        placeHolder: "例：1",
        errorMessage: "1以上の値を入力してください。",
        isValidOK: { value in return value >= 1 })
    
    // 前ゼロ削除の有効／無効
    static let PATIENT_NO_REMOVE_ZERO_PREFIX_ENABLE = SettingValueAttr(
        label: "前ゼロ削除",
        defaultValue: false,
        placeHolder: "前ゼロ削除が有効かどうか",
        errorMessage: "true/falseを設定してください。",
        isValidOK: { value in return true })
    
    static let TEMP_TRANS_PERIOD_MONTH = SettingValueAttr(
        label: "検索対象期間[月]",
        defaultValue: 0,
        placeHolder: "0:当日のみ / 1〜:(N-1)カ月前の月初から当日まで",
        errorMessage: "0以上の値を入力してください。例：0",
        isValidOK: { value in return value >= 0 })
    
    static let HEALTHCARE_SYSTEM = SettingValueAttr(
        label: "連携種別選択",
        defaultValue: PatientCardSeisanSetting.HealthcareSystemType.orca,
        placeHolder: "",
        errorMessage: "値を入力してください",
        isValidOK: { value in return true })
    
    static let ORCA_PAYMENT_ENABLE = SettingValueAttr(
        label: "ORCA入金処理",
        defaultValue: true,
        placeHolder: "ORCAへの入金処理を行うかどうか",
        errorMessage: "true/falseを設定してください。",
        isValidOK: { value in return true })
    
    static let REPORT_AND_BILL_PRINT_ENABLE = SettingValueAttr(
        label: "診療費請求書兼領収書と診療費明細書を印刷する",
        defaultValue: true,
        placeHolder: "診療費請求書兼領収書と診療費明細書を印刷するかどうか",
        errorMessage: "true/falseを設定してください。",
        isValidOK: { value in return true })
    
    static let RYOSHUIN_PRINT_ENABLE = SettingValueAttr(
        label: "領収印を印刷する",
        defaultValue: true,
        placeHolder: "領収印を印刷するかどうか",
        errorMessage: "true/falseを設定してください。",
        isValidOK: { value in return true })
    
    static let RYOSHUIN_IMAGE = SettingValueAttr(
        label: "領収印画像",
        defaultValue: UIImage(),
        placeHolder: "領収印画像",
        errorMessage: "領収印画像を設定してください。",
        isValidOK: { value in return value.size.width > 0 && value.size.height > 0 })
    
    static let REPORT_BETWEEN_BILL_CUT_ENABLE = SettingValueAttr(
        label: "診療費請求書兼領収書と診療費明細書の間で紙を切る",
        defaultValue: true,
        placeHolder: "診療費請求書兼領収書と診療費明細書の間で紙を切るかどうか",
        errorMessage: "true/falseを設定してください。",
        isValidOK: { value in return true })
    
    static let SHOHOSEN_PRINT_ENABLE = SettingValueAttr(
        label: "処方箋引換券を印刷する",
        defaultValue: true,
        placeHolder: "処方箋引換券を印刷するかどうか",
        errorMessage: "true/falseを設定してください。",
        isValidOK: { value in return true })
    
    /// 仮販売データの検索対象期間（From〜To）を生成する
    /// - Returns:検索対象期間期間（From〜To）
    func getTempTransFromTo() throws -> (Date, Date) {
        let now = Date.now
        
        // Toを計算
        // ・当日の23時59分59秒を指定
        guard let to = now.hhmmdd(23, 59, 59) else {
            throw SettingError.dateCalc("'to' calc 23:59:59 error. date=\(now)")
        }
        
        // Fromを計算
        // ・From日の0時0分0秒を指定
        if tempTransPeriodMonth == 0 {
            // 0の場合、当日のみとする
            guard let from = now.hhmmdd(0, 0, 0) else {
                throw SettingError.dateCalc("'from' calc 00:00:00 error. date=\(now)")
            }
            
            return (from, to)
        }
        
        // 1以上の場合、(N-1)カ月前の月初から当日まで
        let offsetMonth = -(tempTransPeriodMonth - 1)
        guard let from = now.firstDayOfMonth(offsetMonth) else {
            throw SettingError.dateCalc("'from' calc firstDayOfMonth error. base=\(now), offsetMonth=\(offsetMonth)")
        }
        
        return (from, to)
    }
    
    /// 仮販売データのメモ欄のフォーマット種別を取得する
    /// - Returns: フォーマット種別
    func getTempTransIntegrationMemoType() -> SmaregiPlatformRepository.IntegrationMemoType {
        switch healthcareSystemType {
        case .orca:
            // ORCA連携
            return .orca
        case .miu, .csv:
            // MIU連携／CSV連携
            return .csv
        }
    }
}

extension PatientCardSeisanSetting {
    /// 医療システム連携種別
    enum HealthcareSystemType: String, CaseIterable, Codable, CustomStringConvertible {
        /// ORCA連携
        ///  　→仮販売データのメモ欄のフォーマットがORCA連携専用
        ///  　→ORCAへの入金登録処理も可能
        case orca
        /// MIU連携
        ///  　→仮販売データのメモ欄のフォーマットはCSV連携と同じだが、
        ///  　　MUI連携プログラムとの連携がある
        case miu
        /// CSV連携
        ///  　→仮販売データのメモ欄のフォーマットがCSV連携で共通
        case csv
        
        var description: String {
            switch self {
            case .orca:
                return "ORCA連携"
            case .miu:
                return "MIU連携"
            case .csv:
                return "CSV連携"
            }
        }
        
        static func parse(str: String?, defaultValue: HealthcareSystemType) -> HealthcareSystemType {
            guard let str = str else {
                return defaultValue
            }
            
            let ret = HealthcareSystemType(rawValue: str) ?? defaultValue
            return ret
        }
    }
}

extension PatientCardSeisanSetting {
    enum SettingError: Error {
        case dateCalc(String)
    }
}
