//
//  AppSetting.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/25.
//

import Foundation

final class AppSetting {
    let barcodeType: AppSetting.BarcodeType
    let patientCardSeisanSetting: PatientCardSeisanSetting?
    let miuProgramSetting: MIUProgram.Setting?
    let autoCashierType: AppSetting.AutoCashierType
    let grolyR08Setting: GrolyR08AutoCashierAdapter.Setting?
    let groly300Setting: Groly300AutoCashierAdapter.Setting?
    let storesSetting: STORES.Setting
    let smaregiSetting: SmaregiPlatformRepository.Setting?
    let tsiSmaregiMedicalSetting: TSISmaregiMedicalRepository.Setting?
    let eposPrinterSetting: EPosPrinter.Setting?
    let orcaSetting: ORCARepository.Setting?
    let viewSetting: ViewSetting
    let customerDisplaySetting: CustomerDisplaySetting
    let httpServerSetting: HTTPServer.Setting?
    let anyLogSetting: AnyLogger.Setting
    let fileLogSetting: FileLogger.Setting
    let isUseReceiptPrinter: Bool
    
    init(barcodeType: AppSetting.BarcodeType,
         patientCardSeisanSetting: PatientCardSeisanSetting?,
         miuProgramSetting: MIUProgram.Setting?,
         autoCashierType: AppSetting.AutoCashierType,
         grolyR08Setting: GrolyR08AutoCashierAdapter.Setting?,
         groly300Setting: Groly300AutoCashierAdapter.Setting?,
         storesSetting: STORES.Setting,
         smaregiSetting: SmaregiPlatformRepository.Setting?,
         tsiSmaregiMedicalSetting: TSISmaregiMedicalRepository.Setting?,
         eposPrinterSetting: EPosPrinter.Setting?,
         orcaSetting: ORCARepository.Setting?,
         viewSetting: ViewSetting,
         customerDisplaySetting: CustomerDisplaySetting,
         httpServerSetting: HTTPServer.Setting?,
         anyLogSetting: AnyLogger.Setting,
         fileLogSetting: FileLogger.Setting,
         isUseReceiptPrinter: Bool) {
        self.barcodeType = barcodeType
        self.patientCardSeisanSetting = patientCardSeisanSetting
        self.miuProgramSetting = miuProgramSetting
        self.autoCashierType = autoCashierType
        self.grolyR08Setting = grolyR08Setting
        self.groly300Setting = groly300Setting
        self.storesSetting = storesSetting
        self.smaregiSetting = smaregiSetting
        self.tsiSmaregiMedicalSetting = tsiSmaregiMedicalSetting
        self.eposPrinterSetting = eposPrinterSetting
        self.orcaSetting = orcaSetting
        self.viewSetting = viewSetting
        self.customerDisplaySetting = customerDisplaySetting
        self.httpServerSetting = httpServerSetting
        self.anyLogSetting = anyLogSetting
        self.fileLogSetting = fileLogSetting
        self.isUseReceiptPrinter = isUseReceiptPrinter
    }
    
    /// 現金決済を利用可能かどうか
    /// - Returns: true：利用可能、false：利用不可
    func isCashUse() -> Bool {
        return autoCashierType != .NoUse
    }
    
    /// クレジット決済を利用可能かどうか
    /// - Returns: true：利用可能、false：利用不可
    func isCreditUse() -> Bool {
        return storesSetting.isStoresUse
    }
}
