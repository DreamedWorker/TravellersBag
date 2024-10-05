//
//  Adopt.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/5.
// https://webstatic.mihoyo.com/ys/event/e20200923adopt_calculator/index.html

import SwiftUI
import WebKit

struct AdoptCalculator: View {
    @State private var showUI: Bool = GlobalUIModel.exported.hasDefAccount()
    
    var body: some View {
        if showUI {
            WebView().frame(minHeight: 600)
        } else {
            VStack {
                Image("index_need_login").resizable().scaledToFit().frame(width: 72, height: 72)
                Text("daily.no_account.title").font(.title2).bold().padding(.bottom, 8)
                Button("dashboard.empty.refresh", action: {
                    GlobalUIModel.exported.refreshDefAccount()
                    showUI = GlobalUIModel.exported.hasDefAccount()
                }).buttonStyle(BorderedProminentButtonStyle())
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .frame(minWidth: 400)
        }
    }
}

private struct WebView: NSViewRepresentable {
    let webView: WKWebView
    
    init(webView: WKWebView = WKWebView()) {
        self.webView = webView
    }
    
    func makeNSView(context: Context) -> some NSView {
        let user = GlobalUIModel.exported.defAccount!
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
        let url = URL(string: "https://webstatic.mihoyo.com/ys/event/e20200923adopt_calculator/")!
        var req = URLRequest(url: url)
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo(client: "5")
//        req.setValue("2", forHTTPHeaderField: "x-rpc-challenge_game")
//        req.setValue("https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/index", forHTTPHeaderField: "x-rpc-challenge_path")
        web.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) Mobile miHoYoBBS/2.71.1"
        (nsView as! WKWebView).load(req)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parentContainer: self)
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
                print(data)
                switch method {
                case "getHTTPRequestHeaders":
                    sendToWeb(method: method, callback: data["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"x-rpc-client_type":"5", "x-rpc-device_id":"\(UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_ID, def: ""))", "x-rpc-app_version": "\(TBEnv.xrpcVersion)", "x-rpc-app_id":"bll8iq97cem8", "x-rpc-sdk_version":"2.16.0", "x-rpc-device_fp": "\(UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_FP, def: ""))", "Content-Type":"application/json", "x-rpc-device_name":"iPhone15,1", "x-rpc-sys_version":"16_0"}}
""")
                    break
                case "getStatusBarHeight":
                    sendToWeb(method: method, callback: data["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"statusBarHeight":0}}
""")
                    break
                case "getCookieToken":
                    let user = GlobalUIModel.exported.defAccount!
                    sendToWeb(method: method, callback: data["callback"] as! String, payload: """
{"retcode":0, "message":"", "data":{"cookie_token":"\(user.cookieToken!)"}}
""")
                    break
                case "getActionTicket":
                    Task {
                        do {
                            let a = data["callback"] as! String
                            let actionType = (data["payload"] as! NSDictionary)["action_type"] as! String
                            var req = URLRequest(url: URL(string: "https://api-takumi.mihoyo.com/auth/api/getActionTicketBySToken?action_type=\(actionType)")!)
                            req.setIosUA()
                            req.setDS(version: SaltVersion.V1, type: SaltType.K2)
                            req.setUser(singleUser: GlobalUIModel.exported.defAccount!)
                            req.setDeviceInfoHeaders()
                            req.setXRPCAppInfo(client: "5")
                            let result = try await req.receiveOrThrow()
                            DispatchQueue.main.async {
                                let payload = """
{"retcode":0, "message":"", "data": {"action_ticket": "\(result["ticket"].stringValue)"}}
"""
                                self.sendToWeb(method: method, callback: a, payload: payload)
                            }
                        } catch {
                            print("action_ticket_error:\(error.localizedDescription)")
                        }
                    }
                    break
                case "pushPage":
                    let nextPage = (data["payload"] as! NSDictionary)["page"] as! String
                    parentContainer.webView.load(URLRequest(url: URL(string: nextPage)!))
                    break
                case "closePage":
                    if parentContainer.webView.canGoBack {
                        parentContainer.webView.goBack()
                    }
                    break
                default:
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
                        if e != nil {
                            print("执行js报错：\(String(describing: e))")
                        }
                    }
                }
            }
        }
    }
}
