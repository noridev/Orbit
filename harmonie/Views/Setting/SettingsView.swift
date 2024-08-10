//
//  SettingsView.swift
//  Harmonie
//
//  Created by makinosp on 2024/03/10.
//

import AsyncSwiftUI
import LicenseList
import VRCKit

struct SettingsView: View {
    @EnvironmentObject var appVM: AppViewModel

    enum Destination: Identifiable {
        case userDetail, license
        var id: Int { hashValue }
    }

    var body: some View {
        NavigationSplitView {
            VStack {
                settingsContent
                HStack {
                    Text(appName)
                    Text(appVersion)
                }
                .font(.footnote)
            }
            .navigationDestination(for: Destination.self) { destination in
                presentDestination(destination)
            }
            .navigationTitle("Settings")
        } detail: {
            presentDestination(.userDetail)
        }
    }

    @ViewBuilder
    func presentDestination(_ destination: Destination) -> some View {
        switch destination {
        case .userDetail:
            if let user = appVM.user {
                UserDetailPresentationView(id: user.id)
            }
        case .license:
            LicenseListView()
        }
    }

    var settingsContent: some View {
        List {
            if let user = appVM.user {
                Section(header: Text("My Profile")) {
                    NavigationLink(value: Destination.userDetail) {
                        HStack {
                            CircleURLImage(
                                imageUrl: user.userIconUrl,
                                size: Constants.IconSize.ll
                            )
                            Text(user.displayName)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                }
                .textCase(nil)
            }
            Section(header: Text("Open Source License Notice")) {
                Link(destination: URL(string: "https://github.com/makinosp/harmonie")!) {
                    Label {
                        Text("Source Code")
                    } icon: {
                        Image(systemName: "curlybraces.square.fill")
                    }
                }
                NavigationLink(value: Destination.license) {
                    Label {
                        Text("Third Party Licence")
                    } icon: {
                        Image(systemName: "info.circle.fill")
                    }
                }
            }
            .textCase(nil)
            Section {
                AsyncButton {
                    await appVM.logout()
                } label: {
                    Label {
                        Text("Logout")
                            .foregroundStyle(Color.red)
                    } icon: {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                            .foregroundStyle(Color.red)
                    }
                }
            }
        }
    }

    var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    }

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
