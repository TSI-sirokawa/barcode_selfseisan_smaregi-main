//
//  DayFileLogger.swift
//  seisan
//
//  Created by Hiroyuki Kajiki on 2023/01/30.
//

import Foundation
import Logging

/// ファイルロガー
/// ・swift-logのハンドラ（LogHandler）を実装する
/// ・ドキュメントディレクトリ直下に１ヶ月分のログを日毎に出力する
/// ・ログ出力時に前月分のログは同日の翌日分のログファイルを削除する
/// 　　例：
/// 　　　X月1日のログ: log1.csv
/// 　　　X月2日のログ: log2.csv
/// 　　　　　　・・・｀
/// 　　　X月31日のログ: log31.csv
final class FileDayLogger: LogHandler {
    private let label: String
    private var setting: FileDayLogger.Setting
    
    subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set(newValue) {
            self.metadata[metadataKey] = newValue
        }
    }
    
    var metadata = Logger.Metadata()
    var logLevel: Logging.Logger.Level = .info
    
    init(label: String, setting: FileDayLogger.Setting) {
        self.label = label
        self.setting = setting
    }
    
    func updateSetting(setting: FileDayLogger.Setting) {
        self.setting = setting
        logLevel = self.setting.logLevel
    }
    
    /// ログ出力時に、swift-logからコールバックされるメソッド
    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        if setting.outputEnable {
            return
        }
        
        let now = Date.now
        let timestamp = createTimestamp(date: now)
        writeToFile(text: "\(timestamp): [\(level)] \(message)\n", date: now)
    }
    
    private func createTimestamp(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        let timestamp = dateFormatter.string(from: date)
        return timestamp
    }
    
    private func writeToFile(text: String, date: Date) {
        guard let documentPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first else { return }
        
        let delFileName = getDeleteFileName(date: date)
        let delFilePath = documentPath.appendingPathComponent(delFileName)
        if (FileManager.default.fileExists(atPath: delFilePath.path)) {
            do {
                try FileManager.default.removeItem(atPath: delFilePath.path)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        let fileName = getFileName(date: date)
        let path = documentPath.appendingPathComponent(fileName)
        appendText(fileURL: path, text: text)
    }
    
    private func getFileName(date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.component(.day, from: date)
        let fileName = "log" + today.description + ".csv"
        return fileName
    }
    
    private func getDeleteFileName(date: Date) -> String {
        //前月の同日の翌日ログファイルを削除する
        let calendar = Calendar(identifier: .gregorian)
        let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        let tomorrow = calendar.component(.day, from: nextDate)
        let fileName = "log" + tomorrow.description + ".csv"
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
