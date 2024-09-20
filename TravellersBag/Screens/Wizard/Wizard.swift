//
//  Wizard.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/15.
//

import SwiftUI
import AlertToast

struct Wizard: View {
    let goNext: () -> Void
    @StateObject var viewModel = WizardModel()
    @State var downloadStatic = false
    @State var operationFinished = false
    @State var agreed = UserDefaultHelper.shared.getValue(forKey: "license_agree", def: "no") == "yes"
    
    var body: some View {
        ScrollView {
            if agreed {
                CardView {
                    VStack(alignment: .leading) {
                        HStack(spacing: 16) {
                            Image(systemName: "externaldrive.connected.to.line.below").font(.title2)
                            Text("wizard.data.title").font(.title2)
                            Spacer()
                        }.padding(.bottom, 4)
                        Text("wizard.data.p1")
                        HStack(spacing: 16) {
                            Button("wizard.download", action: {
                                downloadStatic = true
                                Task {
                                    do {
                                        try await viewModel.showNeedDownloadFiles()
                                        try await viewModel.downloadCloudStaticData()
                                        DispatchQueue.main.async {
                                            self.downloadStatic = false
                                        }
                                        try await Task.sleep(for: .seconds(1.5))
                                        DispatchQueue.main.async {
                                            self.operationFinished = true
                                        }
                                    } catch {
                                        uploadAnError(fatalInfo: error)
                                        print(error)
                                        DispatchQueue.main.async {
                                            self.downloadStatic = false
                                            self.viewModel.showErrMsg(msg: "下载资源出错，\(error.localizedDescription)")
                                        }
                                    }
                                }
                            }).buttonStyle(BorderedProminentButtonStyle())
                            Button("wizard.neo.index", action: { viewModel.showFirstDialog = true })
                        }
                    }.padding()
                }.padding(.bottom, 4)
                CardView {
                    VStack(alignment: .leading) {
                        HStack(spacing: 16) {
                            Image(systemName: "arrow.down.app").font(.title2)
                            Text("wizard.images.title").font(.title2)
                            Spacer()
                        }.padding(.bottom, 4)
                        Text("wizard.images.p1").font(.callout)
                        List {
                            ForEach(viewModel.imagesDownloadList, id: \.self){ single in
                                HStack {
                                    Label(single, systemImage: "doc.zipper")
                                    Spacer()
                                    Button(action: {
                                        viewModel.downloadState = 0
                                        viewModel.startDownload(url: "https://static-zip.snapgenshin.cn/\(single).zip")
                                    }, label: { Image(systemName: "square.and.arrow.down") })
                                }.padding(2)
                            }
                        }.frame(minHeight: 120, maxHeight: 135)
                    }.padding()
                }
                HStack {
                    Spacer()
                    Button("wizard.data.next", action: { goNext() })
                        .buttonStyle(BorderedProminentButtonStyle())
                }.padding()
            } else {
                CardView {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.tint).font(.title2)
                        Text("wizard.data.not_agree")
                        Button("wizard.neo.refresh_license", action: {
                            agreed = UserDefaultHelper.shared.getValue(forKey: "license_agree", def: "no") == "yes"
                        }).buttonStyle(BorderedProminentButtonStyle())
                    }.padding()
                }.frame(minWidth: 500)
            }
        }
        .frame(maxWidth: 600)
        .toast(isPresenting: $viewModel.showErr, alert: { AlertToast(type: .error(.red), title: viewModel.errMsg) })
        .toast(isPresenting: $downloadStatic, alert: { AlertToast(type: .loading, title: "正在下载第\(viewModel.metaCount)个文件，总共\(viewModel.metaList.count)个文件。")})
        .toast(isPresenting: $operationFinished, alert: { AlertToast(type: .complete(.green), title: NSLocalizedString("wizard.neo.op_ok", comment: ""))})
        .toast(isPresenting: $viewModel.downloadFinished, alert: { AlertToast(type: .complete(.green), title: "下载完成。") })
        .alert(
            "app.notice", isPresented: $viewModel.showFirstDialog,
            actions: {
                Button("app.confirm", action: {
                    do {
                        try viewModel.indexAvatars()
                        UserDefaultHelper.shared.setValue(forKey: "dataSource", value: "local-cloud")
                        operationFinished = true
                    } catch {
                        viewModel.showErrMsg(msg: error.localizedDescription)
                    }
                })
                Button("app.cancel", action: { viewModel.showFirstDialog = false })
            },
            message: { Text("wizard.neo.get_meta") })
        .sheet(isPresented: $viewModel.showDownloadSheet, content: {
            NavigationStack {
                Text("wizard.images.go")
                    .font(.title).bold()
                    .padding(.bottom, 8)
                Text("wizard.neo.sheet_p1")
                ProgressView(value: viewModel.downloadState, total: 1.0)
            }
            .padding()
            .frame(maxWidth: 300)
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("app.cancel", action: { viewModel.cancelDownload() })
                })
            }
        })
    }
}
