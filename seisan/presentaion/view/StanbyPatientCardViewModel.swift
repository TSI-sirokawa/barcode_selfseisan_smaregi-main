//
//  StanbyPatientCardViewModel.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/22.
//

import Foundation
import SwiftUI
import Logging

/// 診察券バーコード用待機画面ビューモデル
final class StanbyPatientCardViewModel: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState: AppState = AppState.shared
    /// アプリ設定取得サービス
    private let appSetGetSvc: AppSettingGetService = AppSettingGetService.shared
    /// 待機画面表示ステータス
    @Published private(set) var viewStatus = ViewStatusType.`init` {
        didSet {
            switch viewStatus {
            case .`init`:
                isIndicatorActive = false
            case .wait:
                isIndicatorActive = false
            case .barcord:
                isIndicatorActive = true
            case .comm:
                isIndicatorActive = true
            case .refund:
                isIndicatorActive = false
            case .error(_):
                isIndicatorActive = false
            }
        }
    }
    /// アプリケーション設定が完了しているかどうか
    @Published private(set) var isAppSettingOK = false
    /// バーコード入力フック用待機画面ビューコントローラ
    @Published var barcodeInputViewCtrl: UIViewController?
    /// バーコード文字列読み込み用バッファ
    @Published var barcodeBuf = ""
    /// インジケーター表示を制御するフラグ
    @Published var isIndicatorActive = false
    /// 背景画像
    @Published var bgImage: UIImage
    
    init() {
        viewStatus = .wait
        
        // 背景画像を読み込む
        bgImage = ViewSetting.loadStanbyBGImage(barcordType: appSetGetSvc.getMustAppSetting().barcodeType)
    }
    
    /// アプリ設定を読み込む
    func reloadAppSetting() {
        // アプリ設定状態を読み込んで、現在のアプリ設定をアプリ設定取得サービスにセット
        let appSettingState = AppSettingStateService.shared.load()
        AppSettingGetService.shared.update(appSettingState.isAppSettingOK(), appSettingState.getAppSetting())
        
        isAppSettingOK = appSetGetSvc.isAppSettingOK()
    }
    
    /// iPadホーム画面や他のアプリから本アプリに戻ってきた
    func onActive() {
        // 背景画像を読み込む
        bgImage = ViewSetting.loadStanbyBGImage(barcordType: appSetGetSvc.getMustAppSetting().barcodeType)
    }
    
    /// 画面表示
    func onApear() {
        // 背景画像を読み込む
        bgImage = ViewSetting.loadStanbyBGImage(barcordType: appSetGetSvc.getMustAppSetting().barcodeType)
    }
    
    /// バーコード文字列を入力する
    /// - Parameter barcodeText: バーコード文字列
    func inputBarcode(_ barcodeText: String) {
        log.debug("\(type(of: self)): patient barcode input start. value=\(barcodeText)")
        
        viewStatus = .barcord
        
        Task {
            DispatchQueue.main.sync {
                viewStatus = .comm
            }
            
            do {
                let setting = self.appSetGetSvc.getMustAppSetting().patientCardSeisanSetting!
                
                // バーコード文字列を「患者番号取り扱い種別設定」に応じて、本アプリ内で取り扱う用の患者番号に加工する
                let barcodeModif = PatientNoBarcodeModif(
                    isPatientNoLowerDigitsEnable: setting.isPatientNoLowerDigitsEnable,
                    patientNoLowerDigits: setting.patientNoLowerDigits,
                    isPatientNoRemoveLowerDigitsEnable: setting.isPatientNoRemoveLowerDigitsEnable,
                    patientNoRemoveLowerDigits: setting.patientNoRemoveLowerDigits,
                    isPatientNoRemoveZeroPrefixEnable: setting.isPatientNoRemoveZeroPrefixEnable)
                let modfiedBarcodeText = barcodeModif.modifyBarcodeText(barcodeText)
                
                let barcode = try PatientBarcode(modfiedBarcodeText)
                log.info("\(type(of: self)): patient barcode. value=\(barcode)")
                
                // アプリ設定を取得
                let appSetting = self.appSetGetSvc.getMustAppSetting()
                
                if appSetting.patientCardSeisanSetting!.healthcareSystemType == .miu {
                    // MIU連携の場合、MIU連携プログラムに精算準備を依頼する
                    // 　→成功した場合、以下が保証される
                    // 　　・スマレジから仮販売データを取得OK
                    // 　　・TSIクラウドから領収証・診療明細書を取得OK
                    let miuIntegProgram = MIUProgram(setting: appSetting.miuProgramSetting!)
//                    let miuIntegProgram = MIUProgramStub()
                    
                    log.trace("\(type(of: self)): patient seisan prepare service start...")
                    let startTime = Date.now
                    
                    try await PatientSeisanPrepareService(
                        patientNo: barcode.patientNo,
                        prepare: miuIntegProgram).exec()
                    
                    log.info("\(type(of: self)): patient seisan prepare service ok. elapsed=\(Date().timeIntervalSince(startTime))")
                }
                
                // 仮販売データ取得用のインフラを準備
                let billingRepo = SmaregiPlatformRepository(
                    setting: appSetting.smaregiSetting!,
                    integrationMemoType:  appSetting.patientCardSeisanSetting!.getTempTransIntegrationMemoType())
                
                // 仮販売データの取得期間を取得
                log.info("\(type(of: self)): tempTransPeriodMonth=\(appSetGetSvc.getMustAppSetting().patientCardSeisanSetting!.tempTransPeriodMonth)")
                let (from, to) = try appSetting.patientCardSeisanSetting!.getTempTransFromTo()
                
                // 診察券請求を取得
                let billing = try await PatientCardSeisanUseCase(
                    barcode: barcode,
                    billingRepo: billingRepo,
                    from: from,
                    to: to).exec()
                log.info("\(type(of: self)): patient barcode input ok. billing=\(billing)")
                
                appState.setSeisan(billing: billing)
                
                // 仮販売追加項目をバックグラウンドで取得する
                let tempTransPrintDataRepo = TSISmaregiMedicalRepository(setting: self.appSetGetSvc.getMustAppSetting().tsiSmaregiMedicalSetting!)
                let tempTransAddItemBGGetSvc = TempTransAddItemBackgroundGetService(
                    setting: self.appSetGetSvc.getMustAppSetting().patientCardSeisanSetting!,
                    patientCardBilling: billing,
                    tempTransAddItemRepo: tempTransPrintDataRepo)
                tempTransAddItemBGGetSvc.start()
                
                appState.setTempTransAddItemBackgroundGetService(tempTransAddItemBGGetSvc: tempTransAddItemBGGetSvc)
                
            } catch PatientCardSeisanUseCase.RunError.refund(let amount) {
                // 返金
                log.error("\(type(of: self)): refund. amount=\(amount)")
                DispatchQueue.main.sync {
                    viewStatus = .refund
                }
                return
            } catch {
                log.error("\(type(of: self)): error has occurred: \(error)")
                DispatchQueue.main.sync {
                    viewStatus = .error(message: "\(error)")
                }
                return
            }
            
            DispatchQueue.main.sync {
                viewStatus = .wait
            }
            
            // 次画面に遷移
            appState.nextScreen()
        }
    }
    
    /// 返金表示確認後に呼び出す
    func refundOK() {
        viewStatus = .wait
    }
    
    /// エラー表示確認後に呼び出す
    func errorOK() {
        viewStatus = .wait
    }
}

