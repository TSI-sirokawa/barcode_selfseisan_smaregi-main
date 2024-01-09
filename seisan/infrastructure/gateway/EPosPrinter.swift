//
//  EPosPrinter.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/03/27.
//

import Foundation
import Logging
import UIKit

/// EPSON ePOS SDK で接続できるレシートプリンタ
final class EPosPrinter: NSObject, Epos2PtrReceiveDelegate, ReceiptPrintProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    let setting: EPosPrinter.Setting
    
    /// Epos2プリンタインスタンス
    private var printer: Epos2Printer?
    /// 応答ドキュメント受信イベントのコールバックが呼び出されるまで待つためのセマフォ
    private var printWait: DispatchSemaphore?
    /// 応答ドキュメント受信イベントのコールバックで通知された「処理の実行結果」
    private var printCode: Int32?
    
    static let PRINTER_SERIES_VALUE: Epos2PrinterSeries = EPOS2_TM_M30
    static let PRINTER_MODEL_VALUE: Epos2ModelLang = EPOS2_MODEL_JAPANESE
    static let DISCONNECT_CHECK_RETRY_COUNT = 4
    static let DISCONNECT_INTERVAL = 0.01
    
    init(setting: EPosPrinter.Setting) {
        self.setting = setting
    }
    
    func initialize() {
        // Epos2Printerインスタンスの生成と破棄は繰り返し処理の外で行い、短い間隔で繰り返さないように
        // 仕様書に明記（※）されているため、それに従うこと
        // 　※ ePOS_SDK_iOS_um_ja_revX.pdfの補足説明（P.49）を参照
        printer = Epos2Printer(printerSeries: EPosPrinter.PRINTER_SERIES_VALUE.rawValue, lang: EPosPrinter.PRINTER_MODEL_VALUE.rawValue)
        if printer == nil {
            return
        }
        
        // 応答ドキュメント受信イベントのコールバックを登録
        printer!.setReceiveEventDelegate(self)
        
        log.info("\(type(of: self)): init printer ok")
    }
    
    func close() {
        printer?.setReceiveEventDelegate(nil)
        printer = nil
        log.info("\(type(of: self)): finalize printer ok")
    }
    
    /// 通信テストを実施する
    func execCommTest() async throws {
        // プリンタ接続
        try connect()
        
        // プリンタ切断
        disconnect()
    }
    
    /// プリンタに接続する
    func connect() throws {
        if printer == nil {
            // 初期化に失敗していた場合
            throw RunError.unexpected("init printer error")
        }
        
        let procStart = Date()
        let result = printer!.connect(setting.bdAddress, timeout:Int(EPOS2_PARAM_DEFAULT))
        let procElapsed = Date().timeIntervalSince(procStart)
        
        if result != EPOS2_SUCCESS.rawValue {
            throw RunError.comm("connect error. dbAddr=\(setting.bdAddress), result=\(getEpos2ErrorStatusString(result))(\(result))")
        }
        
        log.info("\(type(of: self)): connect ok. elapsed=\(procElapsed)")
    }
    
    /// プリンタから切断する
    func disconnect() {
        var result: Int32 = EPOS2_SUCCESS.rawValue
        
        result = printer!.disconnect()
        var count = 0
        while (result == EPOS2_ERR_PROCESSING.rawValue && count < EPosPrinter.DISCONNECT_CHECK_RETRY_COUNT) {
            Thread.sleep(forTimeInterval: EPosPrinter.DISCONNECT_INTERVAL)
            result = printer!.disconnect()
            count += 1
        }
        if result == EPOS2_SUCCESS.rawValue {
            log.info("\(type(of: self)): disconnect ok")
        } else {
            log.error("\(type(of: self)): disconnect error. result=\(getEpos2ErrorStatusString(result))(\(result))")
        }
        
        printer!.clearCommandBuffer()
    }
    
    /// テキストを印刷する
    /// - Parameter textPrintDatas: テキスト印刷データ
    func printText(textPrintDatas: [TextPrintData]) throws {
        for textPrintData in textPrintDatas {
            // 印刷データ作成
            try createTextPrintData(textPrintData: textPrintData)
            
            // 印刷実行
            try printData()
            
            printer!.clearCommandBuffer()
        }
    }
    
    /// 切れ目のないテキスト印刷を行う
    /// - Parameter continuousTextPrintData: 切れ目なく印刷するためのテキスト印刷データ
    func printContinuousText(textContinuousPrintData: ContinuousTextPrintData) throws {
        // 印刷データ作成
        try createContinTextPrintData(continuousTextPrintData: textContinuousPrintData)
        
        // 印刷実行
        try printData()
        
        printer!.clearCommandBuffer()
    }
    
    /// 画像を印刷する
    /// - Parameter image: 画像
    func printImage(image: UIImage) throws {
        // 印刷データ作成
        try createImagePrintData(image: image)
        
        // 印刷実行
        try printData()
        
        printer!.clearCommandBuffer()
    }
    
    /// プリンタに送信する印刷データを作成する（テキスト印刷）
    /// - Parameter textPrintData: テキスト印刷データ
    private func createTextPrintData(textPrintData: TextPrintData) throws {
        do {
            // テキストを左寄せにする
            var result = printer!.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
            if result != EPOS2_SUCCESS.rawValue {
                throw RunError.unexpected("test aling error. result=\(getEpos2ErrorStatusString(result))(\(result))")
            }

            result = printer!.addTextLang(EPOS2_LANG_JA.rawValue)
            if result != EPOS2_SUCCESS.rawValue {
                throw RunError.unexpected("add text lang error. result=\(getEpos2ErrorStatusString(result))(\(result))")
            }
            
            // テキスト印刷データを追加
            try addTextPrintData(textPrintData: textPrintData)
            
            // 紙をカットする
            result = printer!.addCut(EPOS2_CUT_FEED.rawValue)
            if result != EPOS2_SUCCESS.rawValue {
                throw RunError.unexpected("add cut error. result=\(getEpos2ErrorStatusString(result))(\(result))")
            }
        } catch {
            printer!.clearCommandBuffer()
            throw error
        }
    }
    
    /// プリンタに送信する印刷データを作成する（切れ目のないテキスト印刷）
    /// - Parameter continuousTextPrintData: 切れ目なく印刷するためのテキスト印刷データ
    private func createContinTextPrintData(continuousTextPrintData: ContinuousTextPrintData) throws {
        do {
            var result = printer!.addTextLang(EPOS2_LANG_JA.rawValue)
            if result != EPOS2_SUCCESS.rawValue {
                throw RunError.unexpected("add text lang error. result=\(getEpos2ErrorStatusString(result))(\(result))")
            }
            
            for textPrintData in continuousTextPrintData.textPrintDatas {
                // テキストを左寄せにする
                // 　→切れ目のないテキスト印刷の場合は、領収印印刷で右寄せになっていることがあるので
                // 　 ここで左寄せにする
                result = printer!.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
                if result != EPOS2_SUCCESS.rawValue {
                    throw RunError.unexpected("test aling error. result=\(getEpos2ErrorStatusString(result))(\(result))")
                }
                
                // テキスト印刷データを追加
                try addTextPrintData(textPrintData: textPrintData)
            }
            
            // 紙をカットする
            result = printer!.addCut(EPOS2_CUT_FEED.rawValue)
            if result != EPOS2_SUCCESS.rawValue {
                throw RunError.unexpected("add cut error. result=\(getEpos2ErrorStatusString(result))(\(result))")
            }
        } catch {
            printer!.clearCommandBuffer()
            throw error
        }
    }
    
    /// テキスト印刷データを追加する
    /// - Parameter textPrintData: テキスト印刷データ
    private func addTextPrintData(textPrintData: TextPrintData) throws {
        // フォント設定
        var font = EPOS2_FONT_A.rawValue
        switch textPrintData.font {
        case "EPOS2_FONT_A":
            font = EPOS2_FONT_A.rawValue
        case "EPOS2_FONT_B":
            font = EPOS2_FONT_B.rawValue
        case "EPOS2_FONT_C":
            font = EPOS2_FONT_C.rawValue
        case "EPOS2_FONT_D":
            font = EPOS2_FONT_D.rawValue
        case "EPOS2_FONT_E":
            font = EPOS2_FONT_E.rawValue
        default:
            break
        }
        var result = printer!.addTextFont(font)
        if result != EPOS2_SUCCESS.rawValue {
            throw RunError.unexpected("add font error. result=\(getEpos2ErrorStatusString(result))(\(result))")
        }
        
        // 印刷するテキストを追加
        let textData: NSMutableString = NSMutableString()
        textData.append(textPrintData.text)
        
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            throw RunError.unexpected("add text error. result=\(getEpos2ErrorStatusString(result))(\(result))")
        }
        
        if let ryoshuinImage = textPrintData.ryoshuinImage {
            // 領収印対応
            // 　→テキストに続いて領収印を印刷
                
            // 画像を右寄せにする
            result = printer!.addTextAlign(EPOS2_ALIGN_RIGHT.rawValue)
            if result != EPOS2_SUCCESS.rawValue {
                throw RunError.unexpected("add text align error. result=\(getEpos2ErrorStatusString(result))(\(result))")
            }
            
            // 領収印画像を追加
            result = printer!.add(ryoshuinImage,
                         x: 0,
                         y: 0,
                         width: Int(ryoshuinImage.size.width),   // 画像の 1 ピクセルがプリンターの 1 ドットに相当（ePosSDK仕様）
                         height: Int(ryoshuinImage.size.height), // 上記と同様
                         color: EPOS2_COLOR_1.rawValue,
                         mode: EPOS2_MODE_MONO.rawValue,
                         halftone: EPOS2_HALFTONE_DITHER.rawValue,
                         brightness: Double(EPOS2_PARAM_DEFAULT),
                         compress: EPOS2_COMPRESS_AUTO.rawValue)
            if result != EPOS2_SUCCESS.rawValue {
                throw RunError.unexpected("add image error. result=\(getEpos2ErrorStatusString(result))(\(result))")
            }
        }
        
        // 最後に行単位の紙送りを行う
        result = printer!.addFeedLine(1)
        if result != EPOS2_SUCCESS.rawValue {
            throw RunError.unexpected("add feed line error. result=\(getEpos2ErrorStatusString(result))(\(result))")
        }
    }
    
    /// プリンタに送信する印刷データを作成する（画像印刷）
    /// - Parameter textPrintData: 画像印刷データ
    func createImagePrintData(image: UIImage) throws {
        let pixelWidth = Int(image.size.width * image.scale)
        let pixelHeight = Int(image.size.height * image.scale)
        
        var result = printer!.add(image,
                                  x: 0,
                                  y: 0,
                                  width: pixelWidth,
                                  height: pixelHeight,
                                  color: EPOS2_PARAM_DEFAULT,
                                  mode: EPOS2_PARAM_DEFAULT,
                                  halftone: EPOS2_PARAM_DEFAULT,
                                  brightness: Double(EPOS2_PARAM_DEFAULT),
                                  compress: EPOS2_COMPRESS_DEFLATE.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            throw RunError.unexpected("add image error. result=\(getEpos2ErrorStatusString(result))(\(result))")
        }
        
        result = printer!.addCut(EPOS2_CUT_FEED.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            throw RunError.unexpected("cut feed error. result=\(getEpos2ErrorStatusString(result))(\(result))")
        }
    }
    
    private func printData() throws {
        let result = printer!.sendData(Int(EPOS2_PARAM_DEFAULT))
        if result != EPOS2_SUCCESS.rawValue {
            throw RunError.comm("send data error. dbAddr=\(setting.bdAddress), result=\(getEpos2ErrorStatusString(result))(\(result))")
        }
        
        printWait = DispatchSemaphore(value: 0)
        printWait!.wait()
        
        if printCode! != EPOS2_CODE_SUCCESS.rawValue {
            throw RunError.print("print notif error. code=\(getEpos2CallbackCodeString(printCode!))(\(printCode!))")
        }
    }
    
    func onPtrReceive(_ printerObj: Epos2Printer!, code: Int32, status: Epos2PrinterStatusInfo!, printJobId: String!) {
        log.info("\(type(of: self)): onPtrReceive: code=\(getEpos2CallbackCodeString(code))(\(code))")
        
        printCode = code
        printWait!.signal()
    }
}

