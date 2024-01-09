//
//  Groly300AutoCashierAdapter.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/12/18.
//

import Foundation
import Logging

/// グローリー300自動つり銭機アダプタ
final class Groly300AutoCashierAdapter: CashTransactionProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// グローリー300つり銭機通信設定
    private let setting: Setting
    /// コマンド実行
    private let cmdExec: CommandExecutor
    /// 現在の取引
    private var transaction: Transaction?
    /// つり銭機の取引状態を取得するメソッドが呼び出された場合の待機時間
    ///  　→ビジーループにならないようにスリープを入れる
    private static let GET_TRANSACTION_SLEEP_SEC: Double = 0.01
    
    /// コンストラクタ
    init(setting: Setting) {
        self.setting = setting
        cmdExec = CommandExecutor(setting: setting)
    }
    
    /// 通信テストを実施する
    func execCommTest() async throws {
        _ = try await cmdExec.exec(Command.ENQ)
    }
    
    /// つり銭機の取引を開始する（現金取引プロトコル実装）
    /// - Parameter billing: 請求
    /// - Returns: 取引ID
    func startTransaction(billing: BillingProtocol) async throws -> String {
        do {
            let resp = try await cmdExec.exec(Command.KEISU_DATA_READ)
            if resp.match([.DLE]) {
                _ = try KeisuDataReadResponse(resp: resp)
            }
            
            if let transaction = self.transaction {
                if transaction.isDepositFix {
                    // 処理中取引の入金が完了している場合、
                    // 入金完了状態の取引はキャンセルすることはできないため、エラーレスポンス(processing)を返す
                    throw RunError.processing
                }
                
                // 処理中取引の入金が完了していない(入金確定メソッドを実行していない)場合、
                // 処理中の取引をキャンセル後、取引を開始し、新しい取引IDを返す
                try await transaction.cancel()
                await transaction.waitCancelled()
            }
            
            // 取引を生成
            transaction = Transaction(billing: billing, cmdExec: cmdExec)
            try await transaction!.start()
            return transaction!.ID
        } catch {
            throw makeCashTransactionError(error)
        }
    }
    
    /// つり銭機の取引状態を取得する（現金 取引プロトコル実装）
    /// - Parameter transactionID: 取引ID
    /// - Returns: 現金取引状態
    func getTransaction(transactionID: String) async throws -> CashTransctionState {
        guard let transaction = self.transaction else {
            throw CashTransactionError.transaction(message: "transaction has not started yet")
        }
        if transaction.ID != transactionID {
            throw CashTransactionError.transaction(message: "transaction is not found. param=\(transactionID), current=\(transaction.ID)")
        }
        
        let latest = transaction.copy()
        if latest.status == .beginDeposit && latest.error != nil {
            // 取引ステータスが「入金中」につり銭機がエラー状態になった場合、
            // 例外を投げる
            throw makeCashTransactionError(latest.error!)
        }
        
        try await Task.sleep(until: .now + .seconds(Groly300AutoCashierAdapter.GET_TRANSACTION_SLEEP_SEC), clock: .continuous)
        
        // 以下の場合、現金取引状態を返す
        // ・正常稼働時
        // ・取引ステータスが「出金中」、「つり銭抜き取り待ち」のときにつり銭機がエラー状態になった場合
        return CashTransctionState(
            transactionID: latest.ID,
            transactionStatus: latest.status,
            total: latest.billing.amount.value,
            deposit: latest.deposit,
            change: latest.change,
            isCanPayoutChange: latest.isCanPayoutChange,
            dispensedCash: latest.dispensedCash,
            fixDeposit: latest.isDepositFixed,
            seqNo: latest.seqNo,
            startDate: latest.startDate.getISO8601()
        );
    }
    
    /// 指定金額の払出しが可能かどうか
    /// - Parameter amount: 払い出したい金額[円]
    /// - Returns: true:払い出し可、false:払い出し不可
    func canPayoutChange(amount: Int) async throws -> Bool {
        do {
            // 精査コマンドで金銭が不足していないかどうかをチェック
            let seisaResp = try await cmdExec.exec(Command.SEISA)
            let parsedSeisaResp = try SeisaResponse(resp: seisaResp)
            return parsedSeisaResp.canPayout(amount: amount)
        } catch {
            throw makeCashTransactionError(error)
        }
    }
    
    /// 入金完了を要求する（現金取引プロトコル実装）
    func fixDeposit() async throws {
        do {
            try await transaction?.fixDeposit()
        } catch {
            throw makeCashTransactionError(error)
        }
    }
    
    /// つり銭機の取引をキャンセルする（現金取引プロトコル実装）
    func cancelTransaction() async throws {
        do {
            try await transaction?.cancel()
        } catch {
            throw makeCashTransactionError(error)
        }
    }
    
    /// 機器の状態を取得する
    /// - Returns: 機器の状態
    func getMachineStatus() async throws -> MachineState {
        // 今のところ上位モジュールで使用していないので実装しない
        return MachineState(
            bill: Bill(errorCode: 0, setInfo: 0),
            coin: Bill(errorCode: 0, setInfo: 0),
            cashStatus: CashState(the1: "", the5: "", the10: "", the50: "", the100: "", the500: "", the1000: "", the2000: "", the5000: "", the10000: "", billReject: "", cassete: "", overflow: ""),
            cashWrapStatus: CashWrapState(the1: "", the5: "", the10: "", the50: "", the100: "", the500: "", reject: false, opened: false),
            seqNo: 0);
    }
    
    func makeCashTransactionError(_ error: Error) -> CashTransactionError {
        if let runErr = error as? RunError {
            return CashTransactionError.transaction(message: "\(runErr.detail)(\(runErr.title))")
        }
        return CashTransactionError.transaction(message: "error=\(error)")
    }
}

extension Groly300AutoCashierAdapter {
    /// エラー
    private final class RunError: Error, CustomStringConvertible {
        let title: String
        let detail: String
        
        private init(_ title: String, _ detail: String) {
            self.title = title
            self.detail = detail
        }
        
        var description: String {
            return "\(detail)(\(title))"
        }
        
