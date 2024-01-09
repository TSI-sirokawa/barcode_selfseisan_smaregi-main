//
//  AnnounceManager.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/06/29.
//

import Foundation
import Logging
import AVFoundation

/// 説明音声管理
final class AnnounceManager: NSObject, AVAudioPlayerDelegate, ObservableObject {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// 音声案内再生用
    private var audioPlayer: AVAudioPlayer?
    ///  再生中かどうかを示すフラグ
    private(set) var isPlaying = false
    
    /// 説明音声の再生を開始する
    /// - Parameter situation: シチュエーション
    func play(situation: Situation) {
        // 説明音声中の場合は説明音声を停止
        audioPlayer?.stop()
        audioPlayer = nil
        
        isPlaying = true
        
        // 再生する説明音声を選択
        let assetName = getAssetName(situation: situation)
        if let assetName = assetName {
            // 説明音声を再生
            do {
                let musicData = NSDataAsset(name: assetName)!.data
                audioPlayer = try AVAudioPlayer(data: musicData)
                audioPlayer!.delegate = self
                audioPlayer!.prepareToPlay()
                audioPlayer!.play()
            } catch {
                log.error("\(type(of: self)): play sound error: \(error)")
            }
        }
    }
    
    /// 説明音声を停止する
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // AVAudioPlayerDelegateプロトコル実装
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            // 再生終了
            isPlaying = false
        }
    }
    
    /// 説明音声のアセット名を取得
    private func getAssetName(situation: Situation) -> String? {
        var assetName: String?
        switch situation {
        case .selectKesaiView:
            assetName = "Sounds/Sound_01"
        case .cashKesaiView:
            assetName = "Sounds/Sound_02"
        case .creditKesaiView:
            assetName = "Sounds/Sound_03"
        case .changeExist:
            assetName = "Sounds/Sound_04"
        case .receiptAndCashComplete:
            assetName = "Sounds/Sound_05"
        case .receiptAndCreditComplete:
            assetName = "Sounds/Sound_06"
        case .patiaentCardAndCashWithoutShohosen:
            assetName = "Sounds/Sound_07"
        case .patiaentCardAndCashWithShohosen:
            assetName = "Sounds/Sound_08"
        case .patiaentCardAndCreditWithoutShohosen:
            assetName = "Sounds/Sound_09"
        case .patiaentCardAndCreditWithShohosen:
            assetName = "Sounds/Sound_10"
        }
        return assetName
    }
}

extension AnnounceManager {
    ///　説明音声再生シチュエーション
    enum Situation {
        /// 決済方法選択画面表示
        case selectKesaiView
        /// 現金決済画面表示
        case cashKesaiView
        /// クレジット決済画面表示
        case creditKesaiView
        /// 現金決済でお釣りがある場合
        case changeExist
        /// 領収書精算＆現金決済完了
        case receiptAndCashComplete
        /// 領収書精算＆クレジット決済完了
        case receiptAndCreditComplete
        /// 診察券精算＆現金（処方なし）
        case patiaentCardAndCashWithoutShohosen
        /// 診察券精算&現金（処方あり）
        case patiaentCardAndCashWithShohosen
        /// 診察券精算＆クレジット（処方なし）
        case patiaentCardAndCreditWithoutShohosen
        /// 診察券精算＆クレジット（処方あり）
        case patiaentCardAndCreditWithShohosen
    }
}
