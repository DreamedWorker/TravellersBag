//
//  DailyNoteTile.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/10.
//

import SwiftUI

struct DailyNoteTile: View {
    let imgName: String
    let title: String
    let state: String
    let useVStack: Bool
    var body: some View {
        if !useVStack {
            HStack {
                Image(imgName).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32).padding(.leading, 2)
                Text(title).font(.headline).bold()
                Spacer()
                Text(state).padding(.trailing, 2)
            }.border(.gray.opacity(0.4), width: 0.5).padding(2)
        } else {
            VStack {
                Image(imgName).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20).padding(.top, 2)
                Text(title).font(.headline).bold()
                    .padding(.horizontal, 2)
                Spacer()
                Text(state).padding(.horizontal, 2).padding(.vertical, 2)
            }.border(.gray.opacity(0.4), width: 0.5).padding(2)
        }
    }
}

#Preview {
    DailyNoteTile(imgName: "", title: "", state: "", useVStack: true)
}
