//
//  AppSettingStateService.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/26.
//

import Foundation
import Logging

/// アプリ設定状態サービス
final class AppSettingStateService: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ設定リポジトリプロトコル
    private var repo: AppSettingRepositoryProtocol {
        get {
            return _repo!
        }
    }
    private var _repo: AppSettingRepositoryProtocol?
    
    /// シングルトンインスタンス
    static var shared: AppSettingStateService = AppSettingStateService()
    
    private init() {
    }
    
    func setRepository(repo: AppSettingRepositoryProtocol) {
        self._repo = repo
    }
    
    func load() -> AppSettingState {
        let selectedBarcodeState = SelectedBarcodeState.load(repo: repo)
        let patientCardSeisanState = PatientCardSeisanSettingState.load(repo: repo)
        let miuProgramSettingState = MIUProgramSettingState.load(repo: repo)
        let selectedAutoCashierState = SelectedAutoCashierState.load(repo: repo)
        let groly300SettingState = Groly300AutoCashierAdapterSettingState.load(repo: repo)
        let grolyR08SettingState = GrolyR08AutoCashierAdapterSettingState.load(repo: repo)
        let creditSettingState = CregitSettingState.load(repo: repo)
        let tsiSmaregiMecicalState = TSISmaregiMedicalSettingState.load(repo: repo)
        let receiptPrinterSettingState = ReceiptPrinterSettingState.load(repo: repo)
        let orcaSettingState = ORCASettingState.load(repo: repo)
        let smaregiSettingState = SmaregiPlatformSettingState.load(repo: repo, selectedBarcodeState: selectedBarcodeState)
        let viewSettingState = ViewSettingState.load(repo: repo)
        let customerDisplaySettingState = CustomerDisplaySettingState.load(repo: repo)
        let httpServerSettingState = HTTPServerSettingState.load(repo: repo)
        let logSettingState = LogSettingState.load(repo: repo)
        
        log.trace("\(type(of: self)): load app setting state ok")
        
        let state = AppSettingState(
            selectedBarcodeState: selectedBarcodeState,
            patientCardSeisanSettingState: patientCardSeisanState,
            miuProgramSettingState: miuProgramSettingState,
            selectedAutoCashierState: selectedAutoCashierState,
            grolyR08SettingState: grolyR08SettingState,
            groly300SettingState: groly300SettingState,
            creditSettingState: creditSettingState,
            smaregiSettingState: smaregiSettingState,
            tsiSmaregiMedicalSettingState: tsiSmaregiMecicalState,
            receiptPrinterSettingState: receiptPrinterSettingState,
            orcaSettingState: orcaSettingState,
            viewSettingState: viewSettingState,
            customerDisplaySettingState: customerDisplaySettingState,
            httpServerSettingState: httpServerSettingState,
            logSettingState: logSettingState)
        return state
    }
    
    func save(_ state: AppSettingState) throws {
        // 設定状態は無効な値であっても常に保存
        SelectedBarcodeState.save(repo: repo, state: state.selectedBarcodeState)
        PatientCardSeisanSettingState.save(repo: repo, state: state.patientCardSeisanSettingState)
        MIUProgramSettingState.save(repo: repo, state: state.miuProgramSettingState)
        SelectedAutoCashierState.save(repo: repo, state: state.selectedAutoCashierState)
        GrolyR08AutoCashierAdapterSettingState.save(repo: repo, state: state.grolyR08SettingState)
        Groly300AutoCashierAdapterSettingState.save(repo: repo, state: state.groly300SettingState)
        CregitSettingState.save(repo: repo, state: state.creditSettingState)
        SmaregiPlatformSettingState.save(repo: repo, state: state.smaregiSettingState)
        ReceiptPrinterSettingState.save(repo: repo, state: state.receiptPrinterSettingState)
        TSISmaregiMedicalSettingState.save(repo: repo, state: state.tsiSmaregiMedicalSettingState)
        try ORCASettingState.save(repo: repo, state: state.orcaSettingState)
        ViewSettingState.save(repo: repo, state: state.viewSettingState)
        CustomerDisplaySettingState.save(repo: repo, state: state.customerDisplaySettingState)
        HTTPServerSettingState.save(repo: repo, state: state.httpServerSettingState)
        LogSettingState.save(repo: repo, state: state.logSettingState)
        
        log.trace("\(type(of: self)): save app setting state ok")
    }
}
