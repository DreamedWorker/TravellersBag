//
//  WebBrowser.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/25.
//

import SwiftUI
import WebKit

struct WebBrowser: NSViewRepresentable {
    typealias NSViewType = WKWebView
    
    let webView: WKWebView = WKWebView()
    let initialWeb: String
    
    init(initialWeb: String) {
        self.initialWeb = initialWeb
    }
    
    func makeNSView(context: Context) -> WKWebView {
        webView.configuration.websiteDataStore = .default()
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) Mobile miHoYoBBS/2.71.1"
        webView.load(URLRequest(url: URL(string: initialWeb)!))
    }
}
