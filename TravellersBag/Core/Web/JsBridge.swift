//
//  JsBridge.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/13.
//

import Foundation
import WebKit
import SwiftyJSON

final class JsBridge : @unchecked Sendable {
    
    private static func send2web(web: WKWebView, callback: String, payload: String? = nil) {
        let js = "javascript:mhyWebBridge(\"\(callback)\"\(payload != nil ? "," + payload! : ""))"
        Task {
            DispatchQueue.main.async {
                web.evaluateJavaScript(js){ (_, e) in
                    if e != nil {
                        print("执行js报错：\(String(describing: e))")
                    }
                }
            }
        }
    }
    
    @MainActor static func communicateWithWeb(web: WKWebView, callback: String, method: String, account: MihoyoAccount, data: NSDictionary? = nil) {
        switch method {
        case "getStatusBarHeight":
            send2web(web: web, callback: callback, payload: """
{"retcode":0, "message":"", "data":{"statusBarHeight":0}}
""")
            break
        case "getCookieInfo":
            send2web(web: web, callback: callback, payload: """
{"retcode":0, "message":"", "data":{"ltuid":"\(account.cookies.stuid)", "ltoken":"\(account.cookies.ltoken)", "login_ticket":""}}
""")
            break
        case "getDS":
            send2web(web: web, callback: callback, payload: """
{"retcode":0, "message":"", "data":{"DS": "\(JsDs().genDs4Js())"}}
""")
            break
        case "getDS2":
            send2web(web: web, callback: callback, payload: """
{"retcode":0, "message":"", "data":{"DS": "\(JsDs().genDs2ForJs(q: ((data!["payload"] as! NSDictionary)["query"] as! NSDictionary), b: (data!["payload"] as! NSDictionary)["body"] as! String))"}}
""")
            break
        case "getHTTPRequestHeaders":
            send2web(web: web, callback: callback, payload: """
{"retcode":0, "message":"", "data":{"x-rpc-client_type":"5", "x-rpc-device_id":"\(UserDefaults.standard.string(forKey: TBData.DEVICE_ID) ?? "")", "x-rpc-app_version": "\(TBData.xrpcVersion)", "x-rpc-app_id":"bll8iq97cem8", "x-rpc-sdk_version":"2.16.0", "x-rpc-device_fp": "\(UserDefaults.standard.string(forKey: TBData.DEVICE_FP) ?? "")", "Content-Type":"application/json", "x-rpc-device_name":"iPhone15,1", "x-rpc-sys_version":"16_0"}}
""")
            break
        case "getCookieToken":
            send2web(web: web, callback: callback, payload: """
{"retcode":0, "message":"", "data":{"cookie_token":"\(account.cookies.cookieToken)"}}
""")
            break
        case "getActionTicket":
            let a = (data!["payload"] as! NSDictionary)["action_type"] as! String
            var req = URLRequest(url: URL(string: "https://api-takumi.mihoyo.com/auth/api/getActionTicketBySToken?action_type=\(a)")!)
            req.setIosUA()
            req.setDS(version: SaltVersion.V1, type: SaltType.K2)
            req.setUser(uid: account.cookies.stuid, stoken: account.cookies.stoken, mid: account.cookies.mid)
            req.setDeviceInfoHeaders()
            req.setXRPCAppInfo(client: "5")
            Task {
                do {
                    let result = try await JSON(data: req.receiveOrBlackData())
                    if result.contains(where: { $0.0 == "ProgramError" }) {
                        throw NSError()
                    }
                    let payload = """
{"retcode":0, "message":"", "data": {"action_ticket": "\(result["ticket"].stringValue)"}}
"""
                    DispatchQueue.main.async {
                        self.send2web(web: web, callback: callback, payload: payload)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.send2web(web: web, callback: callback, payload: """
{"retcode":0, "message":"", "data": {"action_ticket": ""}}
""")
                    }
                }
            }
            break
        default:
            break
        }
    }
}
