//
//  FileDayLogger.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/30.
//

import Foundation
import Logging

/// ファイルロガー
/// ・ドキュメントディレクトリ直下にLogsディレクトリを作成し、その直下にログを出力する
/// ・ログフォーマット
///         日付 [ログレベル] ログメッセージ
/// ・日付毎にログファイルを作成する（ログファイル名：yyyyMMdd.log`）
/// ・ローテーション数（設定）分のログファイルを保持する
///
/// 　　例：ローテーション数を3に設定した場合以下のようなになる
/// 　　　　Logs
/// 　　　　　+20230201.log　←稼働日当日
/// 　　　　　+20230131.log
/// 　　　　　+20230130.log
/// 　　　　　+20230129.log　←存在する場合は削除する
/// 　　　　　+20230128.log　←存在する場合は削除する
final class FileLogger: AnyLoggerOutputProtocol {
    private let log = Logger(label: Bundle.main.bundleIdentifier!)
    
    private var setting: FileLogger.Setting
    
    private static let LOG_DIR_NAME = "Logs"
    
    init(setting: FileLogger.Setting) {
        self.setting = setting
    }
    
    func updateSetting(_ setting: FileLogger.Setting) {
        let oldSetting = self.setting
        self.setting = setting
        
        if oldSetting.rotationCount != self.setting.rotationCount {
            log.info("\(type(of: self)): change log rotation count. \(oldSetting.rotationCount) -> \(self.setting.rotationCount)")
        }
    }
    
    /// ログ出力時に、swift-logからコールバックされるメソッド
    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        let now = Date.now
        let timestamp = createTimestamp(date: now)
        writeToFile(text: "\(timestamp): [\(level)] \(message)\n", date: now)
    }
    
    private func createTimestamp(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        let timestamp = dateFormatter.string(from: date)
        return timestamp
    }
    
    private func writeToFile(text: String, date: Date) {
        guard let documentPathUrl = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first else { return }
        
        let logDirUrl = documentPathUrl.appendingPathComponent(FileLogger.LOG_DIR_NAME)
        do {
            try FileManager.default.createDirectory(at: logDirUrl, withIntermediateDirectories: true)
        } catch {
            print("create logs dir error: \(error)")
            return
        }
        
        // ログローテーション
        execRotation(at: logDirUrl)
        
        let fileName = getFileName(date: date)
        let path = logDirUrl.appendingPathComponent(fileName)
        appendText(fileURL: path, text: text)
    }
    
    private func execRotation(at: URL) {
        do {
            // ログを列挙
            var fileUrls = try FileManager.default.contentsOfDirectory(at: at,
                                                                       includingPropertiesForKeys: nil)
            
            // 列挙したログファイルを名前降順にソート（=日付降順ソートと同じ意味になる）
            fileUrls.sort { $0.relativePath > $1.relativePath }
            
            // ローテーション数だけ残して削除
            for (i, fileUrl) in fileUrls.enumerated() {
                if i < setting.rotationCount {
                    continue
                }
                
                do {
                    try FileManager.default.removeItem(at: fileUrl)
                    print("remove log file .file=\(fileUrl.relativePath)")
                } catch {
                    print("remove log file error. file=\(fileUrl.relativePath): \(error)")
                }
            }
        } catch {
            print("rotate log file error: \(error)")
            return
        }
    }
    
    private func getFileName(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let timestamp = dateFormatter.string(from: date)
        
        let fileName = "\(timestamp).log"
        return fileName
    }
    
    private func appendText(fileURL: URL, text: String) {
        guard let stream = OutputStream(url: fileURL, append: true) else { return }
        stream.open()
        defer { stream.close() }
        
        guard let data = text.data(using: .utf8) else { return }
        
        let result = data.withUnsafeBytes({ (rawBufferPointer: UnsafeRawBufferPointer) -> Int in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            return stream.write(bufferPointer.baseAddress!, maxLength: data.count)
        })
        if result < 0 {
            print("output log error")
        }
    }
}
