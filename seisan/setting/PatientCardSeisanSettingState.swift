//
//  PatientCardSeisanSettingState.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/09.
//

import Foundation
import Logging

// 診察券精算設定状態
final class PatientCardSeisanSettingState: SettingCheckProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// 領収印画像ファイルを配置するディレクト名
    static let RYOSHUIN_IMAGE_DIR_NAME = "Ryoshuin"
    
    /// 領収印画像ファイルの名前
    static let RYOSHUIN_IMAGE_FILE_NAME = "ryoshuin.png"
    
    /// 下位X桁削除が下位N桁使用以上の場合のエラーメッセージ
    static let PATIENT_NO_LOWER_DIGITS_AND_REMOVE_LOWER_DIGITS_ERR_MSG = "「下位X桁削除の桁数」には「下位N桁使用の桁数」より小さい値を設定してください。"
    
    /// 数値のみ使用の有効／無効
    var isPatientNoDecimalOnlyEnable: Bool {
        didSet {
            if isPatientNoDecimalOnlyEnable != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 下位N桁使用の有効／無効
    var isPatientNoLowerDigitsEnable: Bool {
        didSet {
            if isPatientNoLowerDigitsEnable != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 下位N桁使用 - 桁数
    var patientNoLowerDigitsStr: String {
        didSet {
            if patientNoLowerDigitsStr != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 下位X桁削除の有効／無効
    var isPatientNoRemoveLowerDigitsEnable: Bool {
        didSet {
            if isPatientNoRemoveLowerDigitsEnable != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 下位X桁削除 - 桁数
    var patientNoRemoveLowerDigitsStr: String {
        didSet {
            if patientNoRemoveLowerDigitsStr != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 前ゼロ削除の有効／無効
    var isPatientNoRemoveZeroPrefixEnable: Bool {
        didSet {
            if isPatientNoRemoveZeroPrefixEnable != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 検索対象期間[月]
    var tempTransPeriodMonthStr: String {
        didSet {
            if tempTransPeriodMonthStr != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 医療システム連携種別
    var healthcareSystemType: PatientCardSeisanSetting.HealthcareSystemType {
        didSet {
            if healthcareSystemType != oldValue {
                validateSetting()
            }
        }
    }
    
    /// ORCA入金処理
    var isORCAPaymentEnable: Bool {
        didSet {
            if isORCAPaymentEnable != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 診療費請求書兼領収書と診療費明細書を印刷するかどうか
    var isReportAndBillPrintEnable: Bool {
        didSet {
            if isReportAndBillPrintEnable != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 領収印を印刷するかどうか
    var isRyoshuinPrintEnable: Bool {
        didSet {
            if isRyoshuinPrintEnable != oldValue {
                validateSetting()
            }
        }
    }
    
    // 領収印画像はファイルを直接扱うため定義しない
    
    /// 診療費請求書兼領収書と診療費明細書の間で紙を切るかどうか
    var isReportBetweenBillCutEnable: Bool {
        didSet {
            if isReportBetweenBillCutEnable != oldValue {
                validateSetting()
            }
        }
    }
    
    /// 処方箋引換券を印刷するかどうか
    var isShohosenPrintEnable: Bool {
        didSet {
            if isShohosenPrintEnable != oldValue {
                validateSetting()
            }
        }
    }
    
    /// レシートプリンタを使用するかどうか
    var isUseReceiptPrinter: Bool {
        return isReportAndBillPrintEnable || isShohosenPrintEnable
    }
    
    /// バリデーション結果
    var isPatientNoDecimalOnlyEnableOK = false
    var isPatientNoLowerDigitsEnableOK = false
    var isPatientNoLowerDigitsStrOK = false
    var isPatientNoRemoveLowerDigitsEnableOK = false
    var isPatientNoRemoveLowerDigitsStrOK = false
    var isPatientNoLowerDigitsAndRemoveLowerDigitsOK = false
    var isPatientNoRemoveZeroPrefixEnableOK = false
    var isTempTransPeriodMonthStrOK = false
    var isHealthcareSystemTypeOK = false
    var isORCAPaymentEnableOK = false
    var isReportAndBillPrintEnableOK = false
    var isRyoshuinPrintEnableOK = false
    var isRyoshuinImageOK = false
    var isReportBetweenBillCutEnableOK = false
    var isShohosenPrintEnableOK = false
    
    /// 通信設定が完了したかどうか
    var isCommSettingOK: Bool {
        return true
    }
    
    /// 設定が完了したかどうか
    var isSettingOK: Bool {
        return isPatientNoDecimalOnlyEnableOK &&
        isPatientNoLowerDigitsEnableOK &&
        isPatientNoLowerDigitsStrOK &&
        isPatientNoRemoveLowerDigitsEnableOK &&
        isPatientNoRemoveLowerDigitsStrOK &&
        isPatientNoLowerDigitsAndRemoveLowerDigitsOK &&
        isPatientNoRemoveZeroPrefixEnableOK &&
        isTempTransPeriodMonthStrOK &&
        isHealthcareSystemTypeOK &&
        isORCAPaymentEnableOK &&
        isReportAndBillPrintEnableOK &&
        isRyoshuinPrintEnableOK &&
        isRyoshuinImageOK &&
        isReportBetweenBillCutEnableOK &&
        isShohosenPrintEnableOK
    }
    /// テストが完了したかどうか
    var isTestOK: Bool {
        return true
    }
    
    /// 設定内容を端的に説明するサマリ
    var shortSummary: String {
        var summary = ""
        if isSettingOK {
            // 患者番号取り扱い設定
            var patientNoDetails: [String] = []
            if isPatientNoDecimalOnlyEnable {
                patientNoDetails.append("数値のみ使用")
            }
            if isPatientNoLowerDigitsEnable {
                patientNoDetails.append("下位\(patientNoLowerDigitsStr)桁使用")
            }
            if isPatientNoRemoveLowerDigitsEnable{
                patientNoDetails.append("下位\(patientNoRemoveLowerDigitsStr)桁削除")
            }
            if isPatientNoRemoveZeroPrefixEnable{
                patientNoDetails.append("前ゼロ削除")
            }
            
            summary += "患者番号（"
            summary += patientNoDetails.count == 0 ? "そのまま" : patientNoDetails.joined(separator: "→")
            summary += "）\n"
            
            summary += "検索対象期間（"
            let tempTransPeriodMonth = Int(tempTransPeriodMonthStr)!
            switch tempTransPeriodMonth {
            case 0:
                summary += "当日のみ"
            case 1:
                summary += "当月月初〜当日"
            default:
                summary += "\(tempTransPeriodMonth-1)カ月前の月初〜当日"
            }
            summary += "）\n"
            
            summary += "\(healthcareSystemType)"
            if healthcareSystemType == .orca {
                if isORCAPaymentEnable {
                    summary += "（入金有効）"
                } else {
                    summary += "（入金無効）"
                }
            }
            summary += "\n"
            
            summary += "診療費請求書兼領収書と診療費明細書印刷（"
            if isReportAndBillPrintEnable {
                summary += "有効:"
                summary += "領収印" + (isRyoshuinPrintEnable ? "あり": "なし")
                summary += ":" + (isReportBetweenBillCutEnable ? "紙カット": "紙連続")
            } else {
                summary += "無効"
            }
            summary += "）\n"
            
            summary += "処方箋引換券印刷（" + (isShohosenPrintEnable ? "有効": "無効") + "）"
        }
        return summary
    }
    
    static let DEFAULT = PatientCardSeisanSettingState(
        isPatientNoDecimalOnlyEnable: PatientCardSeisanSetting.PATIENT_NO_DECIMAL_ONLY_ENABLE.defaultValue,
        isPatientNoLowerDigitsEnable: PatientCardSeisanSetting.PATIENT_NO_LOWER_DIGITS_ENABLE.defaultValue,
        patientNoLowerDigitsStr: "", // 必ず入力してもらうためにデフォルト値は空白にする
        isPatientNoRemoveLowerDigitsEnable: PatientCardSeisanSetting.PATIENT_NO_LOWER_DIGITS_ENABLE.defaultValue,
        patientNoRemoveLowerDigitsStr: "", // 必ず入力してもらうためにデフォルト値は空白にする
        isPatientNoRemoveZeroPrefixEnable: PatientCardSeisanSetting.PATIENT_NO_REMOVE_ZERO_PREFIX_ENABLE.defaultValue,
        tempTransPeriodMonthStr: "", // 必ず入力してもらうためにデフォルト値は空白にする
        healthcareSystemType: PatientCardSeisanSetting.HEALTHCARE_SYSTEM.defaultValue,
        isORCAPaymentEnable: PatientCardSeisanSetting.ORCA_PAYMENT_ENABLE.defaultValue,
        isReportAndBillPrintEnable:  PatientCardSeisanSetting.REPORT_AND_BILL_PRINT_ENABLE.defaultValue,
        isRyoshuinPrintEnable: PatientCardSeisanSetting.RYOSHUIN_PRINT_ENABLE.defaultValue,
        isReportBetweenBillCutEnable: PatientCardSeisanSetting.REPORT_BETWEEN_BILL_CUT_ENABLE.defaultValue,
        isShohosenPrintEnable: PatientCardSeisanSetting.SHOHOSEN_PRINT_ENABLE.defaultValue
    )
    
    init(isPatientNoDecimalOnlyEnable: Bool,
         isPatientNoLowerDigitsEnable: Bool,
         patientNoLowerDigitsStr: String,
         isPatientNoRemoveLowerDigitsEnable: Bool,
         patientNoRemoveLowerDigitsStr: String,
         isPatientNoRemoveZeroPrefixEnable: Bool,
         tempTransPeriodMonthStr: String,
         healthcareSystemType: PatientCardSeisanSetting.HealthcareSystemType,
         isORCAPaymentEnable: Bool,
         isReportAndBillPrintEnable: Bool,
         isRyoshuinPrintEnable: Bool,
         isReportBetweenBillCutEnable: Bool,
         isShohosenPrintEnable: Bool) {
        self.isPatientNoDecimalOnlyEnable = isPatientNoDecimalOnlyEnable
        self.isPatientNoLowerDigitsEnable = isPatientNoLowerDigitsEnable
        self.patientNoLowerDigitsStr = patientNoLowerDigitsStr
        self.isPatientNoRemoveLowerDigitsEnable = isPatientNoRemoveLowerDigitsEnable
        self.patientNoRemoveLowerDigitsStr = patientNoRemoveLowerDigitsStr
        self.isPatientNoRemoveZeroPrefixEnable = isPatientNoRemoveZeroPrefixEnable
        self.tempTransPeriodMonthStr = tempTransPeriodMonthStr
        self.healthcareSystemType = healthcareSystemType
        self.isORCAPaymentEnable = isORCAPaymentEnable
        self.isReportAndBillPrintEnable = isReportAndBillPrintEnable
        self.isRyoshuinPrintEnable = isRyoshuinPrintEnable
        self.isReportBetweenBillCutEnable = isReportBetweenBillCutEnable
        self.isShohosenPrintEnable = isShohosenPrintEnable
        
        validateSetting()
    }
    
    func validateSetting() {
        // 下位N桁使用
        do {
            try PatientCardSeisanSetting.PATIENT_NO_DECIMAL_ONLY_ENABLE.validate(isPatientNoDecimalOnlyEnable)
            isPatientNoDecimalOnlyEnableOK = true
        } catch {
            isPatientNoDecimalOnlyEnableOK = false
        }
        
        // 下位N桁使用
        do {
            try PatientCardSeisanSetting.PATIENT_NO_LOWER_DIGITS_ENABLE.validate(isPatientNoLowerDigitsEnable)
            isPatientNoLowerDigitsEnableOK = true
        } catch {
            isPatientNoLowerDigitsEnableOK = false
        }
        
        isPatientNoLowerDigitsStrOK = true
        if isPatientNoLowerDigitsEnable {
            // 下位N桁使用が有効な場合
            do {
                guard let patientNoLowerDigits = Int(patientNoLowerDigitsStr) else {
                    throw SettingError(PatientCardSeisanSetting.PATIENT_NO_LOWER_DIGITS.errorMessage)
                }
                
                try PatientCardSeisanSetting.PATIENT_NO_LOWER_DIGITS.validate(patientNoLowerDigits)
                isPatientNoLowerDigitsStrOK = true
            } catch {
                isPatientNoLowerDigitsStrOK = false
            }
        }
        
        // 下位X桁削除
        do {
            try PatientCardSeisanSetting.PATIENT_NO_REMOVE_LOWER_DIGITS_ENABLE.validate(isPatientNoLowerDigitsEnable)
            isPatientNoRemoveLowerDigitsEnableOK = true
        } catch {
            isPatientNoRemoveLowerDigitsEnableOK = false
        }
        
        isPatientNoRemoveLowerDigitsStrOK = true
        if isPatientNoRemoveLowerDigitsEnable {
            // 下位X桁削除が有効な場合
            do {
                guard let patientNoRemoveLowerDigits = Int(patientNoRemoveLowerDigitsStr) else {
                    throw SettingError(PatientCardSeisanSetting.PATIENT_NO_REMOVE_LOWER_DIGITS.errorMessage)
                }
                
                try PatientCardSeisanSetting.PATIENT_NO_REMOVE_LOWER_DIGITS.validate(patientNoRemoveLowerDigits)
                isPatientNoRemoveLowerDigitsStrOK = true
            } catch {
                isPatientNoRemoveLowerDigitsStrOK = false
            }
        }
        
        isPatientNoLowerDigitsAndRemoveLowerDigitsOK = true
        if isPatientNoLowerDigitsEnable && isPatientNoRemoveLowerDigitsEnable {
            // 下位N桁使用が有効、かつ、下位X桁削除が有効な場合
            
            if isPatientNoLowerDigitsStrOK && isPatientNoRemoveLowerDigitsStrOK {
                let patientNoLowerDigits = Int(patientNoLowerDigitsStr)!
                let patientNoRemoveLowerDigits = Int(patientNoRemoveLowerDigitsStr)!
                
                if patientNoRemoveLowerDigits < patientNoLowerDigits {
                    // 「下位X桁削除の桁数」が「下位N桁使用の桁数」より小さい場合
                    isPatientNoLowerDigitsAndRemoveLowerDigitsOK = true
                } else {
                    isPatientNoLowerDigitsAndRemoveLowerDigitsOK = false
                }
            }
        }
        
        // 前ゼロ削除
        do {
            try PatientCardSeisanSetting.PATIENT_NO_REMOVE_ZERO_PREFIX_ENABLE.validate(isPatientNoRemoveZeroPrefixEnable)
            isPatientNoRemoveZeroPrefixEnableOK = true
        } catch {
            isPatientNoRemoveZeroPrefixEnableOK = false
        }
        
        // 検索対象期間[月]
        do {
            guard let tempTransPeriodMonth = Int(tempTransPeriodMonthStr) else {
                throw SettingError(PatientCardSeisanSetting.TEMP_TRANS_PERIOD_MONTH.errorMessage)
            }
            
            try PatientCardSeisanSetting.TEMP_TRANS_PERIOD_MONTH.validate(tempTransPeriodMonth)
            isTempTransPeriodMonthStrOK = true
        } catch {
            isTempTransPeriodMonthStrOK = false
        }
        
        // 医療システム連携種別
        do {
            try PatientCardSeisanSetting.HEALTHCARE_SYSTEM.validate(healthcareSystemType)
            isHealthcareSystemTypeOK = true
        } catch {
            isHealthcareSystemTypeOK = false
        }
        
        // ORCAへの入金処理
        do {
            try PatientCardSeisanSetting.ORCA_PAYMENT_ENABLE.validate(isORCAPaymentEnable)
            isORCAPaymentEnableOK = true
        } catch {
            isORCAPaymentEnableOK = false
        }
        
        // 領収印を印刷するかどうか
        do {
            try PatientCardSeisanSetting.RYOSHUIN_PRINT_ENABLE.validate(isRyoshuinPrintEnable)
            isRyoshuinPrintEnableOK = true
        } catch {
            isRyoshuinPrintEnableOK = false
        }
        
        isRyoshuinImageOK = true
        isReportAndBillPrintEnableOK = true
        isReportBetweenBillCutEnableOK = true
        if isReportAndBillPrintEnable {
            // 診療費請求書兼領収書と診療費明細書を印刷する場合
            do {
                try PatientCardSeisanSetting.REPORT_AND_BILL_PRINT_ENABLE.validate(isReportAndBillPrintEnable)
                isReportAndBillPrintEnableOK = true
            } catch {
                isReportAndBillPrintEnableOK = false
            }
            
            if isRyoshuinPrintEnable {
                // 領収印を印刷する場合
                
                // 画像読み込みチェック
                if PatientCardSeisanSettingState.loadRyoshuinImage() != nil {
                    isRyoshuinImageOK = true
                } else {
                    isRyoshuinImageOK = false
                }
            }
            
            // 診療費請求書兼領収書と診療費明細書の間で紙を切るかどうか
            do {
                try PatientCardSeisanSetting.REPORT_BETWEEN_BILL_CUT_ENABLE.validate(isReportBetweenBillCutEnable)
                isReportBetweenBillCutEnableOK = true
            } catch {
                isReportBetweenBillCutEnableOK = false
            }
        }
        
        /// 処方箋引換券を印刷するかどうか
        do {
            try PatientCardSeisanSetting.SHOHOSEN_PRINT_ENABLE.validate(isShohosenPrintEnable)
            isShohosenPrintEnableOK = true
        } catch {
            isShohosenPrintEnableOK = false
        }
    }
    
    func getSetting() -> PatientCardSeisanSetting? {
        
        do {
            // 下位N桁使用の桁数
            var patientNoLowerDigits = 0
            if isPatientNoLowerDigitsEnable {
                // 下位N桁使用が有効な場合
                
                guard let lowerDigits = Int(patientNoLowerDigitsStr) else {
                    throw SettingError(PatientCardSeisanSetting.PATIENT_NO_LOWER_DIGITS.errorMessage)
                }
                
                patientNoLowerDigits = lowerDigits
            }
            
            // 下位X桁削除の桁数
            var patientNoRemoveLowerDigits = 0
            if isPatientNoRemoveLowerDigitsEnable {
                // 下位X桁削除が有効な場合
                
                guard let removeLowerDigits = Int(patientNoRemoveLowerDigitsStr) else {
                    throw SettingError(PatientCardSeisanSetting.PATIENT_NO_REMOVE_LOWER_DIGITS.errorMessage)
                }
                
                patientNoRemoveLowerDigits = removeLowerDigits
            }
            
            if isPatientNoLowerDigitsEnable && isPatientNoRemoveLowerDigitsEnable {
                // 下位N桁使用が有効、かつ、下位X桁削除が有効な場合
                
                let patientNoLowerDigits = Int(patientNoLowerDigitsStr)!
                let patientNoRemoveLowerDigits = Int(patientNoRemoveLowerDigitsStr)!
                
                if patientNoRemoveLowerDigits >= patientNoLowerDigits {
                    // 「下位X桁削除の桁数」が「下位N桁使用の桁数」以上の場合
                    throw SettingError(PatientCardSeisanSettingState.PATIENT_NO_LOWER_DIGITS_AND_REMOVE_LOWER_DIGITS_ERR_MSG)
                }
            }
            
            // 検索対象期間[月]
            guard let tempTransPeriodMonth = Int(tempTransPeriodMonthStr) else {
                throw SettingError(PatientCardSeisanSetting.TEMP_TRANS_PERIOD_MONTH.errorMessage)
            }
            
            var isORCAPaymentEnable = isORCAPaymentEnable
            if healthcareSystemType != .orca {
                // 医療システム連携種別がORCA連携以外の場合はORCA入金処理フラグを下ろす
                isORCAPaymentEnable = false
            }
            
            var ryoshuinImage: UIImage? = nil
            var isReportBetweenBillCutEnable = false
            if isReportAndBillPrintEnable {
                // 診療費請求書兼領収書と診療費明細書を印刷する場合
                
                if isRyoshuinPrintEnable {
                    // 領収印を印刷する場合
                    
                    // 領収印画像を読み込む
                    guard let img = PatientCardSeisanSettingState.loadRyoshuinImage() else {
                        throw SettingError(PatientCardSeisanSetting.RYOSHUIN_IMAGE.errorMessage)
                    }
                    
                    ryoshuinImage = img
                }
                
                isReportBetweenBillCutEnable = self.isReportBetweenBillCutEnable
            }
            
            return try PatientCardSeisanSetting(
                isPatientNoDecimalOnlyEnable: isPatientNoDecimalOnlyEnable,
                isPatientNoLowerDigitsEnable: isPatientNoLowerDigitsEnable,
                patientNoLowerDigits: patientNoLowerDigits,
                isPatientNoRemoveLowerDigitsEnable: isPatientNoRemoveLowerDigitsEnable,
                patientNoRemoveLowerDigits: patientNoRemoveLowerDigits,
                isPatientNoRemoveZeroPrefixEnable: isPatientNoRemoveZeroPrefixEnable,
                tempTransPeriodMonth: tempTransPeriodMonth,
                healthcareSystemType: healthcareSystemType,
                isORCAPaymentEnable: isORCAPaymentEnable,
                isReportAndBillPrintEnable: isReportAndBillPrintEnable,
                ryoshuinImage: ryoshuinImage,
                isReportBetweenBillCutEnable: isReportBetweenBillCutEnable,
                isShohosenPrintEnable: isShohosenPrintEnable)
            
        } catch {
            log.error("\(type(of: self)): create setting eror: \(error)")
            return nil
        }
    }
    
    /// アプリ動作環境の初期化処理を行う
    static func execEnvInit() {
        let dirUrl = getRyoshuinImageDirUrl()
        do {
            try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true)
        } catch {
            print("create ryoshuin dir in document dir error: \(error)")
            return
        }
    }
    
    /// 領収印画像を読み込む
    /// - Returns: 領収印画像　※取得できなかった場合はnilを返す
    static func loadRyoshuinImage() -> UIImage? {
        let fileUrl = getRyoshuinImageFileUrl()
        let img = UIImage(contentsOfFile: fileUrl.path)
        return img
    }
    
    /// 領収印画像ファイルURL（端末内のパス）を取得
    /// - Returns: 領収印画像ファイルURL
    static func getRyoshuinImageFileUrl() -> URL {
        let dirUrl = PatientCardSeisanSettingState.getRyoshuinImageDirUrl()
        let fileUrl = dirUrl.appendingPathComponent(RYOSHUIN_IMAGE_FILE_NAME)
        return fileUrl
    }
    
    /// 領収印画像格納先ディレクトリURL（端末内のパス）を取得
    /// - Returns: 領収印画像格納先ディレクトリURL
    static func getRyoshuinImageDirUrl() -> URL {
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dirUrl = docURL.appendingPathComponent(PatientCardSeisanSettingState.RYOSHUIN_IMAGE_DIR_NAME)
        return dirUrl
    }
    
    static func load(repo: AppSettingRepositoryProtocol) -> PatientCardSeisanSettingState {
        // 医療システム連携設定をUserDefaultsから読み込んでHealthcareSystemTypeに変換
        let healthcareSystemType = PatientCardSeisanSetting.HealthcareSystemType.parse(str: repo.load(key: "PatientCardSeisanSettingState.healthcareSystemType"), defaultValue: PatientCardSeisanSetting.HEALTHCARE_SYSTEM.defaultValue)
        
        // 領収印画像（ryoshuinImageメンバ変数）は画像ファイルを直接扱うためUserDefautlsから読み込まない
        return PatientCardSeisanSettingState(
            isPatientNoDecimalOnlyEnable: repo.load(key: "PatientCardSeisanSettingState.isPatientNoDecimalOnlyEnable") ?? DEFAULT.isPatientNoDecimalOnlyEnable,
            isPatientNoLowerDigitsEnable: repo.load(key: "PatientCardSeisanSettingState.isPatientNoLowerDigitsEnable") ?? DEFAULT.isPatientNoLowerDigitsEnable,
            patientNoLowerDigitsStr: repo.load(key: "PatientCardSeisanSettingState.patientNoLowerDigitsStr") ?? DEFAULT.patientNoLowerDigitsStr,
            isPatientNoRemoveLowerDigitsEnable: repo.load(key: "PatientCardSeisanSettingState.isPatientNoRemoveLowerDigitsEnable") ?? DEFAULT.isPatientNoRemoveLowerDigitsEnable,
            patientNoRemoveLowerDigitsStr: repo.load(key: "PatientCardSeisanSettingState.patientNoRemoveLowerDigitsStr") ?? DEFAULT.patientNoRemoveLowerDigitsStr,
            isPatientNoRemoveZeroPrefixEnable: repo.load(key: "PatientCardSeisanSettingState.isPatientNoRemoveZeroPrefixEnable") ?? DEFAULT.isPatientNoRemoveZeroPrefixEnable,
            tempTransPeriodMonthStr: repo.load(key: "PatientCardSeisanSettingState.tempTransPeriodMonthStr") ?? DEFAULT.tempTransPeriodMonthStr,
            healthcareSystemType: healthcareSystemType,
            isORCAPaymentEnable: repo.load(key: "PatientCardSeisanSettingState.isORCAPaymentEnable") ?? DEFAULT.isORCAPaymentEnable,
            isReportAndBillPrintEnable: repo.load(key: "PatientCardSeisanSettingState.isReportAndBillPrintEnable") ?? DEFAULT.isReportAndBillPrintEnable,
            isRyoshuinPrintEnable: repo.load(key: "PatientCardSeisanSettingState.isRyoshuinPrintEnable") ?? DEFAULT.isRyoshuinPrintEnable,
            isReportBetweenBillCutEnable: repo.load(key: "PatientCardSeisanSettingState.isReportBetweenBillCutEnable") ?? DEFAULT.isReportBetweenBillCutEnable,
            isShohosenPrintEnable: repo.load(key: "PatientCardSeisanSettingState.isShohosenPrintEnable") ?? DEFAULT.isShohosenPrintEnable
            )
    }
    
    static func save(repo: AppSettingRepositoryProtocol, state: PatientCardSeisanSettingState) {
        repo.save(key: "PatientCardSeisanSettingState.isPatientNoDecimalOnlyEnable", value: state.isPatientNoDecimalOnlyEnable)
        repo.save(key: "PatientCardSeisanSettingState.isPatientNoLowerDigitsEnable", value: state.isPatientNoLowerDigitsEnable)
        repo.save(key: "PatientCardSeisanSettingState.patientNoLowerDigitsStr", value: state.patientNoLowerDigitsStr)
        repo.save(key: "PatientCardSeisanSettingState.isPatientNoRemoveLowerDigitsEnable", value: state.isPatientNoRemoveLowerDigitsEnable)
        repo.save(key: "PatientCardSeisanSettingState.patientNoRemoveLowerDigitsStr", value: state.patientNoRemoveLowerDigitsStr)
        repo.save(key: "PatientCardSeisanSettingState.isPatientNoRemoveZeroPrefixEnable", value: state.isPatientNoRemoveZeroPrefixEnable)
        repo.save(key: "PatientCardSeisanSettingState.tempTransPeriodMonthStr", value: state.tempTransPeriodMonthStr)
        repo.save(key: "PatientCardSeisanSettingState.healthcareSystemType", value: state.healthcareSystemType.rawValue)
        repo.save(key: "PatientCardSeisanSettingState.isORCAPaymentEnable", value: state.isORCAPaymentEnable)
        repo.save(key: "PatientCardSeisanSettingState.isReportAndBillPrintEnable", value: state.isReportAndBillPrintEnable)
        repo.save(key: "PatientCardSeisanSettingState.isRyoshuinPrintEnable", value: state.isRyoshuinPrintEnable)
        // 領収印画像（ryoshuinImageメンバ変数）は画像ファイルを直接扱うためUserDefautlsには保存しない
        repo.save(key: "PatientCardSeisanSettingState.isReportBetweenBillCutEnable", value: state.isReportBetweenBillCutEnable)
        repo.save(key: "PatientCardSeisanSettingState.isShohosenPrintEnable", value: state.isShohosenPrintEnable)
    }
}
