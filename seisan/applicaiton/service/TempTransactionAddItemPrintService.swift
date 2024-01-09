//
//  TempTransactionAddItemPrintService.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/08/26.
//

import Foundation
import Logging

/// 仮販売追加項目印刷サービス
final class TempTransactionAddItemPrintService {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    let setting: PatientCardSeisanSetting
    let patientCardBilling: PatientCardBilling
    let addItems: [TemporaryTransacitonAddItem]
    let receiptPrintSvc: ReceiptPrintService
    
    /// 処方箋引換券テンプレート
    static let SHOHOSEN_HIKIKAEKEN_TEMPLATE = "「処方箋引換券」\n\n日付：{timestamp}\n\n患者番号：{patientNo}\n\n患者名：{patientName}様\n\n処方箋があります。\n受付窓口までお越しください。\n"
    
    /// 処方箋引換券の日時文字列フォーマット
    static let SHOHOSEN_HIKIKAEKEN_TIMESTAMP_FORMAT = "yyyy年MM月dd日"
    
    init(setting: PatientCardSeisanSetting,
         patientCardBilling: PatientCardBilling,
         addItems: [TemporaryTransacitonAddItem],
         receiptPrintSvc: ReceiptPrintService) {
        self.setting = setting
        self.patientCardBilling = patientCardBilling
        self.addItems = addItems
        self.receiptPrintSvc = receiptPrintSvc
    }
    
    /// 印刷を開始する
    func exec() {
        if setting.isReportAndBillPrintEnable {
            // 診療費請求書兼領収書と診療費明細書の印刷設定が有効な場合
            log.info("print report-and-bill setting enable")
            
            if setting.isReportBetweenBillCutEnable {
                log.info("report-between-bill cut setting enable")
            } else {
                log.info("report-between-bill cut setting disable")
            }
            
            // 診療費請求書兼領収書の印刷テキストを取得
            for addItem in addItems {
                if setting.isReportBetweenBillCutEnable {
                    // 診療費請求書兼領収書と診療費明細書の間を切る場合
                    var textPrintDatas: [TextPrintData] = []
                    
                    // 診療費請求書兼領収書
                    if let reportText = addItem.reportText {
                        textPrintDatas.append(
                            TextPrintData(text: reportText,
                                          font: setting.reportFont,
                                          ryoshuinImage: setting.ryoshuinImage)
                        )
                    }
                    // 診療費明細書
                    if let billText = addItem.billText {
                        textPrintDatas.append(
                            TextPrintData(text: billText,
                                          font: setting.billFont))
                    }
                    
                    // 印刷を実行
                    receiptPrintSvc.printText(textPrintDatas: textPrintDatas)
                } else {
                    // 診療費請求書兼領収書と診療費明細書の間を切らない場合
                    var textPrintDatas: [TextPrintData] = []
                    
                    // 診療費請求書兼領収書
                    if let reportText = addItem.reportText {
                        textPrintDatas.append(
                            TextPrintData(text: reportText,
                                          font: setting.reportFont,
                                          ryoshuinImage: setting.ryoshuinImage)
                        )
                    }
                    // 診療費明細書
                    if let billText = addItem.billText {
                        textPrintDatas.append(
                            TextPrintData(text: billText,
                                          font: setting.billFont))
                    }
                    
                    if textPrintDatas.count > 0 {
                        // 印刷を実行
                        receiptPrintSvc.printContinuousText(
                            continuousTextPrintData: ContinuousTextPrintData(textPrintDatas: textPrintDatas)
                        )
                    }
                }
            }
        }
        
        if setting.isShohosenPrintEnable {
            // 処方箋引換券の印刷設定が有効な場合
            log.info("print shohosen-hikikae-ken setting enable")
            
            // 処方箋引換券の印刷が必要かどうかを取得
            AppState.shared.setIsShohosenPrinted(
                isShohosenPrinted: addItems.contains(where: { $0.prescriptionFlg == true }))
            if AppState.shared.isShohosenPrinted {
                // 処方箋引換券を印刷
                log.info("print shohosen-hikikae-ken required")
                let textPrintDatas = TextPrintData(text: createShohosenHikikaekenPrintText())
                
                // 印刷を実行
                receiptPrintSvc.printText(textPrintDatas: [textPrintDatas])
            }
        }
    }
    
    /// 処方箋引換券の印刷テキストを生成する
    /// - Returns: 処方箋引換券の印刷テキスト
    func createShohosenHikikaekenPrintText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = TempTransactionAddItemPrintService.SHOHOSEN_HIKIKAEKEN_TIMESTAMP_FORMAT
        let timestamp = dateFormatter.string(from: .now)
        
        var printText = TempTransactionAddItemPrintService.SHOHOSEN_HIKIKAEKEN_TEMPLATE
        printText = printText.replacingOccurrences(of: "{timestamp}", with: timestamp, options: .caseInsensitive)
        printText = printText.replacingOccurrences(of: "{patientNo}", with: patientCardBilling.customer!.code, options: .caseInsensitive)
        printText = printText.replacingOccurrences(of: "{patientName}", with: patientCardBilling.customer!.name, options: .caseInsensitive)
        return printText
    }
}
