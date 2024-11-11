//
//  NoticeScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/9.
//

import SwiftUI
import SwiftyJSON
import Kingfisher
import WebKit

struct NoticeScreen: View {
    @StateObject private var viewModel = NoticeScreenViewModel()
    @State private var uiPart: NoticePart = .Game
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack(spacing: 8) {
                    Image(systemName: "app.gift").font(.title)
                    Text("notice.main.current_gacha").font(.title).bold()
                    Spacer()
                }.padding()
                GachaTime(gachaNote: viewModel.announcementContext.filter({ $0.subtitle.contains("祈愿") }).first)
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], content: {
                    ForEach(viewModel.announcementContext.filter({ $0.subtitle.contains("祈愿") })) { a in
                        @State var showSheet: Bool = false
                        CurrentGacha(a: a, getContent: { want in return viewModel.getNoticeDetailEntry(id: a.id) })
                    }
                }).padding(.horizontal, 16).padding(.bottom, 8) // 罗列当期全部卡池
            }
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .padding(.horizontal, 16).padding(.top, 8)
            TabView(selection: $uiPart, content: {
                DisplayPart(
                    parts: viewModel.announcementContext.filter({ $0.type == 1 }),
                    goTo: { want in return viewModel.getNoticeDetailEntry(id: want) }
                ).tabItem({ Text("notice.tag.game") }).tag(NoticePart.Game)
                DisplayPart(
                    parts: viewModel.announcementContext.filter({ $0.type == 2 }),
                    goTo: { want in return viewModel.getNoticeDetailEntry(id: want) }
                ).tabItem({ Text("notice.tag.notice") }).tag(NoticePart.Notice)
            }).padding(.horizontal, 16)
        }
        .navigationTitle(Text("home.sidebar.notice"))
        .onAppear {
            Task {
                await viewModel.fetchAnnouncement()
                await viewModel.fetchNewsDetail()
            }
        }
        .toolbar {
            ToolbarItem {
                Button(
                    action: { Task { await viewModel.refreshSource() }},
                    label: { Image(systemName: "arrow.clockwise").help("notice.menu.refresh")}
                )
            }
        }
    }
    
    // 显示卡池活动时间和进度条呈现方式
    private struct GachaTime: View {
        let gachaNote: NoticeEntry?
        
        var body: some View {
            if let note = gachaNote {
                VStack(alignment: .leading, content: {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                        Text("notice.main.gacha_time")
                        Spacer()
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString("notice.main.gacha_time_p", comment: ""), note.start, note.end)
                        ).font(.callout).foregroundStyle(.secondary)
                    }
                    ProgressView(
                        value: 1 - (Float(dateSpacer(s1: Date.now, s2: note.end)) / Float(dateSpacer(s1: note.start, s2: note.end))),
                        total: 1.0)
                }).padding(.horizontal, 16)
            }
        }
        
        private func dateSpacer(s1: Date, s2: String) -> Int {
            let b = string2date(str: s2)
            let r = Calendar.current.dateComponents([.day], from: s1, to: b).day ?? 0
            return r
        }
        
        private func dateSpacer(s1: String, s2: String) -> Int {
            let b = string2date(str: s2); let a = string2date(str: s1)
            let r = Calendar.current.dateComponents([.day], from: a, to: b).day ?? 0
            return r
        }
        
        private func string2date(str: String) -> Date {
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return format.date(from: str)!
        }
    }
    
    // 显示当期卡池的图片 点按后弹出sheet
    private struct CurrentGacha: View {
        @State var showSheet: Bool = false
        let a: NoticeEntry
        let getContent: (Int) -> JSON?
        
        var body: some View {
            VStack {
                KFImage(URL(string: a.banner))
                    .loadDiskFileSynchronously(true)
                    .placeholder({ ProgressView() })
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onTapGesture {
                showSheet = true
            }
            .sheet(isPresented: $showSheet, content: { AnnouncementContent(entry: getContent(a.id), dismiss: { showSheet = false }) })
        }
    }
    
    // 分页内容显示根
    private struct DisplayPart: View {
        let parts: [NoticeEntry]?
        let goTo: (Int) -> JSON?
        
        var body: some View {
            ScrollView {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], content: {
                    if let part = parts {
                        ForEach(part, id: \.annId) { a in
                            NormalAnnouncementDisplay(a: a, json: goTo(a.annId))
                        }
                    }
                })
            }
        }
        
        struct NormalAnnouncementDisplay: View {
            let a: NoticeEntry
            let json: JSON?
            @State var showSheet: Bool = false
            
            var body: some View {
                VStack {
                    KFImage(URL(string: a.banner))
                        .loadDiskFileSynchronously(true)
                        .placeholder({ ProgressView() })
                        .resizable()
                        .frame(height: 72)
                    Text(a.subtitle).font(.title3).bold()
                    Text(a.title).font(.callout).padding(.bottom, 4).lineLimit(1).padding(.horizontal, 2)
                    HStack {
                        Spacer()
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("notice.main.gacha_time_p", comment: ""),
                            cutStr(a: a.start), cutStr(a: a.end)
                        )
                        ).font(.footnote).foregroundStyle(.secondary)
                    }.padding(2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                .onTapGesture {
                    showSheet = true
                }
                .sheet(isPresented: $showSheet, content: { AnnouncementContent(entry: json, dismiss: { showSheet = false }) })
            }
            
            private func cutStr(a: String) -> String {
                return String(a.prefix(upTo: a.index(a.startIndex, offsetBy: 10)))
            }
        }
    }
}

