//
//  NoticeViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/2/9.
//

import Foundation

class NoticeViewModel: ObservableObject {
    enum PageState {
        case Loading; case Finished; case Failed
    }
    @Published var loadingState: PageState = .Loading
    @Published var contentList: AnnouncementList? = nil
    @Published var contentDetailList: AnnouncementContents? = nil
    
    func getNotices() async {
        switch await NoticeService.fetchNoticeList() {
        case .success(let result):
            switch await NoticeService.fetchNoticeContent() {
            case .success(let contentResult):
                await MainActor.run {
                    contentList = result; contentDetailList = contentResult
                    if result.list.count != 0 && contentResult.list.count != 0 {
                        loadingState = .Finished
                    } else {
                        loadingState = .Failed
                    }
                }
            case .failure(_):
                await MainActor.run(body: {
                    loadingState = .Failed
                })
            }
        case .failure(_):
            await MainActor.run(body: {
                loadingState = .Failed
            })
        }
    }
}
