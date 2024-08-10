//
//  CardView.swift
//  TravellingBag
//
//  Created by 鸳汐 on 2024/8/2.
//

import SwiftUI
import Kingfisher

struct AnnouncementCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let banner: String
    let annID: String
    let subtitle: String
    
    var body: some View {
        VStack {
            KFImage(URL(string: banner))
                .placeholder(
                    {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 36))
                    }
                )
                .loadDiskFileSynchronously(true)
                .resizable()
                .frame(width: 250, height: 130)
                .padding(0)
                .aspectRatio(contentMode: .fill)
            HStack {
                Text(title).font(.title3).bold()
                Spacer()
            }.padding(.bottom, 4).frame(width: 220)
            HStack {
                Text(subtitle).multilineTextAlignment(.leading).font(.callout).lineLimit(2)
                Spacer()
            }.frame(width: 220).padding(.bottom, 0)
            Spacer()
        }
        .frame(height: 210)
        .background(colorScheme == .dark ? Color.gray.opacity(0.8) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8.0))
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 8)
        .onTapGesture {
            print(annID)
        }
    }
}

struct CardView<ChildView: View> : View {
    @Environment(\.colorScheme) private var colorScheme
    let content: () -> ChildView
    
    var body: some View {
        VStack(content: content)
            .background(colorScheme == .dark ? Color.gray.opacity(0.8) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8.0))
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 8)
    }
}

#Preview {
    AnnouncementCardView(
        title: "测试标题",
        //banner: "https://sdk-webstatic.mihoyo.com/announcement/2020/11/11/a539394edc88c73effd030507be02681_8843944720719944518.jpg",
        banner: "",
        annID: "annid",
        subtitle: "「活动」测试副标题"
    )
}
