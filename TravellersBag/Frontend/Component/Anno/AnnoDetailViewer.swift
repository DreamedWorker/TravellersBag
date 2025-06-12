//
//  AnnoDetailViewer.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/28.
//

import SwiftUI
import WebKit

struct AnnoDetailViewer: View {
    let detail: AnnoDetailStruct.DetailList.AnnoUnit?
    
    var body: some View {
        if let confirmed = detail {
            VStack {
                Text(confirmed.title).font(.title.bold()).padding(.vertical)
                AnnoBrowser(detail: confirmed.content)
                    .frame(width: 600, height: 450)
            }
            .background(.thinMaterial)
        } else {
            Image(systemName: "camera.metering.none").resizable().frame(width: 72, height: 72)
        }
    }
}

struct AnnoBrowser: NSViewRepresentable {
    let webView: WKWebView
    let detail: String
    typealias NSViewType = WKWebView
    
    init(webView: WKWebView = WKWebView(), detail: String) {
        self.webView = webView
        self.detail = detail
    }
    
    func makeNSView(context: Context) -> WKWebView {
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(detail, baseURL: nil)
    }
}
