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
    @State var destination: Destination?

    enum Destination: Hashable {
        case userDetail, license
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            VStack {
                settingsContent
                HStack {
                    Text(appName)
                    Text(appVersion)
                }
                .font(.footnote)
            }
            .navigationDestination(item: $destination) { destination in
                presentDestination(destination)
            }
            .navigationTitle("Settings")
        }
        .navigationSplitViewStyle(.balanced)
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
                profileSection(user: user)
            }
            Section(header: Text("Open Source License Notice")) {
                Link(destination: URL(string: "https://github.com/makinosp/harmonie")!) {
                    Label {
                        Text("Source Code")
                    } icon: {
                        Image(systemName: "curlybraces.square.fill")
                    }
                }
                Button {
                    destination = .license
                } label: {
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
    
    func profileSection(user: User) -> some View {
        Section(header: Text("My Profile")) {
            Button {
                destination = .userDetail
            } label: {
                HStack(alignment: .center) {
                    Label {
                        Text(user.displayName)
                    } icon: {
                        CircleURLImage(
                            imageUrl: user.thumbnailUrl,
                            size: Constants.IconSize.ll
                        )
                    }
                    Spacer()
                    Constants.Icon.forward
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            Button {} label: {
                HStack(alignment: .center) {
                    Label {
                        Text("Status")
                    } icon: {
                        Image(systemName: Constants.IconName.circleFilled)
                            .foregroundStyle(user.status.color)
                    }
                    Spacer()
                    Text(user.status.description)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .font(.callout)
                    Constants.Icon.forward
                }
            }
            Button {} label: {
                HStack(alignment: .center) {
                    Label("Description", systemImage: "quote.bubble")
                    Spacer()
                    Text(user.statusDescription)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .font(.callout)
                    Constants.Icon.forward
                }
            }
        }
        .textCase(nil)
    }

    var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    }

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
