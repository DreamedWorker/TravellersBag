//
//  MDLikeTile.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/16.
//

import SwiftUI

/// 创建一个在布局风格上逼近 jetpack compose 中的 ListTile 的显示条
struct MDLikeTile: View {
    let leadingIcon: String
    let endIcon: String
    let title: String
    let onClick: () -> Void
    
    var body: some View {
        Button(
            action: { onClick() },
            label: {
                HStack {
                    Image(systemName: leadingIcon).padding(.trailing, 8)
                    Text(title)
                    Spacer()
                    Image(systemName: endIcon)
                }.padding()
            }
        )
    }
}

#Preview {
    MDLikeTile(leadingIcon: "house", endIcon: "house", title: "app.name", onClick: {})
}
