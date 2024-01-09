//
//  HTTPServer.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/09/20.
//

import Foundation
import Logging
import NIOTransportServices
import NIO
import NIOHTTP1

/// HTTPサーバ
class HTTPServer: ObservableObject, ChannelInboundHandler {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    /// ChannelInboundHandlerをHTTPサーバとして使うための作法の模様
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    // イベントループを処理するクラス
    // 　→HTTPサーバ停止後に使い回すとエラーが発生しリクエストを処理できなくなる
    private var group = NIOTSEventLoopGroup()
    
    /// HTTPサーバ設定
    private(set) var setting: Setting?
    
    /// ヘルスチェックURLパス
    static let HEALTH_CHECK_URL_PATH = "/healthcheck"
    
    /// ハンドラマップ
    var handlerMap = Dictionary<String, (_ context: ChannelHandlerContext) -> HTTPServer.Response>()
    
    /// ハンドラを登録
    /// - Parameter newHandlerMap: 登録するハンドラマップ
    func registerHandler(newHandlerMap: Dictionary<String, (_ context: ChannelHandlerContext) -> HTTPServer.Response>) {
        // マージする
        // 　→キーが重複していた場合は新しい方で上書き　※設計ミスなので通常発生しない
        handlerMap.merge(newHandlerMap) { (_, new) in new }
    }
    
    /// 待ち受けを開始する
    ///  →HTTPサーバの起動に成功した場合、HTTPサーバを停止するまでブロックする
    ///  →待ち受けポートをワイルドWiFiを無効⇛有効とした場合に再起動しなくても稼働しつづける
    func start(setting: Setting) async throws {
        
        if self.setting != nil {
            // 起動済みの場合
            
            if self.setting == setting {
                // 設定が変わらない場合は何もしない
                return
            }
            
            // 設定が変更された場合は再起動する
            do {
                try stop()
            } catch {
                log.info("\(type(of: self)): stop http server error: \(error)")
            }
        }
        
        self.setting = setting
        
        let bootstrap = NIOTSListenerBootstrap(group: group)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline()
                    .flatMap {
                        channel.pipeline.addHandler(self)
                    }
            }
        
        do {
            let channel = try await bootstrap
                .bind(host: setting.listenIPAddr, port: Int(setting.listenPort))
                .get()
            
            
            log.info("\(type(of: self)): start http server...")
            
            // ポートが既に使用されている場合はここでエラーが発生
            try await channel.closeFuture.get()
        } catch {
            self.setting = nil
            throw error
        }
    }
    
    /// 待ち受けを停止する
    func stop() throws {
        try group.syncShutdownGracefully()
        
        // イベントループクラスを再作成
        group = NIOTSEventLoopGroup()

        // 設定をクリア
        setting = nil
        
        log.error("\(type(of: self)): stop http server ok")
    }
    
    /// ヘルスチェックリクエストを実行する
    func execHealthCheck() async throws {
        guard let setting = self.setting else {
            throw RunError.healthCheck("http server is not started at health check")
        }
        
        let url = URL(string: "http://localhost:\(setting.listenPort)\(HTTPServer.HEALTH_CHECK_URL_PATH)")!
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("close", forHTTPHeaderField: "Connection")
        
        let (_, res) = try await URLSession.shared.data(for: req)
        guard let res = res as? HTTPURLResponse else {
            throw RunError.healthCheck("health check error")
        }
        
        if res.statusCode != 200 {
            // 200以外の場合
            throw RunError.healthCheck("health check is invalid reponse. urlPath=\(url.absoluteString),  statusCode=\(res.statusCode)")
        }
        
        log.info("\(type(of: self)): health check success. urlPath=\(url.absoluteString)")
    }
    
    /// HTTPリクエスト受信時にコールバックされるメソッド
    /// - Parameters:
    ///   - context: コンテキスト
    ///   - data: リクエスト
    internal func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)
        
        // メソッドとURLパスを取得
        var method = ""
        var urlPath = ""
        switch frame {
        case .head(let request):
            method = request.method.rawValue
            urlPath = request.uri
        default:
            return
        }
        
        // ヘルスチェック
        if method == HTTPMethod.GET.rawValue && urlPath == HTTPServer.HEALTH_CHECK_URL_PATH {
            log.info("\(type(of: self)): health check request. urlPath=\(urlPath)")
            sendResponse(
                context: context,
                status: .ok,
                contentType: "text/plain",
                isKeepAlive: false,
                resBody: "OK".data(using: .utf8)!)
            return
        }
        
        let handler = handlerMap[method + urlPath]
        
        var errResp: ErrorResponse?
        if let handler = handler {
            // パスに対応するハンドラが見つかった場合
            
            // ハンドラを呼び出し
            let resp = handler(context)
            if resp.isOK() {
                sendResponse(
                    context: context,
                    status: .ok,
                    contentType: resp.okResp!.contentType,
                    resBody: resp.okResp!.resBody)
                return
            }
            
            errResp = resp.errResp
        } else {
            // パスに対応するハンドラが見つからなかった場合
            log.warning("\(type(of: self)): unknown urlPath. urlPath=\(urlPath)")
            
            // HTTP404エラーレスポンスを送信
            errResp = ErrorResponse(
                type: urlPath,
                status: .notFound,
                title: "unknown url path"
            )
        }
        
        let resBody = try! JSONEncoder().encode(errResp!)
        
        sendResponse(
            context: context,
            status: .notFound,
            contentType: "application/json",
            resBody: resBody)
    }
    
    /// レスポンスを送信する
    /// - Parameters:
    ///   - context: コンテキスト
    ///   - status: HTTPステータスコード
    ///   - contentType: コンテントタイプ
    ///   - resBody: レスポンスボディ
    private func sendResponse(context: ChannelHandlerContext,
                              status: HTTPResponseStatus,
                              contentType: String,
                              isKeepAlive: Bool = true,
                              resBody: Data) {
        // 書き込みサイズを取得するため、まずはレスポンスボディをバッファに書き込み
        var buffer = context.channel.allocator.buffer(capacity: resBody.count)
        buffer.writeBytes(resBody)
        
        // レスポンスヘッダを準備
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: contentType)
        headers.add(name: "Content-Length", value: "\(buffer.readableBytes)")
        headers.add(name: "Connection", value: isKeepAlive ? "Keep-Alive": "close")
        let resHeader = HTTPResponseHead(version: .http1_1,
                                         status: status,
                                         headers: headers)
        
        // レスポンスヘッダを送信
        context.write(self.wrapOutboundOut(.head(resHeader)), promise: nil)
        
        // レスポンスボディを送信
        context.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        
        // レスポンス終了処理
        // 　→これを指定しないと「Connection: Keep-Alive」が機能しない
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}

