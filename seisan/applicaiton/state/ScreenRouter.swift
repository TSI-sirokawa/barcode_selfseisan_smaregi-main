//
//  ScreenRouter.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/20.
//

import Foundation
import Logging

/// 画面表示ルータ
final class ScreenRouter: ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// シングルトンインスタンス
    static let shared: ScreenRouter = .init()
    
    /// シングルトンにするためにinitをprivateで定義
    private init() {}
    
    /// NavigationStackを制御するための画面ID配列
    @Published var pathes: [ScreenID] = []
    /// 現在表示中の画面
    @Published private(set) var currScreenID: ScreenID = .rooting
    /// 画面遷移監視タイマー
    private var routingTimer: Timer?
    
    /// 画面遷移監視タイマーのタイムアップ時間
    static let ROUTING_TIMER_TIMEUP_SEC: Double = 5
    
    /// 画面遷移を行う
    /// - Parameters:
    ///   - prev: 遷移前（現在）の画面ID
    ///   - next: 遷移先の画面ID
    func transition(prev: ScreenID, next: ScreenID) {
        log.info("\(type(of: self)): \(prev) -> \(next)")
        
        // 画面遷移監視タイマーを停止
        stopRoutingTimer()
        
        // 画面遷移許可の確認と、画面遷移の実行
        switch prev {
        case .rooting:
            switch next {
            case .stanby:
                // ルート画面 -> 待機画面
                nextScreen(.stanby)
            default:
                log.warning("\(type(of: self)): unknown present. prev=\(prev), next=\(next)")
            }
        case .stanby:
            switch next {
            case .kesaiSelect:
                // 待機画面 -> 決済方法選択画面
                nextScreen(.kesaiSelect)
            case .cashKesai:
                // 待機画面 -> 現金決済画面
                nextScreen(.cashKesai)
            case .creditKesai:
                // 待機画面 -> クレジット決済画面
                nextScreen(.creditKesai)
            default:
                log.warning("\(type(of: self)): unknown present. prev=\(prev), next=\(next)")
            }
        case .kesaiSelect:
            switch next {
            case .stanby:
                // 待機画面 <- 決済方法選択画面
                prevScreen()
            case .cashKesai:
                // 決済方法選択画面 -> 現金決済画面
                nextScreen(.cashKesai)
            case .creditKesai:
                // 決済方法選択画面 -> クレジット決済画面
                nextScreen(.creditKesai)
            default:
                log.warning("\(type(of: self)): unknown present. prev=\(prev), next=\(next)")
            }
        case .cashKesai:
            switch next {
            case .stanby:
                // 待機画面 <- 現金決済画面
                returnStanby()
            case .kesaiSelect:
                // 決済方法選択 <- 現金決済画面
                prevScreen()
            case .seisanFinalize:
                // 現金決済画面 -> 取引終了処理画面
                nextScreen(.seisanFinalize)
            case .complete:
                // 現金決済画面 -> 精算完了画面
                nextScreen(.complete)
            default:
                log.warning("\(type(of: self)): unknown present. prev=\(prev), next=\(next)")
            }
        case .creditKesai:
            switch next {
            case .stanby:
                // 待機画面 <- クレジット決済画面
                returnStanby()
            case .kesaiSelect:
                // 決済方法選択 <- クレジット決済画面
                prevScreen()
            case .seisanFinalize:
                // クレジット決済画面 -> 取引終了処理画面
                nextScreen(.seisanFinalize)
                // 画面遷移に失敗する現象に対応するため、タイマーによる遷移監視を行う
                // ・クレジット決済画面から取引終了処理画面への遷移で発生
                // ・iPad第8世代（iPadOSバージョン16.2/16.3）で発生を確認
                startRoutingTimer(.seisanFinalize)
            case .complete:
                // クレジット決済画面 -> 精算完了画面
                nextScreen(.complete)
            default:
                log.warning("\(type(of: self)): unknown present. prev=\(prev), next=\(next)")
            }
        case .seisanFinalize:
            switch next {
            case .complete:
                // 取引終了処理画面 -> 精算完了画面
                nextScreen(.complete)
            default:
                log.warning("\(type(of: self)): unknown present. prev=\(prev), next=\(next)")
            }
        case .complete:
            switch next {
            case .stanby:
                // 待機画面 <- 精算完了画面
                returnStanby()
            default:
                log.warning("\(type(of: self)): unknown present. prev=\(prev), next=\(next)")
            }
        }
    }
    
    /// 次の画面に進む
    /// - Parameter screenID: 画面ID
    func nextScreen(_ screenID: ScreenID) {
        DispatchQueue.main.async {
            self.pathes.append(screenID)
            self.outputRouteLog()
        }
    }
    
    /// １つ前の画面に戻る
    func prevScreen() {
        DispatchQueue.main.async {
            self.pathes.removeLast()
            self.outputRouteLog()
        }
    }
    
    /// 待機画面に戻る
    func returnStanby() {
        DispatchQueue.main.async {
            self.pathes = [ self.pathes[0] ]
            self.outputRouteLog()
        }
    }
    
    ///  ルートログを取得する
    func outputRouteLog() {
        var pathStr = ""
        for path in pathes {
            if pathStr != "" {
                pathStr += " -> "
            }
            pathStr += String(describing: path)
        }
        log.info("\(type(of: self)): screen route: \(pathStr)")
    }
    
    /// 現在表示中の画面の通知する
    /// - Parameter screenID: 画面ID
    func noticeCurrScreen(_ screenID: ScreenID) {
        log.trace("\(type(of: self)): notice curr screen. screenID=\(screenID)")
        currScreenID = screenID
    }
    
    /// 画面遷移監視タイマーを開始する
    /// - Parameter screenID: 画面ID
    func startRoutingTimer(_ screenID: ScreenID) {
        log.trace("\(type(of: self)): start routing timer. screenID=\(screenID)")
        routingTimer = Timer.scheduledTimer(withTimeInterval: ScreenRouter.ROUTING_TIMER_TIMEUP_SEC, repeats: false, block: routingTimeup)
    }
    
    /// 画面遷移監視タイマーを停止する
    func stopRoutingTimer() {
        if routingTimer != nil {
            log.trace("\(type(of: self)): stop routing timer")
        }
        routingTimer?.invalidate()
        routingTimer = nil
    }
    
    /// 画面遷移監視タイマーのタイムアップ
    /// - Parameter timer: タイマー
    private func routingTimeup(timer: Timer) {
        let lastScreenID = pathes.last!
        let currScreenID = currScreenID
        
        log.info("\(type(of: self)): routing timeup. lastScreenID=\(lastScreenID), currScreenID=\(currScreenID)")
        
        if pathes.last! != currScreenID {
            // 「画面遷移ID配列の最後尾」と「現在表示中の画面」が一致しなかった場合
            // 画面遷移をリトライ
            log.info("\(type(of: self)): routing retry")
            pathes.removeLast()
            pathes.append(lastScreenID)
        }
    }
}

extension ScreenRouter {
    /// 画面ID
    enum ScreenID {
        /// 画面遷移用の画面
        case rooting
        /// 精算待機画面
        case stanby
        /// 決済方法選択画面
        case kesaiSelect
        /// 現金決済画面
        case cashKesai
        /// クレジット決済画面
        case creditKesai
        /// 取引終了処理画面
        case seisanFinalize
        /// 精算完了処理画面
        case complete
    }
}