// web页面sheet
private struct AnnouncementContent: View {
    let entry: JSON?
    let dismiss: () -> Void

    var body: some View {
        if let entry = entry {
            NavigationStack {
                NoticeView(context: entry["content"].stringValue).frame(width: 600, height: 500)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("app.cancel", action: { dismiss() })
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

class NoticeScreenViewModel: ObservableObject {
    let noticeRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "notice")
    let fs = FileManager.default
    
    @Published var alertMate = AlertMate()
    @Published var announcementContext: [NoticeEntry] = []
    @Published var announcementDetail: [JSON] = []
    
    init() {
        if !FileManager.default.fileExists(atPath: noticeRoot.toStringPath()) {
            try! FileManager.default.createDirectory(at: noticeRoot, withIntermediateDirectories: true)
        }
    }
    
    func fetchAnnouncement() async {
        let localFile = noticeRoot.appending(component: "notice_list.json")
        if fs.fileExists(atPath: localFile.toStringPath()) {
            do {
                let context = try JSON(data: FileHandler.shared.readUtf8String(path: localFile.toStringPath()).data(using: .utf8)!)
                DispatchQueue.main.async {
                    self.getNoticeProgressed(list: context["list"].arrayValue)
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMate.showAlert(msg: "无法读取本地缓存，\(error.localizedDescription)")
                }
            }
        } else {
            fs.createFile(atPath: localFile.toStringPath(), contents: nil)
            do {
                var req = URLRequest(url: URL(string: ApiEndpoints.shared.getHk4eAnnouncement())!)
                let result = try await req.receiveOrThrow()
                FileHandler.shared.writeUtf8String(path: localFile.toStringPath(), context: result.rawString()!)
                let noticeList = result["list"].arrayValue
                DispatchQueue.main.async {
                    self.getNoticeProgressed(list: noticeList)
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMate.showAlert(msg: "无法获取通知公告，\(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 获取通知的详细信息
    func fetchNewsDetail() async {
        let localFile = noticeRoot.appending(component: "notice_context.json")
        if fs.fileExists(atPath: localFile.toStringPath()) {
            do {
                let context = try JSON(data: FileHandler.shared.readUtf8String(path: localFile.toStringPath()).data(using: .utf8)!)
                DispatchQueue.main.async {
                    for i in context["list"].arrayValue { self.announcementDetail.append(i) }
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMate.showAlert(msg: "无法读取本地缓存，\(error.localizedDescription)")
                }
            }
        } else {
            fs.createFile(atPath: localFile.toStringPath(), contents: nil)
            do {
                var req = URLRequest(url: URL(string: ApiEndpoints.shared.getHk4eAnnounceContext())!)
                let result = try await req.receiveOrThrow()
                FileHandler.shared.writeUtf8String(path: localFile.toStringPath(), context: result.rawString()!)
                DispatchQueue.main.async {
                    for i in result["list"].arrayValue { self.announcementDetail.append(i) }
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMate.showAlert(msg: "无法获取通知公告详情信息，\(error.localizedDescription)")
                }
            }
        }
    }
    
    func refreshSource() async {
        DispatchQueue.main.async { [self] in
            announcementDetail = []; announcementContext = []
        }
        let localDetail = noticeRoot.appending(component: "notice_context.json")
        if fs.fileExists(atPath: localDetail.toStringPath()) { try! fs.removeItem(at: localDetail) }
        let localList = noticeRoot.appending(component: "notice_list.json")
        if fs.fileExists(atPath: localList.toStringPath()) { try! fs.removeItem(at: localList) }
        await fetchAnnouncement()
        await fetchNewsDetail()
    }
    
    func getNoticeDetailEntry(id: Int) -> JSON? {
        return announcementDetail.filter({ $0["ann_id"].intValue == id }).first
    }
    
    /// 处理已经被初步处理过了的通知 这个一般是用于从云获取之后的通知筛选
    private func getNoticeProgressed(list: [JSON]) {
        var temp: [NoticeEntry] = []
        for i in list {
            let i1 = i["list"].arrayValue
            for j in i1 {
                temp.append(
                    NoticeEntry(
                        id: j["ann_id"].intValue,annId: j["ann_id"].intValue, title: j["title"].stringValue,
                        subtitle: j["subtitle"].stringValue, banner: j["banner"].stringValue, type_label: j["type_label"].stringValue,
                        type: j["type"].intValue, start: j["start_time"].stringValue, end: j["end_time"].stringValue
                    )
                )
            }
        }
        temp = temp.sorted(by: { string2date(str: $0.start) > string2date(str: $1.start) })
        announcementContext = temp
    }
    
    /// 字符串转时间对象
    private func string2date(str: String) -> Date {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return format.date(from: str)!
    }
}

enum NoticePart {
    case Notice
    case Game
}
