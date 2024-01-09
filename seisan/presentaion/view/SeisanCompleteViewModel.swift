//
//  SeisanCompleteViewModel.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/23.
//

import Foundation
import Logging
import AudioToolbox

/// 精算完了表示画面ビューモデル
final class SeisanCompleteViewModel: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// アプリ状態
    private let appState: AppState = AppState.shared
    /// アプリ設定取得サービス
    private let appSetGetSvc: AppSettingGetService = AppSettingGetService.shared
    /// 精算完了メッセージ
    @Published var seisanCompleteMessage = ""
    /// 処方箋引換券受け取り案内メッセージ
    @Published var shohosenHikikaekenMessage = ""
    
    init() {
        if appState.isShohosenPrinted {
            // 処方箋引換券を印刷した場合
            shohosenHikikaekenMessage = appSetGetSvc.getMustAppSetting().viewSetting.seisanCompleteViewShohosenHikikaekenMessage
        }
        
        if appState.getCashKesaiState() != nil && appState.getCashKesaiState()!.cashKesaiStatus == .change {
            // 現金決済でおつりがある場合
            
            // 表示メッセージをセット
            seisanCompleteMessage = appSetGetSvc.getMustAppSetting().viewSetting.seisanCompleteViewMessageWithChange
            
            Task {
                await execChangeExistSequence()
            }
            return
        }
        
        // 表示メッセージをセット
        seisanCompleteMessage = appSetGetSvc.getMustAppSetting().viewSetting.seisanCompleteViewMessageNoChange
        
        Task {
            await execChangeNoExistSequence()
        }
    }
    
    /// おつりがある場合のシーケンス処理
    func execChangeExistSequence() async {
        log.info("\(type(of: self)): change exist sequence...")
        
        let cashKesaiState = appState.getCashKesaiState()!
        
        // おつり受け取り説明音声の再生完了、かつ、おつりを受け取るまで待つ
        while(InfraManager.shared.announceMgr.isPlaying || cashKesaiState.cashKesaiStatus != .completed) {
            do {
                // 50ミリ秒毎に確認
                try await Task.sleep(nanoseconds: 50 * 1000 * 1000)
            } catch {}
        }
        
        await execCompleteSequence()
    }
    
    /// おつりがない場合のシーケンス処理
    func execChangeNoExistSequence() async {
        log.info("\(type(of: self)): change no exist sequence...")

        await execCompleteSequence()
    }
    
    /// 共通の精算完了シーケンス処理
    func execCompleteSequence() async {
        log.info("\(type(of: self)): complete sequence...")
        
        // 精算完了メッセージ表示の完了時刻を計算
        let completeMsgLimitTime = Date.now.addingTimeInterval(TimeInterval(appSetGetSvc.getMustAppSetting().viewSetting.seisanCompleteViewMessageDisplayTimeSec))
        
        // 説明音声の再生を開始
        switch appState.getSeisanType() {
        case .ReceiptSeisan:
            // 領収書精算時
            switch appState.getKesaiResult().kesaiMethod {
            case .cash:
                InfraManager.shared.announceMgr.play(situation: .receiptAndCashComplete)
            case .credit:
                InfraManager.shared.announceMgr.play(situation: .receiptAndCreditComplete)
            }
        case .PatientCardSeisan:
            // 診察券精算時
            switch appState.getKesaiResult().kesaiMethod {
            case .cash:
                if AppState.shared.isShohosenPrinted {
                    // 処方箋引換券印刷あり
                    InfraManager.shared.announceMgr.play(situation: .patiaentCardAndCashWithShohosen)
                } else {
                    InfraManager.shared.announceMgr.play(situation: .patiaentCardAndCashWithoutShohosen)
                }
            case .credit:
                if AppState.shared.isShohosenPrinted {
                    // 処方箋引換券印刷あり
                    InfraManager.shared.announceMgr.play(situation: .patiaentCardAndCreditWithShohosen)
                } else {
                    InfraManager.shared.announceMgr.play(situation: .patiaentCardAndCreditWithoutShohosen)
                }
            }
        }
        
        // 精算完了メッセージ表示時間を経過をするまで待つ
        // 　→精算完了説明音声の再生途中の場合は画面遷移によって再生が中断される
        // 　→待機画面への画面遷移による再生中断はRoutingViewに実装している
        while(Date.now < completeMsgLimitTime) {
            do {
                // 50ミリ秒毎に確認
                try await Task.sleep(nanoseconds: 50 * 1000 * 1000)
            } catch {}
        }
        
        log.info("\(type(of: self)): complete sequence ok")
        
        // 次画面に遷移
        appState.nextScreen()
    }
}
