//
//  ReceiptPrintService.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/02.
//

import Foundation
import Logging

/// レシート印刷サービス
final class ReceiptPrintService {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let receiptPrint: ReceiptPrintProtocol
    
    private var queue: Queue<PrintData> = Queue<PrintData>()
    private var isClosing = false
    private var closeWait = DispatchSemaphore(value: 1)
    private var printErr: Error?
    /// プリンタに接続済みかどうか
    private var isConnected = false
    
    init(receiptPrint: ReceiptPrintProtocol) {
        self.receiptPrint = receiptPrint
        
        Task {
            await execPrinting()
        }
    }
    
    func close() {
        isClosing = true
        closeWait.wait()
        
        log.info("\(type(of: self)): close ok")
    }
    
    /// プリンタへの接続要求
    func connect() {
        // 先にプリンタに接続しておく
        let connReq = PrintData(isConnectRequest: true)
        log.info("\(type(of: self)): connect print request enqueue. id=\(connReq.id)")
        queue.enqueue(connReq)
    }
    
    /// テキストを印刷する
    /// - Parameter textPrintDatas: テキスト印刷データ
    func printText(textPrintDatas: [TextPrintData]) {
        let printData = PrintData(textPrintDatas: textPrintDatas)
        log.info("\(type(of: self)): text print data enqueue. id=\(printData.id), count=\(textPrintDatas.count)")
        queue.enqueue(printData)
    }
    
    /// 切れ目なく印刷するテキストを印刷する
    /// - Parameter continuousTextPrintData: 切れ目なく印刷するためのテキスト印刷データ
    func printContinuousText(continuousTextPrintData: ContinuousTextPrintData) {
        let printData = PrintData(continuousTextPrintData: continuousTextPrintData)
        log.info("\(type(of: self)): continuous text print data enqueue. id=\(printData.id)")
        queue.enqueue(printData)
    }
    
    /// 画像を印刷する
    /// - Parameter image: 画像
    func printImage(image: UIImage) {
        let printData = PrintData(image: image)
        log.info("\(type(of: self)): image print data enqueue. id=\(printData.id)")
        queue.enqueue(printData)
    }
    
    /// 印刷完了待ちが必要がどうか
    /// - Returns: true:必要、false:不要
    func isWaitRequired() -> Bool {
        if queue.count == 0 {
            // 印刷キューがゼロの場合は、
            // 印刷完了を待つ必要がない
            return false
        }
        
        if queue.count == 1, let printData = queue.peek(), printData.isConnectRequest{
            // 印刷キューが１つ、かつ、プリンタ接続要求の場合は、
            // 印刷完了を待つ必要がない
            return false
        }
        
        return true
    }
    
    /// 印刷完了待ち
    func wait() async throws {
        log.info("\(type(of: self)): print wait... count=\(queue.count)")
        
        while (!isClosing) {
            if queue.count == 0 {
                break
            }
            
            if let printErr = printErr {
                // 印刷エラー発生
                throw printErr
            }
            
            do {
                try await Task.sleep(for: .milliseconds(10))
            } catch {}
        }
        
        log.info("\(type(of: self)): print ok")
    }
    
    /// 印刷を再開する
    /// ・印刷エラー発生後に再印刷をする場合に呼び出す
    func restart() async {
        printErr = nil
    }
    
    /// キューに追加された印刷データを印刷する
    private func execPrinting() async {
        defer {
            closeWait.signal()
        }
        
        var connFailCount = 0
        while (!isClosing) {
            if printErr == nil {
                // エラー未発生の場合のみ印刷を実行する
                // ・エラーが発生した場合は再実行指示が来るまで印刷を実行しない
                
                if let printData = queue.peek() {
                    if !isConnected {
                        // 未接続の場合はまず接続する
                        
                        // 接続要求
                        do {
                            try receiptPrint.connect()
                            isConnected = true
                            connFailCount = 0
                            log.info("\(type(of: self)): connect ok. id=\(printData.id)")
                        } catch {
                            connFailCount += 1
                            if connFailCount >= 2 {
                                // 切断直後に接続処理を行うと高頻度で「EPOS2_ERR_ILLEGAL(5)」が発生するが、
                                // リトライすると接続に成功する
                                log.warning("\(type(of: self)): connect error. id=\(printData.id): \(error)")
                                printErr = error
                            }
                            
                            do {
                                try await Task.sleep(for: .milliseconds(100))
                            } catch {}
                            continue
                        }
                    }
                    
                    if printData.isConnectRequest {
                        // 接続リクエストは無条件でキューから削除
                        _ = queue.dequeue()
                    } else {
                        // 印刷要求
                        do {
                            log.info("\(type(of: self)): print start... id=\(printData.id)")
                            
                            // テキスト印刷
                            if printData.textPrintDatas.count > 0 {
                                let procStart = Date()
                                try receiptPrint.printText(textPrintDatas: printData.textPrintDatas)
                                let procElapsed = Date().timeIntervalSince(procStart)
                                log.info("\(type(of: self)): print text ok. id=\(printData.id), fonts=[\(printData.textPrintDatas.map { $0.font })], elapsed=\(procElapsed)")
                            }
                            
                            // 切れ目のないテキスト印刷
                            if let continuousTextPrintData = printData.continuousTextPrintData {
                                let procStart = Date()
                                try receiptPrint.printContinuousText(textContinuousPrintData: continuousTextPrintData)
                                let procElapsed = Date().timeIntervalSince(procStart)
                                log.info("\(type(of: self)): print continuous text ok. id=\(printData.id), fonts=[\(printData.textPrintDatas.map { $0.font })], elapsed=\(procElapsed)")
                            }
                            
                            // 画像印刷
                            if let image = printData.image {
                                let procStart = Date()
                                try receiptPrint.printImage(image: image)
                                let procElapsed = Date().timeIntervalSince(procStart)
                                log.info("\(type(of: self)): print image ok. id=\(printData.id), elapsed=\(procElapsed)")
                            }
                            
                            // 印刷に成功したらキューから削除
                            _ = queue.dequeue()
                        } catch {
                            log.error("\(type(of: self)): print error. id=\(printData.id): \(error)")
                            printErr = error
                            
                            // プリンタから切断
                            receiptPrint.disconnect()
                            isConnected = false
                            connFailCount = 0
                        }
                    }
                }
            }
            
            do {
                try await Task.sleep(for: .milliseconds(10))
            } catch {}
        }
        
        // プリンタに接続されている場合は切断する
        if isConnected {
            receiptPrint.disconnect()
            isConnected = false
        }
    }
}

extension ReceiptPrintService {
    /// 印刷データ
    private final class PrintData {
        let id = UUID().uuidString
        let isConnectRequest: Bool
        let textPrintDatas: [TextPrintData]
        let continuousTextPrintData: ContinuousTextPrintData?
        let image: UIImage?
        
        init(isConnectRequest: Bool = false,
             textPrintDatas: [TextPrintData] = [],
             continuousTextPrintData: ContinuousTextPrintData? = nil,
             image: UIImage? = nil) {
            self.isConnectRequest = isConnectRequest
            self.textPrintDatas = textPrintDatas
            self.continuousTextPrintData = continuousTextPrintData
            self.image = image
        }
    }
}
