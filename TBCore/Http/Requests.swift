//
//  Requests.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/9.
//

import Foundation
import SwiftyJSON

// 处理POST和GET方法的回单
extension URLRequest {
    /// 通用的获取json响应内容的方法。 【用于替代receiveData】
    /// - Parameters:
    ///   - isPost 是否采用POST方法 默认采用GET
    ///   - reqBody 请求体，在前者为false时无需理会
    /// - Returns:
    ///   - JSON 的data部分，类型为JSON
    /// - Throws:
    ///   - 从返回值中提取并手动抛出，或在解析json、发出http请求时自动抛出
    mutating func receiveOrThrow(isPost: Bool = false, reqBody: Data? = nil) async throws -> JSON {
        if isPost { // 设定请求方法 已知水社只需要下面两个方法就够了
            self.httpMethod = "POST"
            self.httpBody = reqBody
        } else {
            self.httpMethod = "GET"
        }
        let (data, _) = try await httpSession().data(for: self)
        let json = try JSON(data: data)
        if json["retcode"].intValue == 0 {
            return json["data"]
        } else {
            throw NSError(domain: "http.request", code: json["retcode"].intValue, userInfo: [NSLocalizedDescriptionKey: "\(json["message"].string ?? "未知错误")"])
        }
    }
    
    /// 适用于向胡桃api请求时使用的请求方式
    mutating func receiveOrThrowHutao(isPost: Bool = false, reqBody: Data? = nil) async throws -> JSON {
        if isPost { // 设定请求方法 已知水社只需要下面两个方法就够了
            self.httpMethod = "POST"
            self.httpBody = reqBody
        } else {
            self.httpMethod = "GET"
        }
        let (data, _) = try await httpSession().data(for: self)
        let json = try JSON(data: data)
        if json["retcode"].intValue == 0 {
            return json
        } else {
            throw NSError(domain: "http.request", code: json["retcode"].intValue, userInfo: [NSLocalizedDescriptionKey: "\(json["message"].string ?? "未知错误")"])
        }
    }
}

// 处理几个常用请求头
extension URLRequest {
    /// 设置设备基本信息
    mutating func setDeviceInfoHeaders() {
        self.setValue(TBCore.shared.configGetConfig(forKey: TBCore.DEVICE_FP, def: ""), forHTTPHeaderField: "x-rpc-device_fp")
        self.setValue("iPhone15,1", forHTTPHeaderField: "x-rpc-device_name")
        self.setValue(TBCore.shared.configGetConfig(forKey: TBCore.DEVICE_ID, def: ""), forHTTPHeaderField: "x-rpc-device_id")
        self.setValue("16_0", forHTTPHeaderField: "x-rpc-sys_version")
    }
    
    /// 设置动态密钥
    mutating func setDS(version: SaltVersion, type: SaltType, body: String = "", q: String = "", include: Bool = true) {
        self.setValue(getDynamicSecret(version: version, saltType: type, includeChars: include, query: q, body: body), forHTTPHeaderField: "DS")
    }
    
    /// 设置 Host
    mutating func setHost(host: String) {
        self.setValue(host, forHTTPHeaderField: "Host")
    }
    
    /// 设置 Referer
    mutating func setReferer(referer: String) {
        self.setValue(referer, forHTTPHeaderField: "Referer")
    }
    
    /// 设置用户信息
//    mutating func setUser(singleUser: ShequAccount) {
//        self.setValue("stuid=\(singleUser.stuid!);stoken=\(singleUser.stoken!);mid=\(singleUser.mid!);", forHTTPHeaderField: "cookie")
//    }
    
    mutating func setUser(uid: String, stoken: String, mid: String) {
        self.setValue("stuid=\(uid);stoken=\(stoken);mid=\(mid);", forHTTPHeaderField: "cookie")
    }
    
    /// 设置UA
    mutating func setUA() {
        self.setValue(TBCore.hoyoUA, forHTTPHeaderField: "User-Agent")
    }
    
    mutating func setIosUA() {
        self.setValue(TBCore.iosHoyoUA, forHTTPHeaderField: "User-Agent")
    }
    
    /// 设置请求头app信息
    mutating func setXRPCAppInfo(appID: String = "bll8iq97cem8", client: String = "2") {
        self.setValue(appID, forHTTPHeaderField: "x-rpc-app_id")
        self.setValue(client, forHTTPHeaderField: "x-rpc-client_type")
        self.setValue(TBCore.xrpcVersion, forHTTPHeaderField: "x-rpc-app_version")
    }
    
    /// 设置 X-Requested-With
    mutating func setXRequestWith() {
        self.setValue("com.mihoyo.hyperion", forHTTPHeaderField: "X-Requested-With")
    }
}
