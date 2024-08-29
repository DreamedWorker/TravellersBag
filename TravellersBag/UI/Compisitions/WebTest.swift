//
//  WebTest.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/20.
//

import SwiftUI
import WebKit

struct WebTest: View {
    var body: some View {
        VStack {
            WebView().frame(width: 420, height: 600)
        }
    }
}

private struct DynamicSecret2Payload {
    let query: NSDictionary
    
    init(query: NSDictionary) {
        self.query = query
    }
    
    // 转换query参数为URL查询字符串的方法
    func getQueryParam() -> String {
        let a = query.map { (key, value) -> String in
            // 注意：这里对value进行了简单的字符串转换，实际使用中可能需要根据value的类型做特殊处理
            // 比如，如果value是数组或字典，需要递归转换
            // 这里为了简化，直接使用了`String(describing:)`，它可能不适用于所有情况
            // let valueString = String(describing: value)
            // URL编码
            //let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            //let encodedValue = valueString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? valueString
            return "\(key)=\(value)"
        }.joined(separator: "&")
        print(a)
        return a
    }
}

private struct WebView: NSViewRepresentable {
    let webView: WKWebView
    
    init(webView: WKWebView = WKWebView()) {
        self.webView = webView
    }
    
    class Coordinator : NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parentContainer: WebView
        init(parentContainer: WebView) {
            self.parentContainer = parentContainer
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if !message.name.isEmpty {
                let data = (message.body as! NSDictionary)
                let method = (data["method"]) as! String
                switch method {
                case "getStatusBarHeight":
                    sendToWeb(method: method, callback: data["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"statusBarHeight":0}}
""")
                    break
                case "getCookieInfo":
                    let user = HomeController.shared.currentUser!
                    sendToWeb(method: method, callback: data["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"ltuid":"\(user.stuid!)", "ltoken":"\(user.ltoken!)", "login_ticket":""}}
""")
                    break
                case "getCookieToken":
                    let user = HomeController.shared.currentUser!
                    sendToWeb(method: method, callback: data["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"cookie_token":"\(user.cookieToken!)"}}
""")
                    break
                case "login":
                    sendToWeb(method: method, callback: "login", payload: nil)
                    break
                case "getDS":
                    sendToWeb(method: method, callback: data["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"DS": "\(getDynamicSecret(version: SaltVersion.V1, saltType: SaltType.LK2))"}}
""")
                    break
                case "getDS2":
                    print(data["payload"] as! NSDictionary)
                    sendToWeb(method: method, callback: data["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"DS": "\(getDynamicSecret(
version: SaltVersion.V2, saltType: SaltType.X4,
includeChars: false, query: DynamicSecret2Payload(query: ((data["payload"] as! NSDictionary)["query"]) as! NSDictionary).getQueryParam(),
body: (data["payload"] as! NSDictionary)["body"] as! String))"}}
""")
                    break
                case "getHTTPRequestHeaders":
                    sendToWeb(method: method, callback: data["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"x-rpc-client_type":"5", "x-rpc-device_id":"\(LocalEnvironment.shared.getEnvStringValue(key: LocalEnvironment.DEVICE_ID))", "x-rpc-app_version": "\(LocalEnvironment.xrpcVersion)", "x-rpc-app_id":"bll8iq97cem8", "x-rpc-sdk_version":"2.16.0", "x-rpc-device_fp": "\(LocalEnvironment.shared.getEnvStringValue(key: LocalEnvironment.DEVICE_FP))", "Content-Type":"application/json", "x-rpc-device_name":"iPhone15,1", "x-rpc-sys_version":"16_0"}}
""")
                    break
                case "eventTrack":
                    //sendToWeb(method: method, callback: "eventTrack", payload: nil)
                    break
                case "closePage":
                    //parentContainer.webView.goBack()
                    break
                case "getActionTicket":
                    let a = data["callback"] as! String
                    Task {
                        do {
                            var req = URLRequest(url: URL(string: "https://api-takumi.mihoyo.com/auth/api/getActionTicketBySToken?action_type=login")!)
                            req.setIosUA()
                            req.setDS(version: SaltVersion.V1, type: SaltType.K2)
                            req.setUser(singleUser: HomeController.shared.currentUser!)
                            req.setDeviceInfoHeaders()
                            req.setXRPCAppInfo()
                            let result = try await req.receiveOrThrow()
                            let payload = """
{"retcode":0, "message":"", "data": \(result.rawString()!)}
"""
                            print(payload)
                            DispatchQueue.main.async {
                                self.sendToWeb(method: method, callback: a, payload: payload)
                            }
                        } catch {
                            print("action_ticket_error:\(error.localizedDescription)")
                        }
                    }
                    break
                default:
                    print(method)
                    break
                }
            }
        }
        
        func sendToWeb(method: String, callback: String, payload: String? = nil) {
            let web = self.parentContainer
            let js = "javascript:mhyWebBridge(\"\(callback)\"\(payload != nil ? "," + payload! : ""))"
            Task {
                DispatchQueue.main.async {
                    web.webView.evaluateJavaScript(js){(_, e) in
                        if e == nil {
                            print("完成\(method)")
                            if method == "login" {
                                web.webView.evaluateJavaScript("location.reload(true)")
                            }
                        } else {
                            print("执行js报错：\(String(describing: e))")
                        }
                    }
                }
            }
        }
    }
    
    func makeNSView(context: Context) -> some NSView {
        let user = HomeController.shared.currentUser!
        webView.navigationDelegate = context.coordinator
        webView.configuration.userContentController.add(context.coordinator, name: "miHoYo")
        webView.configuration.websiteDataStore = WKWebsiteDataStore.default()
        let a = webView.configuration.websiteDataStore.httpCookieStore
        a.setCookie(HTTPCookie(properties: [.name:"ltuid", .value:user.stuid!, .domain:".miyoho.com", .path:"/"])!)
        a.setCookie(HTTPCookie(properties: [.name:"ltoken", .value:user.ltoken!, .domain:".miyoho.com", .path:"/"])!)
        a.setCookie(HTTPCookie(properties: [.name:"mid", .value:user.mid!, .domain:".miyoho.com", .path:"/"])!)
        a.setCookie(HTTPCookie(properties: [.name:"cookie_token", .value:user.cookieToken!, .domain:".miyoho.com", .path:"/"])!)
        a.setCookie(HTTPCookie(properties: [.name:"account_id", .value:user.stuid!, .domain:".miyoho.com", .path:"/"])!)
        return webView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        let web = nsView as! WKWebView
        let url = URL(string: "https://webstatic.mihoyo.com/app/community-game-records/")!
        //let url = URL(string: "https://webstatic.mihoyo.com/app/")!
        //let url = URL(string: "https://user.mihoyo.com")!
        var req = URLRequest(url: url)
        //req.setValue("", forHTTPHeaderField: "If-Modified-Since")
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo(client: "5")
//        req.setDS(version: SaltVersion.V2, type: SaltType.X4, include: false)
//        req.setXRequestWith()
        //req.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
//        req.setValue("https://webstatic.mihoyo.com", forHTTPHeaderField: "Origin")
//        req.setReferer(referer: "https://webstatic.mihoyo.com")
//        req.setValue("v4.8.3-ys_#/ys", forHTTPHeaderField: "x-rpc-page")
//        req.setValue("v4.8.3-ys", forHTTPHeaderField: "x-rpc-tool_version")
        req.setValue("2", forHTTPHeaderField: "x-rpc-challenge_game")
        req.setValue("https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/index", forHTTPHeaderField: "x-rpc-challenge_path")
        web.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) Mobile miHoYoBBS/2.71.1"
        (nsView as! WKWebView).load(req)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parentContainer: self)
    }
}

#Preview {
    WebTest()
}
