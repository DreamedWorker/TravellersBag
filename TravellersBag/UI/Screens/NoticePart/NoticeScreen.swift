//
//  NoticeScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/21.
//

import SwiftUI

struct NoticeScreen: View {
    var body: some View {
        Button("app.name", action: {
            HomeController.shared.showInfomationDialog(msg: "你好")
        })
    }
}

#Preview {
    NoticeScreen()
}
