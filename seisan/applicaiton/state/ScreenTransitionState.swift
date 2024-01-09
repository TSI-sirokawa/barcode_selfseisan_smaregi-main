//
//  ScreenTransitionState.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/08/20.
//

import Foundation

/// 画面表示状態
class DisplayScreenState: ObservableObject {
    /// シングルトンインスタンス
    static let shared: DisplayScreenState = .init()
    
    /// シングルトンにするためにinitをprivateで定義
    private init() {}
    
    @Published var pathes: [ScreenID] = []
    
    /// 精算ステータスを元に画面遷移を行う
    /// - Parameter status: 清算ステータス種別
    func transition(prev: ScreenID, next: ScreenID) {
        //精算ステータスで画面遷移先を決定
        switch prev {
        case .stanby:
            switch next {
            case .kesaiSelect:
                // 待機画面 -> 決済方法選択画面
                pathes.append(.kesaiSelect)
            default:
                print("AppState: unknown present. prev=\(prev), next=\(next)")
            }
        case .kesaiSelect:
            switch next {
            case .stanby:
                // 待機画面 <- 決済方法選択画面
                pathes.removeLast()
            case .cashKesai:
                // 決済方法選択画面 -> 現金決済画面
                pathes.append(.cashKesai)
            case .creditKesai:
                // 決済方法選択画面 -> クレジット決済画面
                pathes.append(.creditKesai)
            default:
                print("AppState: unknown present. prev=\(prev), next=\(next)")
            }
        case .cashKesai:
            switch next {
            case .stanby:
                // 待機画面 <- 現金決済画面
                pathes.removeAll()
            case .kesaiSelect:
                // 決済方法選択 <- 現金決済画面
                pathes.removeLast()
            case .complete:
                // 現金決済画面 -> 精算完了画面
                pathes.append(.complete)
            default:
                print("AppState: unknown present. prev=\(prev), next=\(next)")
            }
        case .creditKesai:
            switch next {
            case .stanby:
                // 待機画面 <- クレジット決済画面
                pathes.removeAll()
            case .kesaiSelect:
                // 決済方法選択 <- クレジット決済画面
                pathes.removeLast()
            case .complete:
                // クレジット決済画面 -> 精算完了画面
                pathes.append(.complete)
            default:
                print("AppState: unknown present. prev=\(prev), next=\(next)")
            }
        case .complete:
            switch next {
            case .stanby:
                // 待機画面 <- 精算完了画面
                pathes.removeAll()
            default:
                print("AppState: unknown present. prev=\(prev), next=\(next)")
            }
        }
    }
}

extension DisplayScreenState {
    /// 画面ID
    enum ScreenID {
        /// 精算待機画面
        case stanby
        /// 決済方法選択画面
        case kesaiSelect
        /// 現金決済画面
        case cashKesai
        /// クレジット決済画面
        case creditKesai
        /// 精算完了処理画面
        case complete
    }
}
