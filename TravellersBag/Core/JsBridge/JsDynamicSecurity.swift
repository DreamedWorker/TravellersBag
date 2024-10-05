//
//  JsDynamicSecurity.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/5.
//

import Foundation

struct JsDs {
    init() {}
    
    func genDs4Js() -> String {
        return getDynamicSecret(version: SaltVersion.V1, saltType: SaltType.LK2)
    }
    
    func genDs2ForJs(q: NSDictionary, b: String) -> String {
        return getDynamicSecret(version: .V2, saltType: .X4, includeChars: false, query: DynamicSecret4Payload(query: q).getQueryParam(), body: b)
    }
}

private struct DynamicSecret4Payload {
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