        static let billRejectFull = RunError("billRejectFull", "紙幣リジェクト庫が満杯です。紙幣リジェクト庫の紙幣を回収してください。")
        static let coinRejectFull = RunError("coinRejectFull", "貨幣リジェクト庫が満杯です。貨幣リジェクト庫の紙幣を回収してください。")
        static let busy = RunError("busy", "つり銭機の操作中は実行できません。")
        static let empty = RunError("empty", "つり銭が不足しているためつり銭を出金できません。取引をキャンセルしてつり銭を補充してください。")
        
        static func error(addMessage: String? = nil) -> RunError {
            var detail = "つり銭機がエラー状態です。"
            if let addMessage = addMessage {
                detail += " 内容: \(addMessage)"
            }
            return RunError("error", detail)
        }
        
        static let full = RunError("full", "収納庫が満杯です。")
        
        static func ifError(addMessage: String? = nil) -> RunError {
            var detail = "つり銭機との通信でエラーが発生しました。"
            if let addMessage = addMessage {
                detail += " 内容: \(addMessage)"
            }
            return RunError("ifError", detail)
        }
        
        static let impossible = RunError("impossible", "つり銭機が動作中です。再度実行してください。")
        static let needPullOut = RunError("needPullOut", "貨幣の抜き取りをしてください。")
        static let notReady = RunError("notReady", "つり銭機から応答がありません。")
        static let processing = RunError("processing", "取引処理中のため取引を開始できません。")
        static let failure = RunError("failure", "処理が異常終了しました。")
        static let unknown = RunError("unknown", "予期せぬエラーが発生しました。")
    }
    
    /// 取引
    private final class Transaction {
        private let log = Logger(label: Bundle.main.bundleIdentifier!)
        
        /// 取引ID
        let ID: String
        /// 請求
        let billing: BillingProtocol
        /// 取引開始日時
        let startDate: Date
        /// 取引ステータス
        private(set) var status: CashTransactionStatusType
        /// 取引中に発生したエラー
        private(set) var error: Error?
        /// 入金完了要求フラグ
        private(set) var isDepositFix = false
        /// 入金済みの預かり金額
        private(set) var deposit: Int = 0
        /// 出金予定のつり銭の金額
        private(set) var change: Int = 0
        /// おつり払出し可否
        private(set) var isCanPayoutChange: Bool = false
        /// 出金された金額
        /// ・取引が完了した場合、つり銭の金額
        /// ・取引がキャンセルされた場合、預かり金額
        private(set) var dispensedCash: Int = 0
        /// 入金完了フラグ
        private(set) var isDepositFixed = false
        /// レスポンスの順序を表すシーケンス番号
        /// 　→UNIX時間(ミリ秒)
        private(set) var seqNo: Int64 = 0
        /// コマンド実行
        private let cmdExec: CommandExecutor
        ///  入金シーケンスを実行するタスク
        private var depositTask: Task<(), Never>?
        ///  入金シーケンス終了要求フラグ
        private var isDepositSequenceCancel = false
        ///  入金完了シーケンスを実行するタスク
        private var fixTask: Task<(), Never>?
        ///  キャンセルシーケンスを実行するタスク
        private var cancelTask: Task<(), Never>?
        
        private let lock = NSLock()
        
        init(billing: BillingProtocol, cmdExec: CommandExecutor) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmmss", options: 0, locale: Locale(identifier: "ja_JP"))
            ID = dateFormatter.string(from: .now)
            
            self.billing = billing
            startDate = .now
            status = .beginDeposit
            
            self.cmdExec = cmdExec
        }
        
        init(transaction: Transaction) {
            ID = transaction.ID
            billing = transaction.billing
            startDate = transaction.startDate
            status = transaction.status
            error = transaction.error
            isDepositFix = transaction.isDepositFix
            deposit = transaction.deposit
            change = transaction.change
            isCanPayoutChange = transaction.isCanPayoutChange
            dispensedCash = transaction.dispensedCash
            isDepositFixed = transaction.isDepositFixed
            seqNo = transaction.seqNo
            cmdExec = transaction.cmdExec
        }
        
        func copy() -> Transaction {
            lock.lock()
            defer { lock.unlock() }
            
            return Transaction(transaction: self)
        }
        
        func start() async throws {
            // 預かり金計数開始
            _ = try await cmdExec.exec(Command.KEISU_START)
            
            // 入金シーケンスをを非同期実行
            depositTask = Task {
                do {
                    try await execDepositSequence()
                } catch {
                    setError(error)
                }
            }
        }
        
        /// 入金シーケンスを実行する
        private func execDepositSequence() async throws {
            while !isDepositSequenceCancel {
                // 入金計数データリード
                let readResp = try await cmdExec.exec(Command.KEISU_DATA_READ)
                if !readResp.match([.DLE]) {
                    // 復帰可能なキャラクタもあるため待機
                    // ・出金口に手がある場合(SUB)
                    continue
                }
                
                // 計数データリードを解析
                let parsedReadResp = try KeisuDataReadResponse(resp: readResp)
                
                // おつり払出しが必要かを確認
                // 　→投入金額が請求金額を超えたらおつり払出しあり
                var isCanPayoutChange = false
                let change = parsedReadResp.deposit - billing.amount.value
                if change > 0 {
                    // おつり払出し可否を取得
                    isCanPayoutChange = try await self.canPayoutChange(amount: change)
                }
                
                updateDeposit(parsedReadResp.deposit, isCanPayoutChange: isCanPayoutChange)
            }
        }
        
        // 入金シーケンスをキャンセルする
        private func cancelDepositSequence() async {
            guard let depositTask = self.depositTask else {
                return
            }
            
            // 入金シーケンスタスクをキャンセルする
            // 　→タスクのキャンセルメソッドを使用する方法(※)もあるが、処理の途中でも例外が発生して強制終了するため使用しない
            // 　　※depositTask.cancel()
            isDepositSequenceCancel = true
            _ = await depositTask.result
            self.depositTask = nil
        }
        
