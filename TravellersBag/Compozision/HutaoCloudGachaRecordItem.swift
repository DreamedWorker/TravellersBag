//
//  HutaoCloudGachaRecordItem.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/11.
//

import SwiftUI

extension HutaoLogin {
    struct HutaoCloudGachaRecordItem: View {
        let entry: HutaoRecordEntry
        let deleteAction: () -> Void
        let syncAction: () -> Void
        let updateRecordFromHutao: () -> Void
        let upload2hutao: (Bool) -> Void
        
        var body: some View {
            VStack {
                HStack(spacing: 8, content: {
                    Image(systemName: "waveform.circle").font(.title3)
                    VStack(alignment: .leading, content: {
                        Text(String.localizedStringWithFormat(NSLocalizedString("hutao.gacha.uid", comment: ""), entry.id))
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString("hutao.gacha.count", comment: ""), String(entry.ItemCount))
                        ).font(.callout).foregroundStyle(.secondary)
                    })
                    Spacer()
                    Button(
                        action: {
                            updateRecordFromHutao()
                        },
                        label: { Image(systemName: "square.and.arrow.down.on.square") }
                    ).help("hutao.gacha.sync_with_cloud")
                    Button(
                        action: deleteAction,
                        label: { Image(systemName: "trash").foregroundStyle(.red) }
                    ).help("hutao.gacha.delete")
                })
                HStack {
                    Spacer()
                    Button("hutao.gacha.sync", action: syncAction)
                    Button("hutao.gacha.upload", action: {
                        upload2hutao(entry.ItemCount == 0)
                        Task {
//                                            await viewModel.uploadGachaRecord(isFullUpload: entry.ItemCount == 0)
                        }
                    }).buttonStyle(BorderedProminentButtonStyle())
                }
            }
        }
    }
}
