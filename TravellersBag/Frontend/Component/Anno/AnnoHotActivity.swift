//
//  AnnoHotActivity.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/27.
//

import SwiftUI
import Kingfisher

struct AnnoHotActivity: View {
    @StateObject private var vm = HotActivityHelper()
    
    @ViewBuilder
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if !vm.activities.isEmpty {
                LazyHStack(spacing: 8) {
                    let start = Date.now
                    ForEach(vm.activities, id: \.abstract) { activity in
                        VStack(alignment: .leading) {
                            HStack(spacing: 8) {
                                KFImage.url(URL(string: activity.icon))
                                    .loadDiskFileSynchronously(true)
                                    .resizable()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .frame(width: 32, height: 32)
                                VStack(alignment: .leading, content: {
                                    Text(activity.title).bold()
                                    Text(activity.abstract).font(.footnote).foregroundStyle(.secondary)
                                })
                                Spacer()
                                Button("anno.action.visit", action: {
                                    NSWorkspace.shared.open(URL(string: activity.url) ?? URL(string: "https://miyoushe.com")!)
                                }).buttonStyle(BorderedProminentButtonStyle())
                            }
                            Label(
                                String.localizedStringWithFormat(
                                    NSLocalizedString("anno.label.date", comment: ""),
                                    activity.createTime,
                                    vm.timestamp2string(time: Int(activity.endTime)!)
                                ),
                                systemImage: "calendar"
                            )
                            .font(.callout)
                            .padding(.bottom, 2)
                            if activity.endTime != "0" {
                                let end = vm.timestamp2string(time: Int(activity.endTime)!).dateFromFormattedString()
                                let gap = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: start, to: end)
                                HStack {
                                    Spacer()
                                    Label(
                                        String.localizedStringWithFormat(
                                            NSLocalizedString("anno.label.timer", comment: ""),
                                            String(gap.hour ?? 0), String(gap.minute ?? 0)
                                        ),
                                        systemImage: "timer"
                                    ).font(.callout)
                                }
                            } else {
                                HStack {
                                    Spacer()
                                    Label("anno.label.unknown", systemImage: "timer").font(.callout)
                                }
                            }
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.background)
                        )
                    }
                }
            }
        }
        .onAppear {
            Task.detached {
                await vm.loadFileAndParse()
            }
        }
    }
}

fileprivate class HotActivityHelper: AutocheckedKey, ObservableObject, @unchecked Sendable {
    private let hotDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(path: "Anno")
    private let hotFile: URL
    @Published var activities: [AnnoHotActStruct.ActivityList.ChildElement.PurpleList] = []
    
    init() {
        self.hotFile = hotDir.appending(components: "HotActivity.json")
        super.init(configKey: "hotActivityLastCheck")
        if !FileManager.default.fileExists(atPath: hotDir.path(percentEncoded: false)) {
            try! FileManager.default.createDirectory(at: hotDir, withIntermediateDirectories: true)
        }
        if !FileManager.default.fileExists(atPath: self.hotFile.path(percentEncoded: false)) {
            FileManager.default.createFile(atPath: self.hotFile.path(percentEncoded: false), contents: nil)
        }
    }
    
    func loadFileAndParse() async {
        func loadFromNetwork() async throws {
            let fileRequest = RequestBuilder.buildRequest(
                method: .GET, host: Endpoints.ActApiTakumi, path: "/common/blackboard/ys_obc/v1/home/position",
                queryItems: [.init(name: "app_sn", value: "ys_obc")]
            )
            let result = try await NetworkClient.simpleDataClient(request: fileRequest, type: AnnoHotActStruct.self)
            try JSONEncoder().encode(result).write(to: hotFile)
            await parseValue(localData: result)
            storeFetch(date: Date.now)
        }
        
        func parseValue(localData: AnnoHotActStruct) async {
            if let hotspot = localData.data.list.filter({ $0.name == "热点追踪" }).first {
                if let requiredList = hotspot.children.first {
                    if let innerList = requiredList.children.filter({ $0.name == "近期活动" }).first {
                        for single in innerList.list {
                            await MainActor.run {
                                activities.append(single)
                            }
                        }
                    }
                }
            }
        }
        
        do {
            if let localData = try? JSONDecoder().decode(AnnoHotActStruct.self, from: Data(contentsOf: hotFile)) {
                await parseValue(localData: localData)
            } else {
                try await loadFromNetwork()
            }
        } catch {
            print("Failed to fetch hot activity, because: \(error)")
        }
    }
    
    func timestamp2string(time: Int) -> String {
        if time == 0 {
            return NSLocalizedString("anno.label.unknown", comment: "")
        }
        let confirmedTime = convert13DigitsTo10(String(time))
        return confirmedTime.formatTimestamp()
    }
    
    private func convert13DigitsTo10(_ input: String) -> Int {
        if input.count > 10 {
            let startIndex = input.startIndex
            let endIndex = input.index(startIndex, offsetBy: 10)
            let tenDigitString = String(input[startIndex..<endIndex])
            return Int(tenDigitString)!
        } else if input.count == 10 {
            return Int(input)!
        } else {
            return 0
        }
    }
}
