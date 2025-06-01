//
//  NoticeNormalDetail.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/1.
//

import SwiftUI
import Kingfisher

extension AnnouncementView {
    struct NoticeNormalDetail: View {
        let a: AnnounceRepo.AnnoStruct.AnnoList
        
        private func convertDateString(_ input: String) -> String {
            let inputFormat = "yyyy-MM-dd HH:mm:ss"
            let outputFormat = "yyyy/MM/dd HH:mm"
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = inputFormat
            guard let date = dateFormatter.date(from: input) else {
                return input
            }
            dateFormatter.dateFormat = outputFormat
            return dateFormatter.string(from: date)
        }
        
        var body: some View {
            VStack {
                KFImage(URL(string: a.banner))
                    .loadDiskFileSynchronously(true)
                    .resizable()
                    .frame(height: 72)
                Text(a.subtitle).bold()
                Text(a.title).font(.footnote).foregroundStyle(.secondary)
                    .padding(.bottom, 4).lineLimit(1).padding(.horizontal, 2)
                HStack {
                    Spacer()
                    Text(a.typeLabel.rawValue).font(.footnote).foregroundStyle(.secondary)
                }.padding(.horizontal, 2)
                HStack() {
                    Label(
                        String.localizedStringWithFormat(
                            NSLocalizedString("anno.label.date", comment: ""),
                            convertDateString(a.startTime),
                            convertDateString(a.endTime)
                        ),
                        systemImage: "calendar"
                    ).font(.footnote)
                    Spacer()
                }
                .padding(.horizontal, 2).padding(.bottom, 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
        }
    }
}