extension EPosPrinter {
    // フォント定義
    enum FontType: String, CaseIterable, Codable {
        case EPOS2_FONT_A
        case EPOS2_FONT_B
        case EPOS2_FONT_C
        case EPOS2_FONT_D
        case EPOS2_FONT_E
        
        var description: String {
            switch self {
            case .EPOS2_FONT_A:
                return "EPOS2_FONT_A"
            case .EPOS2_FONT_B:
                return "EPOS2_FONT_B"
            case .EPOS2_FONT_C:
                return "EPOS2_FONT_C"
            case .EPOS2_FONT_D:
                return "EPOS2_FONT_D"
            case .EPOS2_FONT_E:
                return "EPOS2_FONT_E"
            }
        }
    }
}

extension EPosPrinter {
    private func getEpos2ErrorStatusString(_ code: Int32) -> String {
        var str = ""
        switch (code) {
        case EPOS2_SUCCESS.rawValue:
            str = "EPOS2_SUCCESS"
        case EPOS2_ERR_PARAM.rawValue:
            str = "EPOS2_ERR_PARAM"
        case EPOS2_ERR_CONNECT.rawValue:
            str = "EPOS2_ERR_CONNECT"
        case EPOS2_ERR_TIMEOUT.rawValue:
            str = "EPOS2_ERR_TIMEOUT"
        case EPOS2_ERR_MEMORY.rawValue:
            str = "EPOS2_ERR_MEMORY"
        case EPOS2_ERR_ILLEGAL.rawValue:
            str = "EPOS2_ERR_ILLEGAL"
        case EPOS2_ERR_PROCESSING.rawValue:
            str = "EPOS2_ERR_PROCESSING"
        case EPOS2_ERR_NOT_FOUND.rawValue:
            str = "EPOS2_ERR_NOT_FOUND"
        case EPOS2_ERR_IN_USE.rawValue:
            str = "EPOS2_ERR_IN_USE"
        case EPOS2_ERR_TYPE_INVALID.rawValue:
            str = "EPOS2_ERR_TYPE_INVALID"
        case EPOS2_ERR_DISCONNECT.rawValue:
            str = "EPOS2_ERR_DISCONNECT"
        case EPOS2_ERR_ALREADY_OPENED.rawValue:
            str = "EPOS2_ERR_ALREADY_OPENED"
        case EPOS2_ERR_ALREADY_USED.rawValue:
            str = "EPOS2_ERR_ALREADY_USED"
        case EPOS2_ERR_BOX_COUNT_OVER.rawValue:
            str = "EPOS2_ERR_BOX_COUNT_OVER"
        case EPOS2_ERR_BOX_CLIENT_OVER.rawValue:
            str = "EPOS2_ERR_BOX_CLIENT_OVER"
        case EPOS2_ERR_UNSUPPORTED.rawValue:
            str = "EPOS2_ERR_UNSUPPORTED"
        case EPOS2_ERR_DEVICE_BUSY.rawValue:
            str = "EPOS2_ERR_DEVICE_BUSY"
        case EPOS2_ERR_RECOVERY_FAILURE.rawValue:
            str = "EPOS2_ERR_RECOVERY_FAILURE"
        case EPOS2_ERR_FAILURE.rawValue:
            str = "EPOS2_ERR_FAILURE"
        default:
            str = "unknown. result=\(code)"
        }
        
        return str
    }
    
