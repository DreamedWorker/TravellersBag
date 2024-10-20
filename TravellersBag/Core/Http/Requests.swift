//
//  Requests.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/9.
//

import Foundation
import SwiftyJSON

/// 返回一个默认的会话
func httpSession() -> URLSession {
    return URLSession.shared // 由于无需考虑用户是否使用代理（不走代理），故仅用默认的即可。
}

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
            let (data, _) = try await session.data(for: self)
            return EventMessager(evtState: true, data: String(data: data, encoding: .utf8)!)
        } catch {
            return EventMessager(evtState: false, data: error.localizedDescription)
        }
    }
}

// 处理几个常用请求头
extension URLRequest {
    /// 设置设备基本信息
    mutating func setDeviceInfoHeaders() {
        self.setValue(UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_FP, def: ""), forHTTPHeaderField: "x-rpc-device_fp")
        //self.setValue("Unknown Android SDK built for arm64", forHTTPHeaderField: "x-rpc-device_name")
        self.setValue("iPhone15,1", forHTTPHeaderField: "x-rpc-device_name")
        self.setValue(UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_ID, def: ""), forHTTPHeaderField: "x-rpc-device_id")
        //self.setValue("Android SDK built for arm64", forHTTPHeaderField: "x-rpc-device_model")
        //self.setValue("12", forHTTPHeaderField: "x-rpc-sys_version")
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
    mutating func setUser(singleUser: ShequAccount) {
        self.setValue("stuid=\(singleUser.stuid!);stoken=\(singleUser.stoken!);mid=\(singleUser.mid!);", forHTTPHeaderField: "cookie")
    }
    
    mutating func setUser(uid: String, stoken: String, mid: String) {
        self.setValue("stuid=\(uid);stoken=\(stoken);mid=\(mid);", forHTTPHeaderField: "cookie")
    }
    
    /// 设置UA
    mutating func setUA() {
        self.setValue(TBEnv.hoyoUA, forHTTPHeaderField: "User-Agent")
    }
    
    mutating func setIosUA() {
        self.setValue(TBEnv.iosHoyoUA, forHTTPHeaderField: "User-Agent")
    }
    
    /// 设置请求头app信息
    mutating func setXRPCAppInfo(appID: String = "bll8iq97cem8", client: String = "2") {
        self.setValue(appID, forHTTPHeaderField: "x-rpc-app_id")
        self.setValue(client, forHTTPHeaderField: "x-rpc-client_type")
        self.setValue(TBEnv.xrpcVersion, forHTTPHeaderField: "x-rpc-app_version")
    }
    
    /// 设置 X-Requested-With
    mutating func setXRequestWith() {
        self.setValue("com.mihoyo.hyperion", forHTTPHeaderField: "X-Requested-With")
    }
}

//下载功能
extension URLSession {
    /// 下载文件，你提供的url必须是位于沙盘中的路径
    func download2File(url: URL, req: URLRequest) async throws {
        let data = try await self.download(for: req)
        if FileManager.default.fileExists(atPath: url.path().removingPercentEncoding!) {
            // 存在旧文件的话就删除，不然下面的moveItem方法会报错。
            try! FileManager.default.removeItem(at: url)
        }
        try FileManager.default.moveItem(at: data.0, to: url)
    }
    
    /// 下载文件任务，你提供的url必须是位于沙盘中的路径（用于监听进度）
    func buildDownloadTask(url: URL, req: URLRequest) -> URLSessionDownloadTask {
        let downloadTask = self.downloadTask(with: req, completionHandler: { (tempUrl, response, errors) in
            if errors != nil { return }
            if let content = tempUrl {
                if FileManager.default.fileExists(atPath: url.path().removingPercentEncoding!) {
                    try! FileManager.default.removeItem(at: url)
                }
                try! FileManager.default.moveItem(at: content, to: url)
            }
        })
        return downloadTask
    }
}