extension HTTPServer {
    /// HTTPサーバ設定
    final class Setting: Equatable {
        /// 待ち受けIPアドレス
        let listenIPAddr: String
        /// 待ち受けポート番号
        let listenPort: UInt16
        
        init(listenIPAddr: String, listenPort: UInt16) {
            self.listenIPAddr = listenIPAddr
            self.listenPort = listenPort
        }
        
        /// Equatableプロトコル実装
        static func == (lhs: HTTPServer.Setting, rhs: HTTPServer.Setting) -> Bool {
            return lhs.listenIPAddr == rhs.listenIPAddr &&
            lhs.listenPort == rhs.listenPort
        }
        
        /// 待ち受けポート番号
        static let LISTEN_PORT = SettingValueAttr(
            label: "ポート番号",
            defaultValue: UInt16(80),
            placeHolder: "0から65535の範囲で指定してください。",
            errorMessage: "true/falseを設定してください。",
            isValidOK: { value in return true })
    }
}

extension HTTPServer {
    /// 実行エラー
    enum RunError: Error {
        case healthCheck(String)
    }
}

extension HTTPServer {
    /// レスポンス
    class Response {
        let okResp: OKResponse?
        let errResp: ErrorResponse?
        
        init(okResp: OKResponse? = nil, errResp: ErrorResponse? = nil) {
            self.okResp = okResp
            self.errResp = errResp
        }
        
        /// 成功レスポンスかどうか
        /// - Returns: true:成功、false:失敗
        func isOK() -> Bool {
            return okResp != nil
        }
    }
    
    /// 成功レスポンス
    class OKResponse {
        let contentType: String
        let resBody: Data
        
        init(contentType: String, resBody: Data) {
            self.contentType = contentType
            self.resBody = resBody
        }
    }
    
    /// エラーレスポンス
    /// 　→プロパティはRFC 9457を参照
    class ErrorResponse: Encodable {
        var type: String = ""
        let status: UInt
        let title: String
        
        init(status: HTTPResponseStatus, title: String) {
            self.status = status.code
            self.title = title
        }
        
        init(type: String, status: HTTPResponseStatus, title: String) {
            self.type = type
            self.status = status.code
            self.title = title
        }
        
        /// typeプロパティ値を更新する
        /// - Parameter type: typeプロパティ値
        func updateType(_ type: String) {
            self.type = type
        }
    }

}
