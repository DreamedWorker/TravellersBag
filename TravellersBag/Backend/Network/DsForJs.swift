//
//  DsForJs.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/13.
//

import Foundation

final class JsDs {
    static func genDs4Js() -> String {
        return DynamicSecret.getDynamicSecret(version: .V1, saltType: .LK2)
    }
    
    static func genDs2ForJs(q: NSDictionary, b: String) -> String {
        return DynamicSecret.getDynamicSecret(version: .V2, saltType: .X4, includeChars: false, query: DynamicSecret4Payload(query: q).getQueryParam(), body: b)
    }
}

extension JsDs {
    struct DynamicSecret4Payload {
        let query: NSDictionary
        
        init(query: NSDictionary) {
            self.query = query
        }
        
        // 转换query参数为URL查询字符串的方法
        func getQueryParam() -> String {
            let a = query.map { (key, value) -> String in
                return "\(key)=\(value)"
            }.joined(separator: "&")
            return a
        }
    }
}
