//
//  WebStaticView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/20.
//

import SwiftUI
import SwiftData
import WebKit
import SwiftyJSON

struct WebStaticView: View {
    let requiredPage: String
    @Query private var accounts: [HoyoAccount]
    
    var body: some View {
        if let account = accounts.filter({ $0.activedAccount }).first {
            NavigationStack {
                GeometryReader { geo in
                    WebStaticWebView(account: account, webURL: requiredPage)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .navigationTitle(Text("webpage.title"))
        } else {
            ContentUnavailableView("app.blocked.needDefAccount", systemImage: "hand.raised")
                .navigationTitle(Text("webpage.title"))
        }
    }
}

struct WebStaticWebView: NSViewRepresentable {
    let webView: WKWebView
    let account: HoyoAccount
    let webURL: String
    typealias NSViewType = WKWebView
    
    init(webView: WKWebView = WKWebView(), account: HoyoAccount, webURL: String) {
        self.webView = webView
        self.account = account
        self.webURL = webURL
    }
    
    func makeNSView(context: Context) -> WKWebView {
        webView.configuration.websiteDataStore = .default()
        webView.configuration.userContentController.add(context.coordinator, name: "miHoYo")
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        var webRequest = URLRequest(url: URL(string: webURL)!)
        RequestBuilder.deviceBasicHeader.forEach { (key: String, value: String) in
            webRequest.setValue(value, forHTTPHeaderField: key)
        }
        [
            "x-rpc-app_id": "bll8iq97cem8",
            "x-rpc-client_type": "5",
            "x-rpc-app_version": "2.71.1",
        ].forEach { (key: String, value: String) in
            webRequest.setValue(value, forHTTPHeaderField: key)
        }
        webRequest.setValue("2", forHTTPHeaderField: "x-rpc-challenge_game")
        webRequest.setValue("https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/index", forHTTPHeaderField: "x-rpc-challenge_path")
        nsView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) Mobile miHoYoBBS/2.71.1"
        nsView.load(webRequest)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parentContainer: self.webView, account: account)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parentContainer: WKWebView
        let account: HoyoAccount
        
        init(parentContainer: WKWebView, account: HoyoAccount) {
            self.parentContainer = parentContainer
            self.account = account
            super.init()
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            let msgData = message.body as! NSDictionary
            let method = msgData["method"] as! String
            switch method {
            case "getStatusBarHeight":
                send2web(callback: msgData["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"statusBarHeight":0}}
""")
                break
            case "getCookieInfo":
                send2web(callback: msgData["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"ltuid":"\(account.cookie.stuid)", "ltoken":"\(account.cookie.ltoken)", "login_ticket":""}}
""")
                break
            case "getDS":
                send2web(callback: msgData["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"DS": "\(JsDs.genDs4Js())"}}
""")
                break
            case "getDS2":
                send2web(callback: msgData["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"DS": "\(JsDs.genDs2ForJs(q: ((msgData["payload"] as! NSDictionary)["query"] as! NSDictionary), b: (msgData["payload"] as! NSDictionary)["body"] as! String))"}}
""")
                break
            case "getHTTPRequestHeaders":
                send2web(callback: msgData["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"x-rpc-client_type":"5", "x-rpc-device_id":"\(ConfigManager.getSettingsValue(key: ConfigKey.DEVICE_ID, value: ""))", "x-rpc-app_version": "2.71.1", "x-rpc-app_id":"bll8iq97cem8", "x-rpc-sdk_version":"2.16.0", "x-rpc-device_fp": "\(ConfigManager.getSettingsValue(key: ConfigKey.DEVICE_FP, value: ""))", "Content-Type":"application/json", "x-rpc-device_name":"iPhone15,1", "x-rpc-sys_version":"18_0"}}
""")
                break
            case "pushPage":
                let nextPage = (msgData["payload"] as! NSDictionary)["page"] as! String
                parentContainer.load(URLRequest(url: URL(string: nextPage)!))
                break
            case "closePage":
                if parentContainer.canGoBack {
                    parentContainer.goBack()
                }
                break
            case "getCookieToken":
                send2web(callback: msgData["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"cookie_token":"\(account.cookie.cookieToken)"}}
""")
                break
            case "getActionTicket":
                Task.detached {
                    let a = (msgData["payload"] as! NSDictionary)["action_type"] as! String
                    let callback = msgData["callback"] as! String
                    var atRequest = URLRequest(url: URL(string: "https://api-takumi.mihoyo.com/auth/api/getActionTicketBySToken?action_type=\(a)")!)
                    atRequest.setValue(
                        "Mozilla/5.0 (iPhone; CPU iPhone OS 160 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.71.1",
                        forHTTPHeaderField: "User-Agent"
                    )
                    atRequest.setValue(DynamicSecret.getDynamicSecret(version: .V1, saltType: .K2), forHTTPHeaderField: "DS")
                    atRequest.setValue(
                        RequestBuilder.RequestingUser(
                            uid: self.account.cookie.stuid,
                            stoken: self.account.cookie.stoken,
                            mid: self.account.cookie.mid
                        ).toRequestHeader(),
                        forHTTPHeaderField: "cookie"
                    )
                    RequestBuilder.deviceBasicHeader.forEach { (key: String, value: String) in
                        atRequest.setValue(value, forHTTPHeaderField: key)
                    }
                    [
                        "x-rpc-app_id": "bll8iq97cem8",
                        "x-rpc-client_type": "5",
                        "x-rpc-app_version": "2.71.1",
                    ].forEach { (key: String, value: String) in
                        atRequest.setValue(value, forHTTPHeaderField: key)
                    }
                    URLSession.shared.dataTask(with: atRequest, completionHandler: { data,_,_ in
                        if let data = data {
                            let value = try? JSON(data: data)
                            if let value = value {
                                let ticket = value["data"]["ticket"].stringValue
                                DispatchQueue.main.async {
                                    self.send2web(callback: callback, payload: """
{"retcode":0, "message":"", "data": {"action_ticket": "\(ticket)"}}
""")
                                }
                            }
                        }
                    }).resume()
                }
                break
            default:
                break
            }
        }
        
        private func send2web(callback: String, payload: String? = nil) {
            let js = "javascript:mhyWebBridge(\"\(callback)\"\(payload != nil ? "," + payload! : ""))"
            parentContainer.evaluateJavaScript(js) { (_, e) in
                if let e = e {
                    print("执行js报错：\(String(describing: e))")
                }
            }
        }
    }
}
