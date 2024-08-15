//
//  FileHandler.swift
//  TravellingBag
//
//  Created by 鸳汐 on 2024/7/30.
//

import Foundation

/// 文件处理类 由于未做风险容错，故只能使用其中的方法读写沙盒中的文件。
class FileHandler {
    private static var instance: FileHandler?
    
    private init () {}
    
    static var shared: FileHandler {
        if instance == nil {
            instance = FileHandler()
        }
        return instance!
    }
    
    /// 通过传入的路径（记得做好百分号剔除）读取文本文件内容
    func readUtf8String(path: String) -> String {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            return "FAILED:\(error.localizedDescription)"
        }
    }
    
    /// 通过传入的路径（记得做好百分号剔除）写入文本文件内容
    func writeUtf8String(path: String, context: String) {
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }
        try! context.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    /// 创建文件夹的封装
    func mkdir(path: String) {
        try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
}
