//
//  CommonJsBrg.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/5.
//

import Foundation
import WebKit

class JsBridgeHelper {
    private init() {}
    static let `default` = JsBridgeHelper()
    
    func communicateWithWeb(web: WKWebView, callback: String, method: String, data: NSDictionary? = nil) {
        @Sendable func sendToWeb(payload: String? = nil) {
            let js = "javascript:mhyWebBridge(\"\(callback)\"\(payload != nil ? "," + payload! : ""))"
            Task {
                DispatchQueue.main.async {
                    web.evaluateJavaScript(js){(_, e) in
                        if e == nil {
                            print("完成\(method)")
                            if method == "login" {
                                web.evaluateJavaScript("location.reload(true)")
                            }
                        } else {
                            print("执行js报错：\(String(describing: e))")
                        }
                    }
                }
            }
        }
        
        switch method {
        case "getStatusBarHeight":
            sendToWeb(payload: """
{"retcode":0, "message":"", "data":{"statusBarHeight":0}}
""")
            break
        case "getCookieInfo":
            let user = GlobalUIModel.exported.defAccount!
            sendToWeb(payload: """
{"retcode":0, "message":"", "data":{"ltuid":"\(user.stuid!)", "ltoken":"\(user.ltoken!)", "login_ticket":""}}
""")
            break
        case "getDS":
            sendToWeb(payload: """
{"retcode":0, "message":"", "data":{"DS": "\(JsDs().genDs4Js())"}}
""")
            break
        case "getDS2":
            sendToWeb(payload: """
{"retcode":0, "message":"", "data":{"DS": "\(JsDs().genDs2ForJs(q: ((data!["payload"] as! NSDictionary)["query"] as! NSDictionary), b: (data!["payload"] as! NSDictionary)["body"] as! String))"}}
""")
            break
        case "getHTTPRequestHeaders":
            sendToWeb(payload: """
{"retcode":0, "message":"", "data":{"x-rpc-client_type":"5", "x-rpc-device_id":"\(UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_ID, def: ""))", "x-rpc-app_version": "\(TBEnv.xrpcVersion)", "x-rpc-app_id":"bll8iq97cem8", "x-rpc-sdk_version":"2.16.0", "x-rpc-device_fp": "\(UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_FP, def: ""))", "Content-Type":"application/json", "x-rpc-device_name":"iPhone15,1", "x-rpc-sys_version":"16_0"}}
""")
            break
        case "getCookieToken":
            let user = GlobalUIModel.exported.defAccount!
            Task {
                do {
                    let token = try await AccountService.shared.pullUserCookieToken(uid: user.stuid!, token: user.gameToken!)
                    print("新token:\(token)")
                    print("旧token:\(user.cookieToken!)")
                    DispatchQueue.main.async {
                        sendToWeb(payload: """
            {"retcode":0, "message":"", "data":{"cookie_token":"\(token)"}}
            """)
                        web.reload()
                    }
                } catch {
                    print("cookie_ticket_error:\(error.localizedDescription)")
                }
            }
            break
        case "getActionTicket":
            let a = (data!["payload"] as! NSDictionary)["action_type"] as! String
            Task {
                do {
                    var req = URLRequest(url: URL(string: "https://api-takumi.mihoyo.com/auth/api/getActionTicketBySToken?action_type=\(a)")!)
                    req.setIosUA()
                    req.setDS(version: SaltVersion.V1, type: SaltType.K2)
                    req.setUser(singleUser: GlobalUIModel.exported.defAccount!)
                    req.setDeviceInfoHeaders()
                    req.setXRPCAppInfo()
                    let result = try await req.receiveOrThrow()
                    let payload = """
{"retcode":0, "message":"", "data": {"action_ticket": "\(result["ticket"].stringValue)"}}
"""
                    print(payload)
                    DispatchQueue.main.async {
                        sendToWeb(payload: payload)
                    }
                } catch {
                    print("action_ticket_error:\(error.localizedDescription)")
                }
            }
            break
        default:
            break
        }
    }
}
