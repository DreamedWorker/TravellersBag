//
//  NoticeView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/28.
//

import AppKit
import SwiftUI
import Kingfisher

struct NoticeView: View {
    @StateObject private var viewModel = NoticeViewModel()
    
    @ViewBuilder
    var body: some View {
        switch viewModel.loadingState {
        case .Loading:
            ProgressView()
                .onAppear {
                    Task { await viewModel.getNotices() }
                }
        case .Finished: // 这里说明没有出错并且列表不是空的
            NoticeContext.background(.background)
        case .Failed:
            GeneralFailedPage(retryMethod: {})
        }
    }
    
    private var NoticeContext: some View {
        struct NoticeUnit: View {
            let entity: AnnouncementList.ListList
            @State private var showMore: Bool = false
            let queryItem: (Int) -> AnnouncementContents.DetailList?
            
            var body: some View {
                VStack {
                    KFImage(URL(string: entity.banner))
                        .loadDiskFileSynchronously(true)
                        .placeholder {
                            ProgressView()
                        }
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(height: 60)
                    HStack {
                        Text(entity.typeLabel.rawValue)
                            .foregroundStyle(.secondary).bold()
                        Spacer()
                    }.padding(.top, 2)
                    HStack {
                        Text(entity.title).bold()
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.bottom, 4)
                .onTapGesture {
                    showMore = true
                }
                .sheet(isPresented: $showMore, content: {
                    if let msg = queryItem(entity.annID) {
                        NoticeDetailView(dismiss: { showMore = false }, entity: msg)
                    }
                })
            }
        }
        
        return NavigationStack {
            ScrollView {
                LazyVStack {
                    Carousel(
                        neoList: viewModel.contentList!.list
                            .filter({ $0.typeLabel == .活动公告 }).first!.list
                            .filter({ $0.tagLabel == .扭蛋 })
                    )
                    HStack {
                        Text("notice.recent").font(.title2).bold()
                        Spacer()
                    }.padding(.top, 4)
                    LazyVGrid(
                        columns: [.init(.flexible()), .init(.flexible()), .init(.flexible()), .init(.flexible())],
                        spacing: 8
                    ) {
                        ForEach(viewModel.contentList!.list.filter({ $0.typeLabel == .活动公告 }).first!.list, id: \.self) {
                            single in
                            NoticeUnit(
                                entity: single,
                                queryItem: { it in
                                    return viewModel.contentDetailList!.list.filter({ $0.annID == it }).first
                                }
                            )
                        }
                        ForEach(viewModel.contentList!.list.filter({ $0.typeLabel == .游戏公告 }).first!.list, id: \.self) {
                            single in
                            NoticeUnit(
                                entity: single,
                                queryItem: { it in
                                    return viewModel.contentDetailList!.list.filter({ $0.annID == it }).first
                                }
                            )
                        }
                    }
                }
            }
        }.padding(.all, 20)
    }
}

struct NoticeDetailView: View {
    let dismiss: () -> Void
    let entity: AnnouncementContents.DetailList
    @State private var viewAsWebView: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    KFImage(URL(string: entity.banner))
                        .loadDiskFileSynchronously(true)
                        .placeholder {
                            ProgressView()
                        }
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(height: 100)
                    Text(entity.title).font(.title2).bold().padding(.vertical, 4)
                    Text(convertHTMLToAttributedString(html: entity.content)).fontDesign(.default)
                }
            }
        }
        .padding(20)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("def.cancel", action: dismiss)
            }
        }
    }
    
    func convertHTMLToAttributedString(html: String) -> AttributedString {
        let data = html.data(using: .utf8)
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
        ]
        do {
            let nsAttributedString = try NSAttributedString(data: data!, options: options, documentAttributes: nil)
            return try AttributedString(nsAttributedString, including: \.appKit)
        } catch {
            return AttributedString()
        }
    }
}
