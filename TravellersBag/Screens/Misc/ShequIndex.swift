//
//  ShequIndex.swift
//  TravellersBag
//  米游社 「我的」-- 「「原神」卡片」 中的内容；开出这个页面另一方面主要是用于人机验证？不好说
//  Created by 鸳汐 on 2024/10/5.
//

import SwiftUI
import WebKit

struct ShequIndexView: View {
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
        let url = URL(string: "https://webstatic.mihoyo.com/app/community-game-records/")!
        var req = URLRequest(url: url)
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo(client: "5")
        req.setValue("2", forHTTPHeaderField: "x-rpc-challenge_game")
        req.setValue("https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/index", forHTTPHeaderField: "x-rpc-challenge_path")
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
                if method != "setPresentationStyle" {
                    if method == "getDS2" || method == "getActionTicket" {
                        JsBridgeHelper.default.communicateWithWeb(
                            web: parentContainer.webView, callback: data["callback"] as! String, method: method, data: data
                        )
                    } else {
                        if method != "eventTrack" {
                            if method == "pushPage" {
                                let nextPage = (data["payload"] as! NSDictionary)["page"] as! String
                                if nextPage.contains("adopt_calculator") ||
                                    nextPage.contains("ysjournal") ||
                                    nextPage.contains("lineup-fe") || nextPage.contains("e20221121ugc")
                                {
                                    GlobalUIModel.exported.makeAnAlert(type: 3, msg: "请避免在此打开该旅行工具。")
                                } else {
                                    parentContainer.webView.load(URLRequest(url: URL(string: nextPage)!))
                                }
                            } else if method == "closePage" {
                                if parentContainer.webView.canGoBack {
                                    parentContainer.webView.goBack()
                                }
                            } else if method == "login" || method == "configure_share" {
                                //parentContainer.webView.reload()
                            } else {
                                let callback: String = data["callback"] as? String ?? ""
                                JsBridgeHelper.default.communicateWithWeb(
                                    web: parentContainer.webView, callback: callback, method: method
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
