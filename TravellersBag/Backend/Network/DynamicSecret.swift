//
//  DynamicSecret.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/19.
//

import Foundation
import CryptoKit

class DynamicSecret {
    static func getDynamicSecret(
        version: SaltVersion,
        saltType: SaltType,
        includeChars: Bool = true,
        query: String = "",
        body: String = ""
    ) -> String {
        // 第一步 计算时间
        let t = Int(Date().timeIntervalSince1970)
        // 第二步 根据版本选择合适的随机字符
        let r = includeChars ? getRs1() : getRs2()
        // 第三步 预先生成的ds明文
        var dsContent = "salt=\(saltType.rawValue)&t=\(t)&r=\(r)"
        // 针对GET请求，解析url
        let q = query.split(separator: "&").sorted().joined(separator: "&")
        // 针对POST请求，解析上报文
        if version == .V2 {
            let b = (saltType == .PROD) ? "{}" : body
            dsContent = "\(dsContent)&b=\(b)&q=\(q)"
        }
        let check = test(ori: dsContent)
        return "\(t),\(r),\(check)"
    }
    
    private static func getRs1() -> String {
        let range = "abcdefghijklmnopqrstuvwxyz1234567890"
        var sb = ""
        for _ in 0..<6 {
            let randomOne = range.index(range.startIndex, offsetBy: Int.random(in: 0..<range.count))
            sb.append(range[randomOne])
        }
        return sb
    }
    
    private static func getRs2() -> String {
        return String(Int.random(in: 100001...200000))
    }
    
    private static func test(ori: String) -> String {
        let data = ori.data(using: .utf8)!
        let digest = Insecure.MD5.hash(data: data)
        var hexString = ""
        digest.forEach { byte in
            let hex = String(format: "%02x", byte)
            hexString += hex
        }
        return hexString
    }
}

extension DynamicSecret {
    /// 米游社v2.71.1版本的salt
    enum SaltType : String {
        case K2 = "rtvTthKxEyreVXQCnhluFgLXPOFKPHlA"
        case LK2 = "EJncUPGnOHajenjLhBOsdpwEMZmiCmQX"
        case X4 = "xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs"
        case X6 = "t0qEgfub6cvueAPgR5m9aQWWVciEer7v"
        case PROD = "JwYDpKvLj6MrMqqYU6jTKF17KNO2PXoS"
    }
    
    /// 使用盐的版本
    enum SaltVersion {
        case V1
        case V2
    }
}
