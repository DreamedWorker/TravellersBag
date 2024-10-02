//
//  HutaoRecords.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/1.
//

import SwiftUI

struct HutaoRecords: View {
    @Environment(\.managedObjectContext) private var dm
    @StateObject private var viewModel = HutaoGachaModel()
    @State private var deleteAlert: Bool = false
    
    var body: some View {
        ScrollView {
            if viewModel.showUI {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "cloud").font(.title2)
                        Text("hutao.gacha.record").font(.title2).bold()
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .help("dashboard.unit.widget.refresh")
                            .onTapGesture {
                                viewModel.fetchRecordInfo(isRefresh: true)
                                GlobalUIModel.exported.makeAnAlert(type: 1, msg: NSLocalizedString("wizard.neo.op_ok", comment: ""))
                            }
                    }
                    if viewModel.gachaCloudRecord.count > 0 {
                        ForEach(viewModel.gachaCloudRecord) { entry in
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
                                            Task { await viewModel.updateRecordFromHutao() }
                                        },
                                        label: { Image(systemName: "square.and.arrow.down.on.square") }
                                    ).help("hutao.gacha.sync_with_cloud")
                                    Button(
                                        action: { deleteAlert = true },
                                        label: { Image(systemName: "trash").foregroundStyle(.red) }
                                    ).help("hutao.gacha.delete")
                                })
                                HStack {
                                    Spacer()
                                    Button("hutao.gacha.upload", action: {
                                        Task {
                                            await viewModel.uploadGachaRecord(isFullUpload: entry.ItemCount == 0)
                                        }
                                    }).buttonStyle(BorderedProminentButtonStyle())
                                }
                            }
                            .padding()
                        }
                    } else {
                        Image(systemName: "camera.metering.none")
                        Text("hutao.gacha.no_record")
                        Button("hutao.gacha.upload", action: {
                            Task { await viewModel.uploadGachaRecord(isFullUpload: true) }
                        }).buttonStyle(BorderedProminentButtonStyle())
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            } else {
                Text("app.waiting").onAppear { viewModel.initSomething(dm: dm) }
            }
        }
        .padding()
        .navigationTitle(Text("hutao.gacha.title"))
        .alert(
            "app.warning", isPresented: $deleteAlert,
            actions: {
                Button(
                    role: .destructive,
                    action: {
                        deleteAlert = false
                        Task { await viewModel.deleteCloudRecord() }
                    },
                    label: { Text("app.confirm") }
                )
            },
            message: { Text("hutao.gacha.delete_p") }
        )
    }
}
