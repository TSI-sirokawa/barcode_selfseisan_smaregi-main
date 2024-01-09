//
//  CanPayout.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/02.
//

import Foundation
import Logging

/// つり銭機内にある紙幣／硬貨での払出し可否判定するためのクラス
final class CanPayout {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// 紙幣機内：10000円枚数
    let the10000: UInt16
    /// 紙幣機内：5000円枚数
    let the5000: UInt16
    /// 紙幣機内：2000円枚数
    let the2000: UInt16
    /// 紙幣機内：1000円枚数
    let the1000: UInt16
    /// 硬貨機内：500円枚数
    let the500: UInt16
    /// 硬貨機内：100円枚数
    let the100: UInt16
    /// 硬貨機内：50円枚数
    let the50: UInt16
    /// 硬貨機内：10円枚数
    let the10: UInt16
    /// 硬貨機内：5円枚数
    let the5: UInt16
    /// 硬貨機内：1円枚数
    let the1: UInt16
    
    init(the10000: UInt16, the5000: UInt16, the2000: UInt16, the1000: UInt16, the500: UInt16, the100: UInt16, the50: UInt16, the10: UInt16, the5: UInt16, the1: UInt16) {
        self.the10000 = the10000
        self.the5000 = the5000
        self.the2000 = the2000
        self.the1000 = the1000
        self.the500 = the500
        self.the100 = the100
        self.the50 = the50
        self.the10 = the10
        self.the5 = the5
        self.the1 = the1
        
        self.insideNums = [
            10000: Int(self.the10000),
            5000: Int(self.the5000),
            2000: Int(self.the2000),
            1000: Int(self.the1000),
            500: Int(self.the500),
            100: Int(self.the100),
            50: Int(self.the50),
            10: Int(self.the10),
            5: Int(self.the5),
            1: Int(self.the1),
        ]
    }
    
    /// 機内の格納枚数
    private let insideNums: Dictionary<Int, Int>
    /// 払い出しを確認する紙幣
    private static let BILLS: [Int] = [10000, 5000, 1000]
    /// 払い出しを確認する硬貨
    private static let COINS: [Int] = [500, 100, 50, 10, 5, 1]
    
    /// 指定した金額を払い出し可能かを返す
    /// - Parameter amount: 払い出したい金額[円]
    /// - Returns: true:払い出し可、false:払い出し不可
    func isOK(amount: Int) -> Bool {
        var payout = amount
        
        // 各金種での判定
        // 紙幣と硬貨間で代替えは行われない
        // 紙幣での判定
        for idx in 0...CanPayout.BILLS.count-1{
            let targetYen = CanPayout.BILLS[idx]
            
            // 本金種の必要枚数を計算
            let wantNum = payout / targetYen
            if wantNum == 0 {
                continue
            }
            
            let insideNum = insideNums[targetYen] ?? 0
            if (wantNum <= insideNum){
                // 本金種を必要な分だけ払い出せる場合は、
                // 必要な枚数だけ払い出せる
                //
                // 　例：9420円の払い出しで、機内に5000円札が1枚以上残っている場合
                // 　　　5000円札を1枚払い出す
                payout = payout - (wantNum * targetYen)
            } else {
                // 本金種を必要な分だけ払い出せない場合は、
                // 2つ目の金種で代替えを試みる
                //
                // 　例：9420円の払い出しで、機内に5000円札がない場合、
                // 　　　残り9000円を1000円札×9枚で払い出せるかを確認する
                
                if (idx+1 == CanPayout.BILLS.count) {
                    // 紙幣から硬貨の代替えはしないので払い出し不可
                    return false
                }
                
                // １）まず、本金種で払い出す分を引いて、2つ目の金種で払い出す分を計算
                let nextWantPayout = payout - (insideNum * targetYen)
                
                // ２）2つ目の金種を取得
                let nextTargetYen = CanPayout.BILLS[idx+1]
                
                // ３）2つ目の金種の必要枚数を計算
                let nextWantNum = nextWantPayout / nextTargetYen
                
                // ４）機内にある2つ目の金種の枚数を取得
                let nextInsideNum = insideNums[nextTargetYen] ?? 0
                if (nextWantNum > nextInsideNum){
                    // 2つ目の金種でも足りなければ払い出し不可
                    return false
                }
                
                // 本金種で払い出せる分は払い出す
                payout = payout - (insideNum * targetYen)
            }
        }
        // 硬貨での判定
        for idx in 0...CanPayout.COINS.count-1{
            let targetYen = CanPayout.COINS[idx]
            let wantNum = payout / targetYen
            if wantNum == 0 {
                continue
            }
            
            let insideNum = insideNums[targetYen] ?? 0
            if (wantNum <= insideNum){
                payout = payout - (wantNum * targetYen)
            } else {
                if (idx+1 == CanPayout.COINS.count) {
                    // 1円以下の硬貨はないので払い出し不可
                    return false
                }
                
                let nextWantPayout = payout - (insideNum * targetYen)
                let nextTargetYen = CanPayout.COINS[idx+1]
                let nextWantNum = nextWantPayout / nextTargetYen
                let nextInsideNum = insideNums[nextTargetYen] ?? 0
                if (nextWantNum > nextInsideNum){
                    // 2つ目の金種でも足りなければ払い出し不可
                    return false
                }
                
                payout = payout - (insideNum * targetYen)
            }
        }
        
        var canPayout = true
        if (payout > 0) {
            canPayout = false
        }
        
        let debugStr = "10000: \(the10000), 5000: \(the5000), 2000: \(the2000), 1000: \(the1000), 500: \(the500), 100: \(the100), 50: \(the50), 10: \(the10), 5: \(the5), 1: \(the1)"
        log.trace("canPayout: amount=\(amount), canPayout=\(canPayout), cash=\(debugStr)")
        
        return canPayout
    }
}
