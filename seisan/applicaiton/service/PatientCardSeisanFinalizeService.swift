//
//  PatientCardSeisanFinalizeService.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/21.
//

import Foundation
import Logging

/// 診察券精算取引終了処理サービス
final class PatientCardSeisanFinalizeService {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    let setting: PatientCardSeisanSetting
    let patientCardBilling: PatientCardBilling
    let kesaiResult: KesaiResult
    let transResultRepo: TransactionResultRepositoryProtocol
    let tempTransRepo: TemporaryTransacitonRepositoryProtocol
    let isRegisterShunoEnable: Bool
    let shunoRepo: ShunoRepositoryProtocol?
    
    init(setting: PatientCardSeisanSetting,
         patientCardBilling: PatientCardBilling,
         kesaiResult: KesaiResult,
         transResultRepo: TransactionResultRepositoryProtocol,
         tempTransRepo: TemporaryTransacitonRepositoryProtocol,
         isRegisterShunoEnable: Bool,
         shunoRepo: ShunoRepositoryProtocol?) {
        self.setting = setting
        self.patientCardBilling = patientCardBilling
        self.kesaiResult = kesaiResult
        self.transResultRepo = transResultRepo
        self.tempTransRepo = tempTransRepo
        self.isRegisterShunoEnable = isRegisterShunoEnable
        self.shunoRepo = shunoRepo
    }
    
    func exec() async throws {
        // 取引結果を生成
        let (tempTransIDs, transResults) = try createTransactionResults()
        
        // 取引結果を登録
        var procStart = Date()
        let transIDs = try await transResultRepo.registerTransactions(results: transResults)
        var procElapsed = Date().timeIntervalSince(procStart)
        log.info("\(type(of: self)): register transaction ok. elapsed=\(procElapsed)")
        
        for (i, tempTransID) in tempTransIDs.enumerated() {
            log.info("\(type(of: self)): upload transaction result ok. tempTransID=\(tempTransID) -> transIDs=\(transIDs[i]), result=\(transResults[i])")
        }
        
        // 仮販売ステータスを完了に変更し、リポジトリに反映
        for tempTrans in patientCardBilling.tempTranses {
            tempTrans.updateStatus(.Complete)
        }
        
        procStart = Date()
        try await tempTransRepo.updateTemporaryTransactions(patientCardBilling.tempTranses)
        procElapsed = Date().timeIntervalSince(procStart)
        log.info("\(type(of: self)): update temporary transaction status ok. elapsed=\(procElapsed)")
        
        // 診察券請求の収納に入金方法と入金金額をセット
        var depositMethod = Shuno.DepositMethodType.Cash
        if kesaiResult.kesaiMethod == .credit {
            depositMethod = .Credit
        }
        log.trace("\(type(of: self)): depositMethod=\(depositMethod)")
        
        if isRegisterShunoEnable {
            // 収納登録処理が有効な場合
            log.info("\(type(of: self)): register shuno enable")
            let depositDateTime = Date.now
            for shuno in patientCardBilling.shunos {
                // 各収納毎の請求金額の合計を入金済みなので、収納の請求金額をそのまま入金額にセット
                shuno.setDeposit(depositDateTime: depositDateTime,
                                 depositMethod: depositMethod,
                                 depositAmount: shuno.billingAmount)
            }
            
            // 入金登録
            procStart = Date()
            try await shunoRepo!.saveShunos(
                patient: patientCardBilling.customer!,
                shunos: patientCardBilling.shunos)
            procElapsed = Date().timeIntervalSince(procStart)
            log.info("\(type(of: self)): save shuno ok. elapsed=\(procElapsed)")
        } else {
            log.info("\(type(of: self)): register shuno disable")
        }
    }
    
    /// 取引結果を生成する
    /// - Returns: 取引結果配列
    func createTransactionResults() throws -> ([TemporaryTransactionID], [TransactionResult]) {
        var tempTransIDs: [TemporaryTransactionID] = []
        var transResults: [TransactionResult] = []
        
        var kesaiDeposit = kesaiResult.deposit.value
        for (i, tempTran) in patientCardBilling.tempTranses.enumerated() {
            var deposit = Amount.Zero
            var depositCash = Amount.Zero
            var change = Amount.Zero
            var depositCredit = Amount.Zero
            switch kesaiResult.kesaiMethod {
            case .cash:
                // 現金決済の場合、「預かり金／預かり現金のオーバー分」と「釣銭」を最後の取引結果に寄せる
                if i < patientCardBilling.tempTranses.count - 1 {
                    deposit = tempTran.total
                    depositCash = tempTran.total
                    change = Amount.Zero
                    
                    kesaiDeposit -= deposit.value
                } else {
                    deposit = try Amount(kesaiDeposit, isMinusAllow: false)
                    depositCash = try Amount(kesaiDeposit, isMinusAllow: false)
                    change = try Amount(kesaiDeposit - tempTran.total.value, isMinusAllow: false)
                }
            case .credit:
                deposit = tempTran.total
                depositCredit = tempTran.total
            }
            
            tempTransIDs.append(tempTran.id)
            
            let transResult = TransactionResult(
                subtotal: tempTran.total,
                total: tempTran.total,
                memo: tempTran.memo,
                storeID: tempTran.storeID,
                customerID: tempTran.customerID,
                kesaiMethod: kesaiResult.kesaiMethod,
                deposit: deposit,
                depositCash: depositCash,
                change: change,
                depositCredit: depositCredit,
                details: tempTran.details.map {
                    TransactionDetail(
                        transactionDetailID: $0.transactionDetailID.value,
                        transactionDetailDivision: $0.transactionDetailDivision,
                        productId: $0.productId,
                        productCode: nil,   // 取引結果登録時のキーは商品IDだけで十分なので指定しない
                        salesPrice: $0.salesPrice,
                        unitDiscountPrice: $0.unitDiscountPrice,
                        quantity: $0.quantity,
                        unitDiscountSum: $0.unitDiscountSum)
                })
            transResults.append(transResult)
        }
        
        return (tempTransIDs, transResults)
    }
}