    private func getEpos2CallbackCodeString(_ code: Int32) -> String {
        var str = ""
        switch (code) {
        case EPOS2_CODE_SUCCESS.rawValue:
            str = "EPOS2_CODE_SUCCESS"
        case EPOS2_CODE_ERR_TIMEOUT.rawValue:
            str = "EPOS2_CODE_ERR_TIMEOUT"
        case EPOS2_CODE_ERR_NOT_FOUND.rawValue:
            str = "EPOS2_CODE_ERR_NOT_FOUND"
        case EPOS2_CODE_ERR_AUTORECOVER.rawValue:
            str = "EPOS2_CODE_ERR_AUTORECOVER"
        case EPOS2_CODE_ERR_COVER_OPEN.rawValue:
            str = "EPOS2_CODE_ERR_COVER_OPEN"
        case EPOS2_CODE_ERR_CUTTER.rawValue:
            str = "EPOS2_CODE_ERR_CUTTER"
        case EPOS2_CODE_ERR_MECHANICAL.rawValue:
            str = "EPOS2_CODE_ERR_MECHANICAL"
        case EPOS2_CODE_ERR_EMPTY.rawValue:
            str = "EPOS2_CODE_ERR_EMPTY"
        case EPOS2_CODE_ERR_UNRECOVERABLE.rawValue:
            str = "EPOS2_CODE_ERR_UNRECOVERABLE"
        case EPOS2_CODE_ERR_SYSTEM.rawValue:
            str = "EPOS2_CODE_ERR_SYSTEM"
        case EPOS2_CODE_ERR_PORT.rawValue:
            str = "EPOS2_CODE_ERR_PORT"
        case EPOS2_CODE_ERR_INVALID_WINDOW.rawValue:
            str = "EPOS2_CODE_ERR_INVALID_WINDOW"
        case EPOS2_CODE_ERR_JOB_NOT_FOUND.rawValue:
            str = "EPOS2_CODE_ERR_JOB_NOT_FOUND"
        case EPOS2_CODE_PRINTING.rawValue:
            str = "EPOS2_CODE_PRINTING"
        case EPOS2_CODE_ERR_SPOOLER.rawValue:
            str = "EPOS2_CODE_ERR_SPOOLER"
        case EPOS2_CODE_ERR_BATTERY_LOW.rawValue:
            str = "EPOS2_CODE_ERR_BATTERY_LOW"
        case EPOS2_CODE_ERR_TOO_MANY_REQUESTS.rawValue:
            str = "EPOS2_CODE_ERR_TOO_MANY_REQUESTS"
        case EPOS2_CODE_ERR_REQUEST_ENTITY_TOO_LARGE.rawValue:
            str = "EPOS2_CODE_ERR_REQUEST_ENTITY_TOO_LARGE"
        case EPOS2_CODE_CANCELED.rawValue:
            str = "EPOS2_CODE_CANCELED"
        case EPOS2_CODE_ERR_NO_MICR_DATA.rawValue:
            str = "EPOS2_CODE_ERR_NO_MICR_DATA"
        case EPOS2_CODE_ERR_ILLEGAL_LENGTH.rawValue:
            str = "EPOS2_CODE_ERR_ILLEGAL_LENGTH"
        case EPOS2_CODE_ERR_NO_MAGNETIC_DATA.rawValue:
            str = "EPOS2_CODE_ERR_NO_MAGNETIC_DATA"
        case EPOS2_CODE_ERR_RECOGNITION.rawValue:
            str = "EPOS2_CODE_ERR_RECOGNITION"
        case EPOS2_CODE_ERR_READ.rawValue:
            str = "EPOS2_CODE_ERR_READ"
        case EPOS2_CODE_ERR_NOISE_DETECTED.rawValue:
            str = "EPOS2_CODE_ERR_NOISE_DETECTED"
        case EPOS2_CODE_ERR_PAPER_JAM.rawValue:
            str = "EPOS2_CODE_ERR_PAPER_JAM"
        case EPOS2_CODE_ERR_PAPER_PULLED_OUT.rawValue:
            str = "EPOS2_CODE_ERR_PAPER_PULLED_OUT"
        case EPOS2_CODE_ERR_CANCEL_FAILED.rawValue:
            str = "EPOS2_CODE_ERR_CANCEL_FAILED"
        case EPOS2_CODE_ERR_PAPER_TYPE.rawValue:
            str = "EPOS2_CODE_ERR_PAPER_TYPE"
        case EPOS2_CODE_ERR_WAIT_INSERTION.rawValue:
            str = "EPOS2_CODE_ERR_WAIT_INSERTION"
        case EPOS2_CODE_ERR_ILLEGAL.rawValue:
            str = "EPOS2_CODE_ERR_ILLEGAL"
        case EPOS2_CODE_ERR_INSERTED.rawValue:
            str = "EPOS2_CODE_ERR_INSERTED"
        case EPOS2_CODE_ERR_WAIT_REMOVAL.rawValue:
            str = "EPOS2_CODE_ERR_WAIT_REMOVAL"
        case EPOS2_CODE_ERR_DEVICE_BUSY.rawValue:
            str = "EPOS2_CODE_ERR_DEVICE_BUSY"
        case EPOS2_CODE_ERR_GET_JSON_SIZE.rawValue:
            str = "EPOS2_CODE_ERR_GET_JSON_SIZE"
        case EPOS2_CODE_ERR_IN_USE.rawValue:
            str = "EPOS2_CODE_ERR_IN_USE"
        case EPOS2_CODE_ERR_CONNECT.rawValue:
            str = "EPOS2_CODE_ERR_CONNECT"
        case EPOS2_CODE_ERR_DISCONNECT.rawValue:
            str = "EPOS2_CODE_ERR_DISCONNECT"
        case EPOS2_CODE_ERR_DIFFERENT_MODEL.rawValue:
            str = "EPOS2_CODE_ERR_DIFFERENT_MODEL"
        case EPOS2_CODE_ERR_DIFFERENT_VERSION.rawValue:
            str = "EPOS2_CODE_ERR_DIFFERENT_VERSION"
        case EPOS2_CODE_ERR_MEMORY.rawValue:
            str = "EPOS2_CODE_ERR_MEMORY"
        case EPOS2_CODE_ERR_PROCESSING.rawValue:
            str = "EPOS2_CODE_ERR_PROCESSING"
        case EPOS2_CODE_ERR_DATA_CORRUPTED.rawValue:
            str = "EPOS2_CODE_ERR_DATA_CORRUPTED"
        case EPOS2_CODE_ERR_PARAM.rawValue:
            str = "EPOS2_CODE_ERR_PARAM"
        case EPOS2_CODE_RETRY.rawValue:
            str = "EPOS2_CODE_RETRY"
        case EPOS2_CODE_ERR_RECOVERY_FAILURE.rawValue:
            str = "EPOS2_CODE_ERR_RECOVERY_FAILURE"
        case EPOS2_CODE_ERR_JSON_FORMAT.rawValue:
            str = "EPOS2_CODE_ERR_JSON_FORMAT"
        case EPOS2_CODE_NO_PASSWORD.rawValue:
            str = "EPOS2_CODE_NO_PASSWORD"
        case EPOS2_CODE_ERR_INVALID_PASSWORD.rawValue:
            str = "EPOS2_CODE_ERR_INVALID_PASSWORD"
        case EPOS2_CODE_ERR_FAILURE.rawValue:
            str = "EPOS2_CODE_ERR_FAILURE"
        default:
            str = "unknown. result=\(code)"
        }
        
        return str
    }
}

