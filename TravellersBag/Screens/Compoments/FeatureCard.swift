//
//  FeatureCard.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/5.
//

import SwiftUI

extension WizardFirstScreen {
    /// 向用户展示 Apple 风格的软件特性
    struct FeatureCard: View {
        private var iconName: String // 特征图标
        private var titleKey: String // 特征标题
        private var contextKey: String // 特征简介
        
        init(iconName: String, titleKey: String, contextKey: String) {
            self.iconName = iconName
            self.titleKey = titleKey
            self.contextKey = contextKey
        }
        
        var body: some View {
            HStack(alignment: .center) {
                Spacer()
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.accent)
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading) {
                    Text(NSLocalizedString(titleKey, comment: ""))
                        .font(.callout)
                        .bold()
                    Text(NSLocalizedString(contextKey, comment: ""))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 8)
                Spacer()
            }
        }
    }
}
