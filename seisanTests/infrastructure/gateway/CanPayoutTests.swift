//
//  canPayoutTests.swift
//  seisanTests
//
//  Created by Hiroyuki Kajiki on 2022/07/18.
//

import XCTest
@testable import seisan

class canPayoutTests: XCTestCase {
    
    func test_10000() throws {
        var canPayment = seisan.CanPayout(
            the10000: 1,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 9999), false)
        
        canPayment = seisan.CanPayout(
            the10000: 1,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 10000), true)
        
        canPayment = seisan.CanPayout(
            the10000: 1,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 1)
        XCTAssertEqual(canPayment.isOK(amount: 10001), true)
    }
    
    func test_5000() throws {
        var canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 1,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 4999), false)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 1,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 5000), true)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 1,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 1,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 5005), true)
    }
    
    func test_1000() throws {
        var canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 1,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 999), false)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 1,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 1000), true)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 1,
            the500: 0,
            the100: 0,
            the50: 1,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 1050), true)
    }
    
    func test_500() throws {
        var canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 1,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 499), false)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 1,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 500), true)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 1,
            the100: 1,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 600), true)
    }
    
    func test_100() throws {
        var canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 1,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 99), false)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 1,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 100), true)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 1,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 1)
        XCTAssertEqual(canPayment.isOK(amount: 101), true)
    }
    
    func test_50() throws {
        var canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 1,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 49), false)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 1,
            the10: 0,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 50), true)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 1,
            the10: 0,
            the5: 1,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 55), true)
    }
    
    func test_10() throws {
        var canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 1,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 9), false)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 1,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 10), true)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 1,
            the5: 0,
            the1: 1)
        XCTAssertEqual(canPayment.isOK(amount: 11), true)
    }
    
    func test_5() throws {
        var canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 1,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 4), false)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 1,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 5), true)
        
        canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 1,
            the1: 1)
        XCTAssertEqual(canPayment.isOK(amount: 6), true)
    }
    
    func test_1() throws {
        let canPayment = seisan.CanPayout(
            the10000: 0,
            the5000: 0,
            the2000: 0,
            the1000: 0,
            the500: 0,
            the100: 0,
            the50: 0,
            the10: 0,
            the5: 0,
            the1: 1)
        XCTAssertEqual(canPayment.isOK(amount: 1), true)
    }
    
    /// 大きい方の金種枚数が足りない場合に、小さい金種への代替えを行えるかどうかのテスト
    func test_Change() throws {
        /// 請求：           580円
        /// 投入金額：10000円
        /// おつり：      9420円
        /// 機内：5000札はないが、1000円札以下でおつりは払い出せる
        ///
        /// 　→5000札から1000円札への代替えが行われる
        var canPayment = seisan.CanPayout(
            the10000: 1,    // 投入分
            the5000: 0,
            the2000: 0,
            the1000: 10,
            the500: 1,
            the100: 5,
            the50: 1,
            the10: 2,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 9420), true)
        
        /// 請求：            580円
        /// 投入金額： 20000円
        /// おつり：     19420円
        /// 機内：5000札はないが、1000円札以下でおつりは払い出せる
        ///
        /// 　→5000札から1000円札への代替えが行われる
        canPayment = seisan.CanPayout(
            the10000: 2,    // 投入分
            the5000: 0,
            the2000: 0,
            the1000: 20,
            the500: 1,
            the100: 5,
            the50: 1,
            the10: 2,
            the5: 0,
            the1: 0)
        XCTAssertEqual(canPayment.isOK(amount: 19420), true)
    }
}