extension StanbyPatientCardViewModel {
    /// 待機画面表示ステータス種別
    enum ViewStatusType: Equatable {
        ///  初期化中
        case `init`
        /// 待機中
        case wait
        /// バーコード入力中
        case barcord
        /// 通信中
        case comm
        /// 返金案内中
        case refund
        /// エラー中
        case error(message: String)
    }
}

extension StanbyPatientCardViewModel {
    /// 患者番号バーコード加工
    class PatientNoBarcodeModif {
        /// 下位N桁使用の有効／無効
        let isPatientNoLowerDigitsEnable: Bool
        
        /// 下位N桁使用の桁数
        let patientNoLowerDigits: Int
        
        /// 下位X桁削除の有効／無効
        let isPatientNoRemoveLowerDigitsEnable: Bool
        
        /// 下位X桁削除の桁数
        let patientNoRemoveLowerDigits: Int
        
        /// 前ゼロ削除の有効／無効
        let isPatientNoRemoveZeroPrefixEnable: Bool
        
        init(isPatientNoLowerDigitsEnable: Bool = false,
             patientNoLowerDigits: Int = 0,
             isPatientNoRemoveLowerDigitsEnable: Bool = false,
             patientNoRemoveLowerDigits: Int = 0,
             isPatientNoRemoveZeroPrefixEnable: Bool = false) {
            self.isPatientNoLowerDigitsEnable = isPatientNoLowerDigitsEnable
            self.patientNoLowerDigits = patientNoLowerDigits
            self.isPatientNoRemoveLowerDigitsEnable = isPatientNoRemoveLowerDigitsEnable
            self.patientNoRemoveLowerDigits = patientNoRemoveLowerDigits
            self.isPatientNoRemoveZeroPrefixEnable = isPatientNoRemoveZeroPrefixEnable
        }
        