extension EPosPrinter {
    enum RunError: Error {
        case comm(String)
        case print(String)
        case unexpected(String)
    }
}

extension EPosPrinter {
    class Descovery: NSObject, Epos2DiscoveryDelegate {
        private var portType: Epos2PortType
        private var discoveryCallback: (Epos2DeviceInfo) -> Void
        
        init(portType: Epos2PortType, discoveryCallback: @escaping (Epos2DeviceInfo) -> Void) {
            self.portType = portType
            self.discoveryCallback = discoveryCallback
        }
        
        func start() {
            let filterOpt = Epos2FilterOption()
            filterOpt.portType = portType.rawValue
            filterOpt.deviceModel = EPOS2_MODEL_ALL.rawValue
            filterOpt.deviceType = EPOS2_TYPE_PRINTER.rawValue
            let result = Epos2Discovery.start(filterOpt, delegate: self)
            if result != EPOS2_SUCCESS.rawValue {
                print("Epos2Discovery start error. result=\(result)")
            }
        }
        
        func stop() {
            Epos2Discovery.stop()
        }
        
        func onDiscovery(_ deviceInfo: Epos2DeviceInfo!) {
//            print("Device found: -------------------------")
//            print("Target: \(String(describing: deviceInfo.target))")
//            print("Device name: \(String(describing: deviceInfo.deviceName))")
//            print("MAC address: \(String(describing: deviceInfo.macAddress))")
//            print("IP address: \(String(describing: deviceInfo.ipAddress))")
//            print("BD address: \(String(describing: deviceInfo.bdAddress))")
//            print("BD LE address: \(String(describing: deviceInfo.leBdAddress))")

            self.discoveryCallback(deviceInfo)
        }
    }
}
