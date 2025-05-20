//
//  RequestBuilder.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/15.
//

import Foundation

class RequestBuilder {
    typealias HttpRequestHeader = [String:String]
    
    static func buildRequest(
        method: Endpoints.HttpMethod,
        host: String,
        path: String,
        queryItems: [URLQueryItem],
        body: Data? = nil,
        needAppId: Bool = false,
        optHost: String? = nil,
        referer: String? = nil,
        origin: String? = nil,
        user: RequestingUser? = nil,
        needRequestWith: Bool = false,
        ds: String? = nil
    ) -> URLRequest {
        var component = URLComponents()
        component.scheme = "https"
        component.host = host
        component.path = path
        component.queryItems = queryItems
        let url = component.url!
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // 添加设备基本信息
        deviceBasicHeader.forEach { (key: String, value: String) in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 160 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.71.1", forHTTPHeaderField: "User-Agent")
        
        //自定义可选请求头区域
        if needAppId {
            appIdHeader.forEach { (key: String, value: String) in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        if let referer = referer {
            request.setValue(referer, forHTTPHeaderField: "Referer")
        }
        if let origin = origin {
            request.setValue(origin, forHTTPHeaderField: "Origin")
        }
        if let user = user {
            request.setValue(user.toRequestHeader(), forHTTPHeaderField: "cookie")
        }
        if needRequestWith {
            request.setValue("com.mihoyo.hyperion", forHTTPHeaderField: "X-Requested-With")
        }
        if let ds = ds {
            request.setValue(ds, forHTTPHeaderField: "DS")
        }
        if let optHost = optHost {
            request.setValue(optHost, forHTTPHeaderField: "Host")
        }
        
        // 加入请求体
        if let body = body {
            request.httpBody = body
            request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        }
        
        return request
    }
}

extension RequestBuilder {
    static var deviceBasicHeader: HttpRequestHeader {
        return [
            "x-rpc-device_fp": ConfigManager.getSettingsValue(key: ConfigKey.DEVICE_FP, value: ""),
            "x-rpc-device_name": "iPhone15,1",
            "x-rpc-device_id": ConfigManager.getSettingsValue(key: ConfigKey.DEVICE_ID, value: ""),
            "x-rpc-sys_version": "18_0"
        ]
    }
    
    private static var appIdHeader: HttpRequestHeader {
        return [
            "x-rpc-app_id": "bll8iq97cem8",
            "x-rpc-client_type": "2",
            "x-rpc-app_version": "2.71.1",
            //"x-rpc-verify_key": "bll8iq97cem8"
        ]
    }
}

extension RequestBuilder {
    struct RequestingUser {
        let uid: String
        let stoken: String
        let mid: String
        
        init(uid: String, stoken: String, mid: String) {
            self.uid = uid
            self.stoken = stoken
            self.mid = mid
        }
        
        func toRequestHeader() -> String {
            return "stuid=\(uid);stoken=\(stoken);mid=\(mid)"
        }
    }
}
