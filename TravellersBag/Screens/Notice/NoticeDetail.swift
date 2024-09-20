//
//  NoticeDetail.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/19.
//

import SwiftUI
import SwiftyJSON
import WebKit

struct NoticeDetail: View {
    let single: JSON?
    
    var body: some View {
        if single != nil {
            NoticeView(context: single!["content"].stringValue)
                .navigationTitle(Text(single!["title"].stringValue))
        } else {
            VStack {
                Image("expecting_but_nothing").resizable().scaledToFit().frame(width: 72, height: 72)
                Text("notice.detail.no_content").font(.title2).bold().padding(.top, 8)
            }
            .frame(minWidth: 100, maxWidth: 500)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
        }
    }
}

private struct NoticeView: NSViewRepresentable {
    let webView: WKWebView
    let content: String
    
    init(webView: WKWebView = WKWebView(), context: String) {
        self.webView = webView
        self.content = """
<html lang="zh">
<head> <meta charset="utf-8" /> <title>通知内容</title> </head>
<body style="font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;"> \(context) </body>
</html>
""".replacingOccurrences(of: "\\", with: "")
    }
    
    func makeNSView(context: Context) -> some NSView {
        return webView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        let web = nsView as! WKWebView
        web.loadHTMLString(content, baseURL: nil)
    }
}
