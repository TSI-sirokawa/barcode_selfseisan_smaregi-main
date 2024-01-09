//
//  AsyncTCPClient.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2022/12/18.
//

import Foundation
import Logging
import Network

class AsyncTCPClient {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private let dispatchQueue: DispatchQueue
    private let host: NWEndpoint.Host
    private let port: NWEndpoint.Port
    private let connectionTimeoutSec: Int
    private var connection: NWConnection?
    private var recvBuf: [UInt8] = []
    private var connStateQueue: [NWConnection.State] = []
    private let connStateQueueLock = NSLock()
    
    /// 接続、送信、受信時に接続状態をチェックする間隔[秒]
    private static let CONN_CHECK_INTERVAL_SEC = 0.001
    
    /// TCP切断要求後に切断が通知されるまで待機する時のタイムアウト時間[秒]
    private static let DISCONN_TIMEOUT_SEC = TimeInterval(2)
    
    init(dispatchQueue: DispatchQueue, host: String, port: UInt16, connectionTimeoutSec: Int) {
        self.dispatchQueue = dispatchQueue
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
        self.connectionTimeoutSec = connectionTimeoutSec
    }
    
    func connect() async throws {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = connectionTimeoutSec
        let params = NWParameters(tls: nil, tcp: tcpOptions)
        
        connection = NWConnection(host: host, port: port, using: params)
        connection!.stateUpdateHandler = { [weak self] (newState) in
            // 接続状態はキュー経由で管理
            self?.enqueueState(newState)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            connection!.start(queue: dispatchQueue)
            
            while true {
                let (connected, connErr) = checkConnState()
                if let connErr = connErr {
                    continuation.resume(throwing: connErr)
                    break
                }
                
                if connected {
                    continuation.resume()
                    break
                }
                Thread.sleep(forTimeInterval: AsyncTCPClient.CONN_CHECK_INTERVAL_SEC)
            }
        }
    }
    
    func close() {
        if let connection = self.connection {
            connection.cancel()
            
            let startTime = Date.now
            var isCancelled = false
            while !isCancelled {
                let connState = dequeueState()
                if let connState = connState {
                    switch connState {
                    case .cancelled:
                        isCancelled = true
                        break
                    default:
                        break
                    }
                }
                
                if Date.now.timeIntervalSince(startTime) >= AsyncTCPClient.DISCONN_TIMEOUT_SEC {
                    log.warning("\(type(of: self)): cancelled wait timeout")
                    isCancelled = true
                    break
                }
                
                Thread.sleep(forTimeInterval: AsyncTCPClient.CONN_CHECK_INTERVAL_SEC)
            }
            
            self.connection = nil
        }
    }
    
    func send(data: [UInt8], timeout: TimeInterval) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let timeoutTime = Date.now.addingTimeInterval(timeout)
            let wait = DispatchSemaphore(value: 0)
            var occuredErr: Error?
            connection!.send(
                content: data,
                completion: .contentProcessed { error in
                    if let error = error {
                        occuredErr = RunError.send(message: "send error : \(error)")
                        return
                    }
                    wait.signal()
                })
            
            while true {
                let result = wait.wait(timeout: DispatchTime.now() + DispatchTimeInterval.microseconds(Int(AsyncTCPClient.CONN_CHECK_INTERVAL_SEC*1000*1000)))
                if result == .success {
                    continuation.resume()
                    return
                }
                if let occuredErr = occuredErr {
                    continuation.resume(throwing: occuredErr)
                    return
                }
                
                let (_, connErr) = checkConnState()
                if let connErr = connErr {
                    continuation.resume(throwing: connErr)
                    return
                }
                
                if Date.now > timeoutTime {
                    continuation.resume(throwing: RunError.timeout)
                    return
                }
            }
        }
    }
    
    func recv(wantLength: Int, timeout: TimeInterval, received: ([UInt8]) -> Void) async throws {
        let timeoutTime = Date.now.addingTimeInterval(timeout)
        defer { recvBuf = [] }
        
        while recvBuf.count < wantLength {
            let byte = try await recvByte(wantLength: wantLength, timeoutTime: timeoutTime)
            guard let byte = byte else {
                continue
            }
            
            recvBuf.append(byte)
            if recvBuf.count < wantLength {
                continue
            }
        }
        received(recvBuf)
    }
    
    private func recvByte(wantLength: Int, timeoutTime: Date) async throws -> UInt8? {
        return try await withCheckedThrowingContinuation { continuation in
            // minimumIncompleteLengthで1以上を指定した場合は、その分を受信したらcompleteクロージャが呼ばれる。
            // また、recvメソッド呼び出し元がデータを処理しやすくするために、バイトずつ受信する
            let wait = DispatchSemaphore(value: 0)
            var occuredErr: Error?
            var recvData: UInt8?
            connection!.receive(
                minimumIncompleteLength: 1,
                maximumLength: 1,
                completion:{ (data, context, flag, error) in
                    if let error = error {
                        occuredErr = RunError.recv(message: "recv error: \(error)")
                        return
                    }
                    guard let data = data else {
                        wait.signal()
                        return
                    }
                    recvData = data[0]
                    wait.signal()
            })
            
            while true {
                let result = wait.wait(timeout: DispatchTime.now() + DispatchTimeInterval.microseconds(Int(AsyncTCPClient.CONN_CHECK_INTERVAL_SEC*1000)))
                if result == .success {
                    if recvData == nil {
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(returning: recvData)
                    }
                    return
                }
                if let occuredErr = occuredErr {
                    continuation.resume(throwing: occuredErr)
                    return
                }
                
                let (_, connErr) = checkConnState()
                if let connErr = connErr {
                    continuation.resume(throwing: connErr)
                    return
                }
                
                if Date.now > timeoutTime {
                    continuation.resume(throwing: RunError.timeout)
                    return
                }
            }
        }
    }
    
    private func enqueueState(_ state: NWConnection.State) {
        connStateQueueLock.lock()
        defer { connStateQueueLock.unlock() }
        
        connStateQueue.append(state)
    }
    
    private func dequeueState() -> NWConnection.State? {
        connStateQueueLock.lock()
        defer { connStateQueueLock.unlock() }
        
        if connStateQueue.count == 0 {
            return nil
        }
        return connStateQueue.removeFirst()
    }
    
    private func checkConnState() -> (Bool, RunError?) {
        let connState = dequeueState()
        if let connState = connState {
            switch connState {
            case .setup, .preparing, .cancelled:
                break
            case .ready:
                // 接続完了
                return (true, nil)
            case .waiting(let error):
                // 接続タイムアウト時など
                return (false, RunError.connect(message: "state=waiting: \(error)"))
            case .failed(let error):
                return (false, RunError.connect(message: "state=failed: \(error)"))
            @unknown default:
                // 定義されている状態は上記で網羅されているが、将来的に状態が追加された場合はこのパスに入る
                // ・このパスはxcodeの警告で自動補完された実装
                // ・その際は実装を見直す必要あり
                fatalError("unknown connection state. \(connState)")
            }
        }
        
        return (false, nil)
    }
}

extension AsyncTCPClient {
    enum RunError: Error {
        /// タイムアウト
        case timeout
        /// 接続エラー
        case connect(message: String)
        /// 送信エラー
        case send(message: String)
        /// 受信エラー
        case recv(message: String)
    }
}