        /// 指定金額の払出しが可能かどうか
        /// - Parameter amount: 払い出したい金額[円]
        /// - Returns: true:払い出し可、false:払い出し不可
        func canPayoutChange(amount: Int) async throws -> Bool {
            do {
                // 精査コマンドで金銭が不足していないかどうかをチェック
                let seisaResp = try await cmdExec.exec(Command.SEISA)
                let parsedSeisaResp = try SeisaResponse(resp: seisaResp)
                return parsedSeisaResp.canPayout(amount: amount)
            } catch {
                throw RunError.ifError(addMessage: error.localizedDescription)
            }
        }
        
        func fixDeposit() async throws {
            await cancelDepositSequence()
            
            // 計数停止
            _ = try await cmdExec.exec(Command.KEISU_STOP)
            
            // 入金完了シーケンスを非同期実行
            fixTask = Task {
                do {
                    try await execFixSequence()
                } catch {
                    setError(error)
                }
            }
        }
        
        /// 入金完了シーケンスを実行する
        private func execFixSequence() async throws {
            // 入金計数データリードにて装置状態が計数停止中(=計数動作中以外)になるまで
            while true {
                // 入金計数データリード
                let readResp = try await cmdExec.exec(Command.KEISU_DATA_READ)
                if !readResp.match([.DLE]) {
                    // 復帰可能なキャラクタもあるため待機
                    // ・出金口に手がある場合(SUB)
                    continue
                }
                let parsedReadResp = try KeisuDataReadResponse(resp: readResp)
                updateDeposit(parsedReadResp.deposit)
                
                if parsedReadResp.deviceStatus != 1 {
                    // 計数動作中以外になった場合
                    break
                }
            }
            
            // 計数終了
            _ = try await cmdExec.exec(Command.KEISU_END)
            
            // 払い出す金額を確定
            while true {
                // 計数データリード
                let readResp = try await cmdExec.exec(Command.KEISU_DATA_READ)
                if !readResp.match([.DLE]) {
                    // 復帰可能なキャラクタもあるため待機
                    // ・出金口に硬貨が残っている、手がある場合(SUB)
                    continue
                }
                
                let parsedReadResp = try KeisuDataReadResponse(resp: readResp)
                updateDeposit(parsedReadResp.deposit)
                break
            }
            
            if change == 0 {
                // おつりの払い出しが不要な場合
                updateStatus(.finish)
                setFixDeposit()
                return
            }
            
            // 精査コマンドでつり銭が不足していないかどうかをチェック
            let seisaResp = try await cmdExec.exec(Command.SEISA)
            let parsedSeisaResp = try SeisaResponse(resp: seisaResp)
            if !parsedSeisaResp.canPayout(amount: change) {
                throw RunError.empty
            }
            
            updateStatus(.dispenseChange)
            setFixDeposit()
            
            // 金額指定放出
            _ = try await cmdExec.exec(Command.PAYOUT_AMOUNT(amount: change))
            
            // 入金計数データリードのENQレスポンスがSUB(動作中)/DC2(抜き取り待ち)の間ループ
            while true {
                // ENQコマンドでつり銭機の状態を取得
                let enqResp = try await cmdExec.exec(Command.ENQ)
                try enqResp.checkOK(okCtrlChars: [.ACK, .ETB, .SUB, .DC2])
                
                if !enqResp.match([.SUB, .DC2]){
                    break
                }
                
                // 計数データリード
                let readResp = try await cmdExec.exec(Command.KEISU_DATA_READ)
                if !readResp.match([.DLE]) {
                    // 復帰可能なキャラクタもあるため待機
                    // ・出金口に手がある場合(SUB)
                    continue
                }
                
                let parsedReadResp = try KeisuDataReadResponse(resp: readResp)
                updateDeposit(parsedReadResp.deposit)
                
                if parsedReadResp.isWaitPullOut(){
                    updateStatus(.waitPullOut)
                }
            }
            
            setDispensedCash(change)
            updateStatus(.finish)
        }
        
        func cancel() async throws {
            await cancelDepositSequence()
            
            do {
                // 計数停止
                _ = try await cmdExec.exec(Command.KEISU_STOP)
            } catch {
                // 既に計数中を停止している場合は、つり銭機からエラーレスポンスが返ってくるが無視する
                // ※つり銭不足で払い出しができなかった場合のキャンセル時など
            }
            
            // キャンセルシーケンスを非同期実行
            cancelTask = Task {
                do {
                    try await execCancelSequence()
                } catch {
                    setError(error)
                }
            }
        }
        
        func waitCancelled() async {
            _ = await cancelTask?.result
        }
        
