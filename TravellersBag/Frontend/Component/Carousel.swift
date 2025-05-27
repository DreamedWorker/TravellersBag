//
//  Carousel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/2/10.
//

import SwiftUI
import Kingfisher

struct Carousel: View {
    @State private var currentIndex = 0
    @State private var isLeftArrowVisible = false
    @State private var isRightArrowVisible = false
    
    var contentList: [AnnounceRepo.AnnoStruct.AnnoList]
    let wikiGachaPoolList: AnnoGachaPoolRepo.GachaPools?
    
    init(neoList: [AnnounceRepo.AnnoStruct.AnnoList], gachaPools: AnnoGachaPoolRepo.GachaPools? = nil) {
        self.wikiGachaPoolList = gachaPools
        let list = neoList.sorted(
            by: { DateHelper.string2date(str: $0.startTime) > DateHelper.string2date(str: $1.startTime)}
        )
        var neoList: [AnnounceRepo.AnnoStruct.AnnoList] = []
        if let gachas = gachaPools {
            list.forEach { single in
                if gachas.data.list.contains(where: { $0.title == single.subtitle }) {
                    neoList.append(single)
                }
            }
            self.contentList = neoList
        } else {
            self.contentList = list
        }
//        if list.count <= 3 {
//            self.contentList = list
//        } else {
//            if list.count <= 4 {
//                self.contentList = list
//            } else {
//                if Date.now >= DateHelper.string2date(str: list.first!.startTime) {
//                    self.contentList = list[3...].shuffled()
//                } else {
//                    self.contentList = list[..<3].shuffled()
//                }
//            }
//        }
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack(alignment: .center) {
                    ZStack(alignment: .bottom) {
                        KFImage(URL(string: contentList[currentIndex].banner)!)
                            .loadDiskFileSynchronously(true)
                            .placeholder {
                                ProgressView()
                                    .frame(width: geometry.size.width, height: geometry.size.height / 2)
                            }
                            .resizable()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(width: geometry.size.width, height: 230)
                    }
                    HStack {
                        if isLeftArrowVisible {
                            Image(systemName: "chevron.left")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                                .onTapGesture {
                                    withAnimation {
                                        currentIndex = (currentIndex > 0) ? currentIndex - 1 : contentList.count - 1
                                    }
                                }
                                .opacity(isLeftArrowVisible ? 1 : 0)
                                .animation(.easeInOut(duration: 0.3), value: isLeftArrowVisible)
                        }
                        Spacer()
                        if isRightArrowVisible {
                            Image(systemName: "chevron.right")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                                .onTapGesture {
                                    withAnimation {
                                        currentIndex = (currentIndex < contentList.count - 1) ? currentIndex + 1 : 0
                                    }
                                }
                                .opacity(isRightArrowVisible ? 1 : 0)
                                .animation(.easeInOut(duration: 0.3), value: isRightArrowVisible)
                        }
                    }
                    .padding()
                }
                .onHover { hovering in
                    switch hovering {
                    case true:
                        withAnimation {
                            isLeftArrowVisible = true
                            isRightArrowVisible = true
                        }
                    case false:
                        withAnimation {
                            isLeftArrowVisible = false
                            isRightArrowVisible = false
                        }
                    }
                }
            }
            .frame(height: 230)
            VStack {
                HStack {
                    Text("notice.gacha.title").font(.title2).bold()
                    Spacer()
                }.padding(.bottom, 2)
                HStack {
                    Text(
                        String.localizedStringWithFormat(
                            NSLocalizedString("notice.gacha.exp", comment: ""),
                            (wikiGachaPoolList == nil) ? contentList.first!.startTime : wikiGachaPoolList!.data.list.first!.startTime,
                            (wikiGachaPoolList == nil) ? contentList.first!.endTime : wikiGachaPoolList!.data.list.first!.endTime
                        )
                    ).foregroundStyle(.secondary).font(.callout)
                    Spacer()
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.tertiary.opacity(0.3)))
        }
    }
}

#Preview {
    Carousel(neoList: [])
}
