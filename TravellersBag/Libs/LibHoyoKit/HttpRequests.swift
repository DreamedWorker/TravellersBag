//
//  HttpRequests.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/5.
//

import Foundation
import MMKV

/// 返回一个默认的会话
func httpSession() -> URLSession {
    return URLSession.shared // 由于无需考虑用户是否使用代理（不走代理），故仅用默认的即可。
}

// 处理POST和GET方法的回单
extension URLRequest {
    /// 通用的获取json响应内容的方法。
    /// - Parameters:
    ///   - session http会话
    ///   - isPost 是否采用POST方法 默认采用GET
    ///   - reqBody 请求体，在前者为false时无需理会
    mutating func receiveData(session: URLSession, isPost: Bool = false, reqBody: Data?) async -> EventMessager {
        do {
            if isPost {
                self.httpMethod = "POST"
                self.httpBody = reqBody
            } else {
                self.httpMethod = "GET"
            }
            let (data, response) = try await session.data(for: self)
            return EventMessager(evtState: true, data: String(data: data, encoding: .utf8)!)
        } catch {
            return EventMessager(evtState: false, data: error.localizedDescription)
        }
    }
}

// 处理几个常用请求头
extension URLRequest {
    /// 设置设备基本信息
    mutating func setDeviceInfoHeaders() -> URLRequest {
        self.setValue("", forHTTPHeaderField: "x-rpc-device_fp")
        self.setValue("Unknown Android SDK built for arm64", forHTTPHeaderField: "x-rpc-device_name")
        self.setValue(MMKV.default()!.string(forKey: LocalEnvironment.DEVICE_ID)!, forHTTPHeaderField: "x-rpc-device_id")
        self.setValue("Android SDK built for arm64", forHTTPHeaderField: "x-rpc-device_model")
        return self
    }
    
    /// 设置动态密钥
    mutating func setDS(version: SaltVersion, type: SaltType, body: String = "", q: String = "") -> URLRequest {
        self.setValue(getDynamicSecret(version: version, saltType: type, query: q, body: body), forHTTPHeaderField: "DS")
        return self
    }
    
    /// 设置 Host
    mutating func setHost(host: String) -> URLRequest {
        self.setValue(host, forHTTPHeaderField: "Host")
        return self
    }
    
    /// 设置 Referer
    mutating func setReferer(referer: String) -> URLRequest {
        self.setValue(referer, forHTTPHeaderField: "Referer")
        return self
    }
    
    /// 设置用户信息
    // TODO: 待Cookie存储完成后
    mutating func setUser() -> URLRequest {
        return self
    }
    
    /// 设置UA
    mutating func setUA() -> URLRequest {
        self.setValue(LocalEnvironment.hoyoUA, forHTTPHeaderField: "User-Agent")
        return self
    }
    
    /// 设置请求头app信息
    mutating func setXRPCAppInfo(appID: String = "bll8iq97cem8") -> URLRequest {
        self.setValue(appID, forHTTPHeaderField: "x-rpc-app_id")
        self.setValue("2", forHTTPHeaderField: "x-rpc-client_type")
        self.setValue(LocalEnvironment.xrpcVersion, forHTTPHeaderField: "x-rpc-app_version")
        return self
    }
}