        /// キャンセルシーケンスを実行する
        private func execCancelSequence() async throws {
            // 入金計数データリードにて装置状態が計数停止中(=計数動作中以外)になるまで
            while true {
                // 入金計数データリード
                let readResp = try await cmdExec.exec(Command.KEISU_DATA_READ)
                if !readResp.match([.DLE]) {
                    // 復帰可能なキャラクタもあるため待機
                    // ・出金口に手がある場合(SUB)
                    continue
                }
                
                let parsedReadResp = try KeisuDataReadResponse(resp: readResp)
                updateDeposit(parsedReadResp.deposit)
                
                if parsedReadResp.deviceStatus != 1 {
                    // 計数動作中以外になった場合
                    break
                }
            }
            
            do {
                // 計数終了
                _ = try await cmdExec.exec(Command.KEISU_END)
            } catch {
                // 既に計数中を停止している場合は、つり銭機からエラーレスポンスが返ってくるが無視する
                // ※つり銭不足で払い出しができなかった場合のキャンセル時など
            }
            
            // 払い出す金額を確定
            while true {
                // 計数データリード
                let readResp = try await cmdExec.exec(Command.KEISU_DATA_READ)
                if !readResp.match([.DLE]) {
                    // 復帰可能なキャラクタもあるため待機
                    // ・出金口に硬貨が残っている、手がある場合(SUB)
                    continue
                }
                
                let parsedReadResp = try KeisuDataReadResponse(resp: readResp)
                updateDeposit(parsedReadResp.deposit)
                break
            }
            
            if deposit == 0 {
                // 預かり金が無い場合
                updateStatus(.cancel)
                setFixDeposit()
                return
            }
            
            // 精査コマンドで預かり金が不足していないかどうかをチェック
            let seisaResp = try await cmdExec.exec(Command.SEISA)
            let parsedSeisaResp = try SeisaResponse(resp: seisaResp)
            if !parsedSeisaResp.canPayout(amount: deposit) {
                throw RunError.empty
            }
            
            updateStatus(.dispenseChange)
            setFixDeposit()
            
            // 金額指定放出
            _ = try await cmdExec.exec(Command.PAYOUT_AMOUNT(amount: deposit))
            
            // 入金計数データリードのENQレスポンスがSUB(動作中)/DC2(抜き取り待ち)の間ループ
            while true {
                // ENQコマンドでつり銭機の状態を取得
                let enqResp = try await cmdExec.exec(Command.ENQ)
                try enqResp.checkOK(okCtrlChars: [.ACK, .ETB, .SUB, .DC2])
                
                if !enqResp.match([.SUB, .DC2]){
                    break
                }
                
                // 計数データリード
                let readResp = try await cmdExec.exec(Command.KEISU_DATA_READ)
                if !readResp.match([.DLE]) {
                    // 復帰可能なキャラクタもあるため待機
                    // ・出金口に手がある場合(SUB)
                    continue
                }
                
                let parsedReadResp = try KeisuDataReadResponse(resp: readResp)
                updateDeposit(parsedReadResp.deposit)
                
                if parsedReadResp.isWaitPullOut(){
                    updateStatus(.waitPullOut)
                }
            }
            
            setDispensedCash(deposit)
            updateStatus(.cancel)
        }
        
        /// 取引ステータスを更新する
        /// - Parameter status: 取引ステータス
        private func updateStatus(_ status: CashTransactionStatusType) {
            lock.lock()
            defer { lock.unlock() }
            updateSeqNo()
            
            self.status = status
        }
        
        /// 取引中に発生したエラーをセットする
        /// - Parameter error: エラー
        private func setError(_ error: Error) {
            lock.lock()
            defer { lock.unlock() }
            updateSeqNo()
            
            self.error = error
        }
        
        /// 入金完了要求フラグを立てる
        private func setFixDepositRequest() {
            lock.lock()
            defer { lock.unlock() }
            updateSeqNo()
            
            isDepositFix = true
        }
        
        /// 入金済みの預かり金額を更新する。
        /// また、出金予定のつり銭の金額も更新する
        /// - Parameter deposit: 入金済みの預かり金額
        /// - Parameter isCanPayoutChange: おつり払い出し可否
        private func updateDeposit(_ deposit: Int, isCanPayoutChange: Bool? = nil) {
            lock.lock()
            defer { lock.unlock() }
            updateSeqNo()
            
            self.deposit = deposit
            
            if let isCanPayoutChange = isCanPayoutChange {
                self.isCanPayoutChange = isCanPayoutChange
            }
            
            // 出金予定のつり銭の金額を計算
            change = self.deposit - billing.amount.value
            if change < 0 {
                change = 0
            }
        }
        
        /// 出金された金額をセットする
        /// - Parameter dispensedCash: 出金された金額
        private func setDispensedCash(_ dispensedCash: Int) {
            lock.lock()
            defer { lock.unlock() }
            updateSeqNo()
            
            self.dispensedCash = dispensedCash
        }
        
        /// 入金完了フラグを立てる
        private func setFixDeposit() {
            lock.lock()
            defer { lock.unlock() }
            updateSeqNo()
            
            isDepositFixed = true
        }
        
