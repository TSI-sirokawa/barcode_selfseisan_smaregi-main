//
//  RoutingView.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/14.
//

import SwiftUI
import Logging

/// 画面遷移用の画面
struct RoutingView: View {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettingStateSvc: AppSettingStateService
    @EnvironmentObject var appSettingSvc: AppSettingGetService
    @EnvironmentObject var screenRouter: ScreenRouter
    @EnvironmentObject var announceMgr: AnnounceManager
    
    @StateObject var viewModel = RoutingViewModel()
    
    init() {
        //画面遷移時のアニメーションを無効化
        UIView.setAnimationsEnabled(false)
    }
    
    var body: some View {
        ZStack {
            NavigationStack(path: $screenRouter.pathes) {
                EmptyView()
                    .navigationDestination(for: ScreenRouter.ScreenID.self) { viewID in
                        switch viewID {
                        case .stanby:
                            switch appSettingSvc.getMustAppSetting().barcodeType {
                            case .ReceiptBarcord:
                                // 領収書バーコードモード
                                StanbyView()
                            case .PatientCardBarcord:
                                // 診察券バーコードモード
                                StanbyPatientCardView()
                            }
                        case .kesaiSelect:
                            KesaiSelectView()
                        case .cashKesai:
                            CashKesaiView()
                        case .creditKesai:
                            CreditKesaiView()
//                            // 開発用コード
//                            CreditKesaiMockView()
                        case .seisanFinalize:
                            switch appState.getSeisanType() {
                            case .ReceiptSeisan:
                                // 領収書精算時
                                ReceiptSeisanFinalizeView()
                            case .PatientCardSeisan:
                                // 診察券精算時
                                PatientCardSeisanFinalizeView()
                            }
                        case .complete:
                            SeisanCompleteView()
                        default:
                            EmptyView()
                        }
                    }
            }
        }.onAppear {
            log.trace("\(type(of: self)): appear")
            appState.noticeCurrScreen(.rooting)
            
            // 次画面に遷移
            appState.nextScreen()
        }.onChange(of: screenRouter.pathes) { newPathes in
            log.info("\(type(of: self)): pathes change detected. newValue=\(newPathes)")
            
            // 説明音声再生
            switch newPathes.last {
            case .stanby:
                announceMgr.stop()
            case .kesaiSelect:
                announceMgr.play(situation: .selectKesaiView)
            case .cashKesai:
                announceMgr.play(situation: .cashKesaiView)
            case .creditKesai:
                announceMgr.play(situation: .creditKesaiView)
            case .seisanFinalize, .complete:
                // 「精算終了処理画面」では遷移前の説明音声をそのまま流し、
                // 「精算完了画面」では精算完了画面で説明音声を制御するため、
                //  ここでは何も行わない
                break
            default:
                // 上記条件以外の画面遷移時は説明音声を停止
                announceMgr.stop()
                break
            }
        }
        .onReceive(screenRouter.$currScreenID) { newCurrScreenID in
            log.info("\(type(of: self)): notice curr screen. screenID=\(newCurrScreenID)")
            
            // 画面表示時の実行する処理をここに記述する
            switch newCurrScreenID {
            case .stanby:
                viewModel.notifStanbyScreenDisplay()
            case .kesaiSelect:
                viewModel.notifKesaiSelectDisplay()
            default:
                break
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RoutingView()
    }
}
