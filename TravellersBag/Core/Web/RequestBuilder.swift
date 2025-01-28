//
//  RequestBuilder.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/28.
//

import Foundation

extension URLRequest {
    /// 设置设备基本信息
    mutating func setDeviceInfoHeaders() {
        self.setValue(UserDefaults.standard.string(forKey: TBData.DEVICE_FP) ?? "", forHTTPHeaderField: "x-rpc-device_fp")
        self.setValue("iPhone15,1", forHTTPHeaderField: "x-rpc-device_name")
        self.setValue(UserDefaults.standard.string(forKey: TBData.DEVICE_ID) ?? "", forHTTPHeaderField: "x-rpc-device_id")
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
    mutating func setUser(singleUser: MihoyoAccount) {
        self.setValue(
            "stuid=\(singleUser.cookies.stuid);stoken=\(singleUser.cookies.stoken);mid=\(singleUser.cookies.mid);",
            forHTTPHeaderField: "cookie"
        )
    }
    
    mutating func setUser(uid: String, stoken: String, mid: String) {
        self.setValue("stuid=\(uid);stoken=\(stoken);mid=\(mid);", forHTTPHeaderField: "cookie")
    }
    
    /// 设置UA
    mutating func setUA() {
        self.setValue(TBData.hoyoUA, forHTTPHeaderField: "User-Agent")
    }
    
    mutating func setIosUA() {
        self.setValue(TBData.iosHoyoUA, forHTTPHeaderField: "User-Agent")
    }
    
    /// 设置请求头app信息
    mutating func setXRPCAppInfo(appID: String = "bll8iq97cem8", client: String = "2") {
        self.setValue(appID, forHTTPHeaderField: "x-rpc-app_id")
        self.setValue(client, forHTTPHeaderField: "x-rpc-client_type")
        self.setValue(TBData.xrpcVersion, forHTTPHeaderField: "x-rpc-app_version")
    }
    
    /// 设置 X-Requested-With
    mutating func setXRequestWith() {
        self.setValue("com.mihoyo.hyperion", forHTTPHeaderField: "X-Requested-With")
    }
}
