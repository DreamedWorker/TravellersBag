//
//  FeedbackScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/5.
//

import SwiftUI
import Sentry

struct FeedbackScreen: View {
    @StateObject private var viewModel = FeedbackModel()
    
    var body: some View {
        ScrollView {
            VStack {
                TextField("feedback.page.title", text: $viewModel.title)
                    .textFieldStyle(.roundedBorder).font(.title2).padding(8)
                Text("feedback.page.title_explanation")
                    .multilineTextAlignment(.leading).foregroundStyle(.secondary).font(.callout)
                    .padding(.horizontal, 8).padding(.bottom, 8)
            }
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .padding(.bottom, 16)
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "lightbulb.max").font(.title2)
                    Text("feedback.page.context").font(.title2).bold()
                    Spacer()
                }.padding(.horizontal, 16).padding(.top, 16)
                Text("feedback.page.context_exp").font(.callout).padding(.leading, 16)
                Divider().padding(.horizontal, 16)
                TextEditor(text: $viewModel.context)
                    .lineSpacing(5).border(.gray.opacity(0.5), width: 1)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .font(.system(size: 13))
                    .padding(.horizontal, 16).padding(.vertical, 4)
                    .frame(minHeight: 200, maxHeight: 400)
                TextField("feedback.page.email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder).padding(.horizontal, 16).padding(.vertical, 8)
                Text("feedback.page.email_exp").font(.callout).foregroundStyle(.secondary).padding(.horizontal, 16)
            }
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .padding(.bottom, 16)
        }
        .navigationTitle(Text("home.sider.feedback"))
        .padding()
        .toolbar {
            ToolbarItem {
                Button(
                    action: { viewModel.sendMessage() },
                    label: { Image(systemName: "paperplane").help("feedback.page.send") })
            }
        }
    }
}

private class FeedbackModel: ObservableObject {
    @Published var title = ""
    @Published var context = ""
    @Published var email = ""
    
    func sendMessage() {
        let eventId = SentrySDK.capture(message: context)
        let userFeedback = UserFeedback(eventId: eventId)
        userFeedback.comments = title
        userFeedback.email = email
        SentrySDK.capture(userFeedback: userFeedback)
        HomeController.shared.showInfomationDialog(msg: "完成")
        title = ""; context = ""; email = ""
    }
}