        /// バーコード文字列を「患者番号取り扱い種別設定」に応じて、本アプリ内で取り扱う用の患者番号に加工する
        /// - Parameter barcodeText: バーコード文字列
        /// - Returns: 本アプリ内で取り扱う患者番号
        func modifyBarcodeText(_ barcodeText: String) -> String {
            var ret = barcodeText
            
            // 下位N桁使用
            if isPatientNoLowerDigitsEnable {
                ret = getBarcodeTextLowerDigits(ret, digits: patientNoLowerDigits)
            }
            
            // 下位X桁削除
            if isPatientNoRemoveLowerDigitsEnable {
                ret = removeBarcodeTextLowerDigits(ret, digits: patientNoRemoveLowerDigits)
            }

            // 前ゼロ削除
            if isPatientNoRemoveZeroPrefixEnable {
                ret = removeBarcodeTextZeroPrefix(ret)
            }
            
            return ret
        }
        
        /// バーコード文字列の下位digits桁のみを取り出す
        /// 　→実例として以下のケースに対応
        /// 　　・診察券に「数字７桁」の患者番号バーコード貼付
        /// 　　　 → 例：7654321
        /// 　　・上記の内「下位５桁」をORCA患者番号とスマレジ顧客コードとして使用
        /// 　　　　→ 例：54321
        /// - Parameter barcodeText: バーコード文字列
        /// - Parameter int: 有効な桁数
        /// - Returns: 加工したバーコード文字列
        func getBarcodeTextLowerDigits(_ barcodeText: String, digits: Int) -> String {
            var safeDigits = digits
            if safeDigits < 0 {
                safeDigits = 0
            }
            
            return String(barcodeText.suffix(safeDigits))
        }
        
        /// バーコード文字列の下位digits桁を削除する
        /// 　→バーコードのチェックデジットを削除できるようにすための対応
        /// - Parameter barcodeText: バーコード文字列
        /// - Parameter int: 削除する桁数
        /// - Returns: 加工したバーコード文字列
        func removeBarcodeTextLowerDigits(_ barcodeText: String, digits: Int) -> String {
            var safeDigits = digits
            if safeDigits < 0 {
                safeDigits = 0
            }
            
            return String(barcodeText.dropLast(safeDigits))
        }
        
        /// バーコード文字列の前ゼロを削除する
        /// 　→CSV連携の環境において、
        /// 　　診察券の患者番号は「00030」だが、
        /// 　　スマレジへの顧客登録を「30」で行っているところがあることへの対応
        /// - Parameter barcodeText: バーコード文字列
        /// - Returns: 加工したバーコード文字列
        func removeBarcodeTextZeroPrefix(_ barcodeText: String) -> String {
            var ret = barcodeText
            
            // 患者番号の前ゼロを削除して取り扱う場合
            if let number = Int(barcodeText) {
                // 一旦数値化して、再度文字列化する
                ret = String(number)
            }
            
            return ret
        }
    }
}
