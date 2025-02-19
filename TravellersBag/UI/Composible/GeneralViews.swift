//
//  GeneralViews.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/2/10.
//

import SwiftUI

//MARK: - 加载失败页面
struct GeneralFailedPage: View {
    let retryMethod: () -> Void
    
    init(retryMethod: @escaping () -> Void) {
        self.retryMethod = retryMethod
    }
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.warninglight")
                .resizable().fontWeight(.black)
                .padding(.bottom, 2)
                .frame(width: 72, height: 72)
            Text("def.pane.errorTitle")
                .font(.title2).fontWeight(.black)
                .padding(.bottom, 4)
            Button("def.pane.errorRetry", action: retryMethod)
                .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.background))
    }
}
