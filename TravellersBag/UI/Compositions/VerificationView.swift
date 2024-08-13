//
//  VerificationView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/13.
//

import Foundation
import SwiftUI
import WebKit

/// 为完成人机任务准备的浏览器窗口
struct VerificationView : NSViewRepresentable {
    let webView: WKWebView
    let challenge: String
    let gt: String
    @State var completion: (String) -> ()
    
    init(
        webView: WKWebView = WKWebView(),
        challenge: String,
        gt: String,
        completion: @escaping (String) -> Void
    ) {
        self.webView = webView
        self.challenge = challenge
        self.gt = gt
        self.completion = completion
    }
    
    class Coordinator : NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parentContainer: VerificationView
        init(parentContainer: VerificationView) {
            self.parentContainer = parentContainer
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "callbackHandler" {
                if let messageBody = message.body as? String {
                    //print("validate: \(messageBody)")
                    parentContainer.verifiedResult(callback: messageBody)
                }
            }
        }
    }
    
    func makeNSView(context: Context) -> some NSView {
        webView.navigationDelegate = context.coordinator
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        webView.configuration.userContentController.add(context.coordinator, name: "callbackHandler")
        webView.customUserAgent = LocalEnvironment.hoyoUA
        return webView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        let url = URL(string: "https://gi.pizzastudio.org/geetest/")! // 这里使用了来自“原神披萨小助手”已经搭建好的服务器提供服务。（自己的域名还没备案
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "challenge", value: challenge),
            URLQueryItem(name: "gt", value: gt),
        ]
        guard let finalOne = components?.url else {
            return
        }
        var request = URLRequest(url: finalOne)
        request.allHTTPHeaderFields = [ "Referer": "https://webstatic.mihoyo.com" ]
        (nsView as! WKWebView).load(request)
    }
    
    func verifiedResult(callback: String) {
        //self.webView
        completion(callback)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parentContainer: self)
    }
}