        private func updateSeqNo() {
            let sec = Date.now.timeIntervalSince1970
            seqNo = Int64(sec * 1000)
        }
    }
    
    /// コマンド実行
    private final class CommandExecutor {
        private let log = Logger(label: Bundle.main.bundleIdentifier!)
        
        let setting: Setting
        /// コマンドの最終実行時刻
        private var lastExecTime = Date.now
        
        init(setting: Setting) {
            self.setting = setting
        }
        
        /// コマンド実行
        /// - Parameter cmd: コマンド
        /// - Returns: レスポンス
        func exec(_ cmd: Command) async throws -> Response {
            var sizeSetting: RespSizeSetting
            if cmd.isLargeSizeResp {
                sizeSetting = setting.largeSizeResp
            } else {
                sizeSetting = setting.smallSizeResp
            }
            
            var recvDelay = sizeSetting.baseWaitSec
            var retryCount = 0
            while true {
                waitExec()
                defer { updateLastExecTime() }
                
                do {
                    let resp = try await execCmdSequence(cmd, recvDelay: recvDelay)
                    return resp
                } catch {
                    recvDelay += sizeSetting.incTimeSec
                    retryCount += 1
                    if retryCount <= sizeSetting.retryCount {
                        log.warning("\(type(of: self)): retry command. code=\(cmd.code) retryCount=\(retryCount)")
                        continue
                    }
                    throw error
                }
            }
        }
        
        private func execCmdSequence(_ cmd: Command, recvDelay: Double) async throws -> Response {
            // コマンド送信
            log.trace("\(type(of: self)): send command start. code=\(cmd.code)")
            let sendStart = Date()
            let tcpClient = try await send(cmd)
            let sendElapsed = Date().timeIntervalSince(sendStart)
            log.trace("\(type(of: self)): send command ok. code=\(cmd.code) elapsed=\(sendElapsed)")
            defer { tcpClient.close() }
            
            // レスポンスのすっぽ抜け回避のためにスリープ
            try await Task.sleep(until: .now + .seconds(recvDelay), clock: .continuous)
            
            // レスポンス受信シーケンスを実行
            // 　　・応答がない場合のシーケンス（※300Serインターフェイス仕様書のタイマー監視仕様に従う[P.11]）
            // 　　　【概要】
            // 　　　　　1.5秒待っても応答がない場合は、ENQコマンドを送信し0.3秒待つ
            // 　　　　　　→ENQコマンドの応答がある場合は、レスポンスを待つ
            // 　　　　　　　　※仕様書に待機時間の記述は無い
            // 　　　　　　→ENQコマンドの応答がない場合は、EOTを送信し通信をリセットする
            var resp: Response?
            do {
                let recvStart = Date()
                
                resp = try await recvResponse(tcpClient: tcpClient, headTimeoutSec: 1.5)
                
                let recvElapsed = Date().timeIntervalSince(recvStart)
                log.trace("\(type(of: self)): recv response elapsed=\(recvElapsed)")
            } catch AsyncTCPClient.RunError.timeout {
                log.warning("\(type(of: self)): recv timeout")
                tcpClient.close()
                
                // ENQ送信
                let enqTcpClient = try await send(Command.ENQ)
                defer { enqTcpClient.close() }
                log.info("\(type(of: self)): ENQ send ok")
                
                do {
                    // レスポンスのすっぽ抜け回避のためにスリープ
                    try await Task.sleep(until: .now + .seconds(0.1), clock: .continuous)
                    
                    _ = try await recvResponse(tcpClient: enqTcpClient, headTimeoutSec: 0.3)
                    log.info("\(type(of: self)): ENQ reponse recv ok")
                } catch AsyncTCPClient.RunError.timeout {
                    enqTcpClient.close()
                    
                    // EOT送信
                    let eotTcpClient = try await send(Command.ENQ)
                    eotTcpClient.close()
                    log.info("\(type(of: self)): EOT reponse recv ok")
                }
                
                throw RunError.notReady
            }
            
            // エラーレスポンスの場合は例外を投げる
            try resp!.checkError(errorCtrlChars: cmd.errorRespChars)
            
            return resp!
        }
        
        private func send(_ cmd: Command) async throws -> AsyncTCPClient {
            // 非同期TCPクライアントを生成
            let tcpClient = AsyncTCPClient(
                dispatchQueue: DispatchQueue(label: "Groly300AutoCashierAdapter"),
                host: setting.ipAddr,
                port: setting.port,
                connectionTimeoutSec: setting.connectionTimeoutSec);
            do {
                try await tcpClient.connect()
            } catch {
                tcpClient.close()
                throw RunError.notReady
            }
            
            do {
                try await tcpClient.send(data: cmd.value, timeout: TimeInterval(setting.connectionTimeoutSec))
            } catch {
                tcpClient.close()
                throw RunError.ifError(addMessage: error.localizedDescription)
            }
            
            return tcpClient
        }
        
        /// レスポンスを受信する
        /// - Parameter tcpClient: 非同期TCPクライアント
        /// - Parameter headTimeoutSec: 先頭データに対する受信タイムアウト時間[秒]
        /// - Returns: レスポンス
        private func recvResponse(tcpClient: AsyncTCPClient, headTimeoutSec: TimeInterval) async throws -> Response {
            var recvData: [UInt8] = []
            
            // 先頭1バイトを受信
            try await tcpClient.recv(wantLength: 1, timeout: headTimeoutSec, received: { data in recvData.append(contentsOf: data) })
            
            guard let ctrlChar = CtrlChar.parse(recvData[0]) else {
                throw RunError.ifError(addMessage: "ctrl code is unknown. value=\(recvData[0])")
            }
            if ctrlChar != CtrlChar.DLE {
                // 先頭がDLE以外の場合はデータなしレスポンス
                // 　→レスポンスのデータ部があるコマンドでもエラーレスポンス（NAKなど）の場合はデータがないため、データなしレスポンスを返す
                return Response(ctrlChar: ctrlChar, dataStr: nil)
            }
            
            // STX（テキスト開始）
            try await tcpClient.recv(wantLength: 1, timeout: TimeInterval(setting.connectionTimeoutSec), received: { data in recvData.append(contentsOf: data) })
            if recvData[1] != CtrlChar.STX.rawValue {
                throw RunError.ifError(addMessage: "response STX is not found. recvData=\(recvData)")
            }
            
            // データ部の長さ
            // 　→インデックス2〜3に16進数文字列で格納されている
            try await tcpClient.recv(wantLength: 2, timeout: TimeInterval(setting.connectionTimeoutSec), received: { data in recvData.append(contentsOf: data) })
            guard let dataLengthHexStr = String(bytes: recvData[2...3], encoding: .ascii) else {
                throw RunError.ifError(addMessage: "response length part is not ascii code. recvData=\(recvData)")
            }
            guard let dataLengthU32 = UInt32(dataLengthHexStr, radix: 16) else {
                throw RunError.ifError(addMessage: "response length part is not hex string. recvData=\(recvData)")
            }
            let dataLength = UInt8(dataLengthU32)
            
            // 「データ部＋ETX(1バイト)+BCC(1バイト)」を受信
            try await tcpClient.recv(wantLength: Int(dataLength) + 2, timeout: TimeInterval(setting.connectionTimeoutSec), received: { data in recvData.append(contentsOf: data) })
            
            // ETX（テキスト終了）
            // 　→インデックスは末尾から2番目
            let etxIndex = recvData.count - 2
            if recvData[etxIndex] != CtrlChar.ETX.rawValue {
                throw RunError.ifError(addMessage: "response STX is not found. recvData=\(recvData)")
            }
            
            // パリティチェック
            //  →STXの次のデータからETXまで
            let actualBCC = Parity.calcLRC(Array(recvData[2...etxIndex]))
            let wantBCC = recvData[recvData.count-1]
            if actualBCC != wantBCC {
                throw RunError.ifError(addMessage: "response parity is invalid. want=\(wantBCC), actual=\(actualBCC), recvData=\(recvData)")
            }
            
            // データ部を取得｀
            let dataEndIndex =  4+Int(dataLength)-1
            guard let dataStr = String(bytes: recvData[4...dataEndIndex], encoding: .ascii) else {
                throw RunError.ifError(addMessage: "response data is not string. recvData=\(recvData)")
            }
            
            return Response(ctrlChar: ctrlChar, dataStr: dataStr)
        }
        
        /// コマンド実行間隔を空けるために待機する
        private func waitExec() {
            // 前回実行時からの経過時間[秒]を計算し、指定された時間だけ待機
            let elapsedSec = Date().timeIntervalSince(lastExecTime)
            let waitSec = setting.commandIntervalSec - elapsedSec
            if waitSec <= 0 {
                return
            }
            Thread.sleep(forTimeInterval: TimeInterval(waitSec))
        }
        
        /// コマンドの最終実行時刻を更新する
        private func updateLastExecTime() {
            lastExecTime = Date.now
        }
    }
        
    /// コマンド
    private final class Command {
        let code: UInt8
        let value: [UInt8]
        let errorRespChars: Set<CtrlChar>
        /// レスポンスサイズが大きいコマンドかどうか
        /// 　→レスポンスサイズが大きい場合、コマンド送信後しばらく待ってからレスポンス受信開始しないとレスポンスを受信できないことがある
        /// 　→本フラグがtrueの場合
        /// 　　・コマンド送信〜レスポンス受信間の待ち時間を長くする
        /// 　　・リトライ毎に待ち時間を少しずつ長くする
        let isLargeSizeResp: Bool
        
        /// 応答のあるコマンドを生成する
        /// - Parameters:
        ///   - code: コード
        ///   - dataStr: データ文字列
        ///   - errorRespChars: エラーレスポンスキャラクタ
        ///   - isLargeSizeResp: レスポンスサイズが大きいコマンドかどうかを示すフラグ
        private init(_ code: UInt8, _ dataStr: String, _ errorRespChars: Set<CtrlChar>, _ isLargeSizeResp: Bool) {
            self.code = code
            
            let dataStrBytes = [UInt8](dataStr.utf8)
            let dataLengthStr = String(format: "%02X", dataStrBytes.count)
            let dataLengthStrBytes = [UInt8](dataLengthStr.utf8)
            
            var v = [
                CtrlChar.STX.rawValue,
                CtrlChar.DC1.rawValue,
                code,
                dataLengthStrBytes[0],
                dataLengthStrBytes[1]
            ]
            v.append(contentsOf: dataStrBytes)
            v.append(CtrlChar.ETX.rawValue)
            v.append(Parity.calcLRC(Array(v[1...]))) // 水平パリティ計算(２バイト目から)
            value = v
            
            self.errorRespChars = errorRespChars
            self.isLargeSizeResp = isLargeSizeResp
        }
        
        /// 応答のないコマンド、もしくは、ENQコマンドを生成する
        /// - Parameter code: コード
        private init(_ code: UInt8) {
            self.code = code
            value = [code]
            self.errorRespChars = []
            self.isLargeSizeResp = false
        }
        
        /// EOT
        static let EOT = Command(0x04)
        /// ENQ
        static let ENQ = Command(0x05)
        
        /// 金額指定放出
        /// ※CAN応答：機内収納在高以上の放出指示があった場合の応答　→つり銭機は動作を行わずに異常終了する
        static func PAYOUT_AMOUNT(amount: Int) -> Command {
            return Command(0x31, String(format: "%06d", amount), [.NAK], false)
        }
        
        /// 精査
        static let SEISA = Command(0x32, "", [.NAK, .SUB, .DC4], true)
        
        /// 枚数指定放出
        /// ※スマレジ開発チームが枚数放出ではなく、金額指定放出を使用していたため、それに合わせる。このコマンドは使用しない
        /// ※CAN応答：機内収納在高以上の放出指示があった場合の応答　→つり銭機は動作を行わずに異常終了する
        static func PAYOUT_NUMBER(payoutReq: PayoutNumberRequestData) -> Command {
            var dataStr: String = ""
            dataStr += String(format: "%03d", payoutReq.the2000)
            dataStr += String(format: "%03d", payoutReq.the10000)
            dataStr += String(format: "%03d", payoutReq.the5000)
            dataStr += String(format: "%03d", payoutReq.the1000)
            dataStr += String(format: "%03d", payoutReq.the500)
            dataStr += String(format: "%03d", payoutReq.the100)
            dataStr += String(format: "%03d", payoutReq.the50)
            dataStr += String(format: "%03d", payoutReq.the10)
            dataStr += String(format: "%03d", payoutReq.the5)
            dataStr += String(format: "%03d", payoutReq.the1)
            return Command(0x35, dataStr, [.NAK, .BEL, .CAN], false)
        }
        
        /// 計数データリード
        static let KEISU_DATA_READ = Command(0x41, "", [.NAK, .SUB, .DC4], true)
        /// 預かり金計数開始
        static let KEISU_START = Command(0x45, "", [.NAK, .BEL], false)
        /// 計数終了
        static let KEISU_END = Command(0x46, "", [.NAK, .BEL], false)
        /// 計数停止
        static let KEISU_STOP = Command(0x47, "", [.NAK, .BEL], false)
    }
    
    /// レスポンス
    private final class Response {
        let ctrlChar: CtrlChar
        let dataStr: String?
        
        init(ctrlChar: CtrlChar, dataStr: String?) {
            self.ctrlChar = ctrlChar
            self.dataStr = dataStr
        }
        
        func match(_ ctrlChars: Set<CtrlChar>) -> Bool {
            return ctrlChars.contains(ctrlChar)
        }
        
        func checkError(errorCtrlChars: Set<CtrlChar>) throws {
            if !match(errorCtrlChars) {
                return
            }
            
            try execErrorThrowing()
        }
        
        
        func checkOK(okCtrlChars: Set<CtrlChar>) throws {
            if match(okCtrlChars) {
                return
            }
            
            try execErrorThrowing()
        }
        
        private func execErrorThrowing() throws {
            switch ctrlChar {
            case .CAN:
                throw RunError.failure
            case .NAK:
                throw RunError.ifError(addMessage: "response is NAK")
            case .BEL:
                throw RunError.impossible
            default:
                break
            }
        }
    }
    
    /// 伝送制御キャラクタ（ASCIIコード）
    private enum CtrlChar: UInt8 {
        case NUL = 0x00
        /// 計数中
        case SOH = 0x01
        /// テキストの開始を意味するコード（テキスト開始）
        case STX = 0x02
        /// テキストの終了を意味するコード（テキスト終了）
        case ETX = 0x03
        /// 正常終了（受信確認）
        case ACK = 0x06
        /// 動作不可（警告）
        case BEL = 0x07
        /// レスポンスの先頭（データリンクエスケープ）
        case DLE = 0x10
        /// 起動を意味するコード（装置制御1）
        case DC1 = 0x11
        /// 抜き取り待ち（装置制御2）
        case DC2 = 0x12
        /// セットはずれ（装置制御3）
        case DC3 = 0x13
        /// 放出可動作中（装置制御4）
        case DC4 = 0x14
        /// 通信異常（受信失敗）
        case NAK = 0x15
        /// ニアエンプティ（転送ブロック終了）
        case ETB = 0x17
        /// 異常終了（キャンセル）
        case CAN = 0x18
        /// 計数停止中（メディア終了）
        case EM = 0x19
        /// 動作中（置換）
        case SUB = 0x1A
        
        /// 伝送制御キャラクタを解析する
        /// - Parameter b: バイト値
        /// - Returns: 伝送制御キャラクタ
        static func parse(_ b: UInt8) -> CtrlChar? {
            var ctrlChar: CtrlChar? = nil
            switch b {
            case CtrlChar.ACK.rawValue:
                ctrlChar = .ACK
            case CtrlChar.CAN.rawValue:
                ctrlChar = .CAN
            case CtrlChar.ETB.rawValue:
                ctrlChar = .ETB
            case CtrlChar.NAK.rawValue:
                ctrlChar = .NAK
            case CtrlChar.DC3.rawValue:
                ctrlChar = .DC3
            case CtrlChar.SUB.rawValue:
                ctrlChar = .SUB
            case CtrlChar.DC4.rawValue:
                ctrlChar = .DC4
            case CtrlChar.SOH.rawValue:
                ctrlChar = .SOH
            case CtrlChar.EM.rawValue:
                ctrlChar = .EM
            case CtrlChar.BEL.rawValue:
                ctrlChar = .BEL
            case CtrlChar.DC2.rawValue:
                ctrlChar = .DC2
            case CtrlChar.DLE.rawValue:
                ctrlChar = .DLE
            default:
                break
            }
            return ctrlChar
        }
    }
    
    /// 計数データリードのレスポンス
    private final class KeisuDataReadResponse {
        /// 計数情報
        /// 　1:計数処理中、1以外:計数処理中以外
        let keisuInfo: UInt8
        /// 計数停止
        /// 　0:計数停止コマンド未受信、1:受信済み
        let keisuStop: Bool
        /// 装置状態
        /// 　0:その他、1:計数動作中（SOHと同等）、2:計数停止中（EMと同等）
        let deviceStatus: UInt8
        /// 紙幣挿入口情報
        /// 　0:紙幣なし、1:紙幣あり
        let billSlotInfo: Bool
        /// 紙幣部詳細情報
        ///　0:その他、1:計数待機中、2:計数動作中、3:エラー中、4:払出RJ抜取り待ち、5:カセットフル、6:セット外れ、7:リセット中、8:回収中
        let billPartDetailInfo: UInt8
        /// 硬貨投入口情報
        /// 　0:硬貨なし、1:硬貨あり
        let coinSlotInfo: Bool
        /// 硬貨部詳細情報
        /// 　0:その他、1:計数待機中、2:計数動作中、3:エラー中、4:RJ部フル、5:収納部フル、6:セット外れ、7:リセット中、8:回収中、9:回収中抜取り待ち
        let coinPartDetailInfo: UInt8
        /// 10000円処理枚数
        let the10000: UInt16
        /// 5000円処理枚数
        let the5000: UInt16
        /// 2000円処理枚数
        let the2000: UInt16
        /// 1000円処理枚数
        let the1000: UInt16
        /// 500円処理枚数
        let the500: UInt16
        /// 100円処理枚数
        let the100: UInt16
        /// 50円処理枚数
        let the50: UInt16
        /// 10円処理枚数
        let the10: UInt16
        /// 5円処理枚数
        let the5: UInt16
        /// 1円処理枚数
        let the1: UInt16
        /// 装置接続情報 - 硬貨部
        /// 　0固定
        let coinPartConnectStatus: UInt8
        /// 装置接続情報 - 紙幣部
        /// 　0:接続、1:切り離し
        let billPartConnectStatus: UInt8
        /// 預かり金
        let deposit: Int
        
        init(resp: Response) throws {
            guard let dataStr = resp.dataStr else {
                throw RunError.ifError(addMessage: "keisu data read data is not exist. length=\(resp.dataStr!.count)")
            }
            
            /// レスポンスのデータ部の長さをチェック
            if dataStr.count < 39 {
                throw RunError.ifError(addMessage: "keisu data read data length is invalid. length=\(dataStr.count)")
            }
            
            do {
                let dataElems = Array(dataStr)
                self.keisuInfo = try UInt8.fromString(dataElems[0], radix: 10)
                self.keisuStop = (String(dataElems[1]) == "0" ? false: true)
                self.deviceStatus = try UInt8.fromString(dataElems[2], radix: 10)
                self.billSlotInfo = (String(dataElems[3]) == "0" ? false: true)
                self.billPartDetailInfo = try UInt8.fromString(dataElems[4], radix: 10)
                self.coinSlotInfo = (String(dataElems[5]) == "0" ? false: true)
                self.coinPartDetailInfo = try UInt8.fromString(dataElems[6], radix: 10)
                self.the10000 = try UInt16.fromString(dataElems[7...9], radix: 10)
                self.the5000 = try UInt16.fromString(dataElems[10...12], radix: 10)
                self.the2000 = try UInt16.fromString(dataElems[13...15], radix: 10)
                self.the1000 = try UInt16.fromString(dataElems[16...18], radix: 10)
                self.the500 = try UInt16.fromString(dataElems[19...21], radix: 10)
                self.the100 = try UInt16.fromString(dataElems[22...24], radix: 10)
                self.the50 = try UInt16.fromString(dataElems[25...27], radix: 10)
                self.the10 = try UInt16.fromString(dataElems[28...30], radix: 10)
                self.the5 = try UInt16.fromString(dataElems[31...33], radix: 10)
                self.the1 = try UInt16.fromString(dataElems[34...36], radix: 10)
                
                let d37 = try UInt8.fromString(String(dataElems[37]), radix: 10)
                self.coinPartConnectStatus = (d37 & 0x02) >> 1
                self.billPartConnectStatus = (d37 & 0x01)
                
                switch billPartDetailInfo {
                case 3:
                    // 3:エラー中
                    throw RunError.error()
                case 4:
                    // 4:払出RJ抜取り待ち
                    // 　→払い出した紙幣の抜き取り待ち
                    break
                case 5:
                    // 5:カセットフル
                    throw RunError.full
                case 6, 7, 8:
                    // 6:セット外れ（ユニット又は、カセットが セット外れの状態）
                    // 7:リセット中
                    // 8:回収中
                    throw RunError.busy
                default:
                    break
                }
                
                switch coinPartDetailInfo {
                case 3:
                    // 3:エラー中
                    throw RunError.error()
                case 4:
                    // 4:RJ部フル
                    // 　→払い出した硬貨の抜き取り待ち
                    break
                case 5:
                    // 5:収納部フル
                    throw RunError.full
                case 6, 7, 8, 9:
                    // 6:セット外れ
                    // 7:リセット中（ユニット又は、カセットが セット外れの状態）
                    // 8:回収中
                    // 9:回収中抜取り待ち
                    throw RunError.busy
                default:
                    break
                }
                
                var deposit = 0
                deposit += (10000 * Int(the10000))
                deposit += (5000 * Int(the5000))
                deposit += (1000 * Int(the1000))
                deposit += (2000 * Int(the2000))
                deposit += (500 * Int(the500))
                deposit += (100 * Int(the100))
                deposit += (50 * Int(the50))
                deposit += (10 * Int(the10))
                deposit += (5 * Int(the5))
                deposit += (1 * Int(the1))
                self.deposit = deposit
            } catch {
                throw RunError.ifError(addMessage: "seisa data format is invalid: \(error)")
            }
        }
        
        func isWaitPullOut() -> Bool {
            return billPartDetailInfo == 4 || coinPartDetailInfo == 4
        }
    }
    
    /// 枚数指定放出要求データ
    /// ※スマレジ開発チームが枚数放出ではなく、金額指定放出を使用していたため、それに合わせる。このコマンドは使用しない
    private final class PayoutNumberRequestData {
        /// 10000円処理枚数
        let the10000: UInt16
        /// 5000円処理枚数
        let the5000: UInt16
        /// 2000円処理枚数
        let the2000: UInt16
        /// 1000円処理枚数
        let the1000: UInt16
        /// 500円処理枚数
        let the500: UInt16
        /// 100円処理枚数
        let the100: UInt16
        /// 50円処理枚数
        let the50: UInt16
        /// 10円処理枚数
        let the10: UInt16
        /// 5円処理枚数
        let the5: UInt16
        /// 1円処理枚数
        let the1: UInt16
        
        init(dataReadResp: KeisuDataReadResponse) {
            the10000 = dataReadResp.the10000
            the5000 = dataReadResp.the5000
            the2000 = dataReadResp.the2000
            the1000 = dataReadResp.the1000
            the500 = dataReadResp.the500
            the100 = dataReadResp.the100
            the50 = dataReadResp.the50
            the10 = dataReadResp.the10
            the5 = dataReadResp.the5
            the1  = dataReadResp.the1
        }
    }
    
    /// 精査のレスポンス
    private final class SeisaResponse {
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
        
        let canPayout: CanPayout
        
        init(resp: Response) throws {
            guard let dataStr = resp.dataStr else {
                throw RunError.ifError(addMessage: "seisa data is not exist. length=\(resp.dataStr!.count)")
            }
            
            /// レスポンスのデータ部の長さをチェック
            if dataStr.count < 118 {
                throw RunError.ifError(addMessage: "seisa data length is invalid. length=\(dataStr.count)")
            }
            
            do {
                let dataElems = Array(dataStr)
                self.the2000 = try UInt16.fromString(dataElems[0...2], radix: 10)
                self.the10000 = try UInt16.fromString(dataElems[3...5], radix: 10)
                self.the5000 = try UInt16.fromString(dataElems[6...8], radix: 10)
                self.the1000 = try UInt16.fromString(dataElems[9...11], radix: 10)
                
                // カセットの枚数は使用しないため、解析しない
                //                self.cassette2000 = try UInt16.fromString(dataElems[12...14], radix: 10)
                //                self.cassette10000 = try UInt16.fromString(dataElems[15...17], radix: 10)
                //                self.cassette5000 = try UInt16.fromString(dataElems[18...20], radix: 10)
                //                self.cassette1000 = try UInt16.fromString(dataElems[21...23], radix: 10)
                
                self.the500 = try UInt16.fromString(dataElems[24...26], radix: 10)
                self.the100 = try UInt16.fromString(dataElems[27...29], radix: 10)
                self.the50 = try UInt16.fromString(dataElems[30...32], radix: 10)
                self.the10 = try UInt16.fromString(dataElems[33...35], radix: 10)
                self.the5 = try UInt16.fromString(dataElems[36...38], radix: 10)
                self.the1 = try UInt16.fromString(dataElems[39...41], radix: 10)
                
                // 前回抜取りカセット以降は使用しないため、解析しない
            } catch {
                throw RunError.ifError(addMessage: "seisa data format is invalid: \(error)")
            }
            
            canPayout = CanPayout(
                the10000: the10000,
                the5000: the5000,
                the2000: the2000,
                the1000: the1000,
                the500: the500,
                the100: the100,
                the50: the50,
                the10: the10,
                the5: the5,
                the1: the1)
        }
        
        /// 指定した金額を払い出し可能かを返す
        /// - Parameter amount: 払い出したい金額[円]
        /// - Returns: true:払い出し可、false:払い出し不可
        func canPayout(amount: Int) -> Bool {
            return canPayout.isOK(amount: amount)
        }
    }
    
}
