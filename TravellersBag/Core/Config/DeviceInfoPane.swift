//
//  DeviceInfoPane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/15.
//

import SwiftUI

struct DeviceInfoPane: View {
    @StateObject private var model = DeviceInfoModel()
    let dismissIt: () -> Void
    
    var body: some View {
        NavigationStack {
            Text("device.title").font(.title).bold()
            Form {
                HStack {
                    Text("device.show.id")
                    Spacer()
                    Text(model.deviceID).foregroundStyle(.secondary).font(.callout)
                }
                HStack {
                    Text("device.show.bbs_device_id")
                    Spacer()
                    Text(model.bbsDeviceID).foregroundStyle(.secondary).font(.callout)
                }
                HStack {
                    Text("device.show.name")
                    Spacer()
                    Text("device.show.name_p").foregroundStyle(.secondary).font(.callout)
                }
                HStack {
                    Text("device.show_miyoushe")
                    Spacer()
                    Text("device.show_miyoushe_p").foregroundStyle(.secondary).font(.callout)
                }
                VStack {
                    HStack {
                        Text("device.show.fp")
                        Spacer()
                        Text(model.deviceFP).foregroundStyle(.secondary).font(.callout)
                    }
                    if !model.deviceFP.starts(with: "38") {
                        HStack {
                            Spacer()
                            Text("device.show.fp_not_official").foregroundStyle(.red).font(.footnote)
                        }
                    }
                    HStack {
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString("device.show.fp_last_update", comment: ""),
                                model.lastUpdateTime
                            )
                        ).font(.callout)
                        Spacer()
                        Button("device.show.fp_update", action: {
                            Task { await model.updateFp() }
                        })
                    }
                }
            }.formStyle(.grouped)
            Text("device.show.p").font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button("app.confirm", action: dismissIt)
            })
        }
    }
    
    class DeviceInfoModel: ObservableObject {
        @Published var deviceID = UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_ID, def: "")
        @Published var bbsDeviceID = UserDefaultHelper.shared.getValue(forKey: TBEnv.BBS_DEVICE_ID, def: "")
        @Published var deviceFP = UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_FP, def: "")
        @Published var lastUpdateTime = ""
        
        init() {
            lastUpdateTime = timeTransfer(time: UserDefaultHelper.shared.getValue(forKey: "lastTimeOfFpFetch", def: "0"))
        }
        
        func timeTransfer(time: String) -> String {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            return df.string(from: Date(timeIntervalSince1970: TimeInterval(Int64(time)!)))
        }
        
        func updateFp() async {
            await TBEnv.default.updateDeviceFp()
            let currentTime = Int64(Date().timeIntervalSince1970)
            UserDefaultHelper.shared.setValue(forKey: "lastTimeOfFpFetch", value: "\(currentTime)")
            DispatchQueue.main.async { [self] in
                deviceFP = UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_FP, def: "")
                lastUpdateTime = timeTransfer(time: UserDefaultHelper.shared.getValue(forKey: "lastTimeOfFpFetch", def: "0"))
            }
        }
    }
}
