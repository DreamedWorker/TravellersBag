//
//  NoticeDetailBrowser.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/8.
//

import SwiftUI
import WebKit
import SwiftyJSON
import Kingfisher

extension NoticeView {
    struct NoticeDetailBrowser: View {
        let entry: JSON?
        let dismiss: () -> Void
        
        var body: some View {
            if let entry = entry {
                NavigationStack {
                    NoticeView(context: entry["content"].stringValue).frame(width: 600, height: 500)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction, content: {
                        Button("def.cancel", action: { dismiss() })
                    })
                }
            } else {
                Image("home_waiting").resizable().frame(width: 72, height: 72)
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
    """
        }
        
        func makeNSView(context: Context) -> some NSView {
            return webView
        }
        
        func updateNSView(_ nsView: NSViewType, context: Context) {
            let web = nsView as! WKWebView
            web.loadHTMLString(content, baseURL: nil)
        }
    }
}

extension NoticeView {
    struct NoticeNormalDetail: View {
        let a: NoticeEntry
        let getNoticeDetail: (Int) -> JSON?
        
        @State var showThisDetail: Bool = false
        
        private func cutStr(a: String) -> String {
            return String(a.prefix(upTo: a.index(a.startIndex, offsetBy: 10)))
        }
        
        var body: some View {
            VStack {
                KFImage(URL(string: a.banner))
                    .loadDiskFileSynchronously(true)
                    .placeholder({ ProgressView() })
                    .resizable()
                    .frame(height: 72)
                Text(a.subtitle).font(.title3).bold()
                Text(a.title).font(.callout).padding(.bottom, 4).lineLimit(1).padding(.horizontal, 2)
                VStack {
                    HStack {
                        Spacer()
                        Text(a.type_label).font(.footnote).foregroundStyle(.secondary)
                    }
                    HStack {
                        Spacer()
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("notice.main.gacha_time_p", comment: ""),
                            cutStr(a: a.start), cutStr(a: a.end)
                        )
                        ).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .onTapGesture { showThisDetail = true }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .sheet(
                isPresented: $showThisDetail,
                content: { NoticeDetailBrowser(entry: getNoticeDetail(a.id), dismiss: { showThisDetail = false }) }
            )
        }
    }
}
