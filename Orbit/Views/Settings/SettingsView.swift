//
//  SettingsView.swift
//  Orbit
//
//  Created by makinosp on 2024/03/10.
//

import LicenseList
import SwiftUI
import VRCKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) var appVM
    @State var destination: SettingsDestination? = UIDevice.current.userInterfaceIdiom == .pad ? .favoriteGroups : nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedLibrary: Library?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            settingsContent
                .navigationTitle("Settings")
                .toolbar(removing: .sidebarToggle)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: {
                            dismiss()
                        })
                    }
                }
        } detail: {
            if let destination = destination {
                presentDestination(destination)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color(UIColor { $0.userInterfaceStyle == .dark ? .white : .black }))
        .sheet(item: $selectedLibrary) { library in
            NavigationStack {
                LicenseView(library: library)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                selectedLibrary = nil
                            }
                        }
                    }
                    .navigationTitle(library.name)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    @ViewBuilder
    private func presentDestination(_ destination: SettingsDestination) -> some View {
        switch destination {
        case .favoriteGroups:
            FavoriteGroupsListView()
        case .about:
            aboutThisApp
        case .license:
            List(Library.libraries) { library in
                Button {
                    selectedLibrary = library
                } label: {
                    Text(library.name)
                }
            }
            .navigationTitle("Third Party Licence")
            .navigationBarTitleDisplayMode(.inline)
        case .rawHistoryData:
            NavigationStack {
                RawHistoryDataView()
            }
        }
    }

    private var settingsContent: some View {
        List(selection: $destination) {
            AboutSection()
            Section("Debug") {
                Label("Raw History Data", systemImage: "doc.text.magnifyingglass")
                    .tag(SettingsDestination.rawHistoryData)
            }
            Section {
                LogoutButton()
            }
        }
    }

    private var aboutThisApp: some View {
        List {
            LabeledContent {
                Text(BundleUtil.appName)
            } label: {
                Text("App Name")
            }
            LabeledContent {
                Text(BundleUtil.appVersion)
            } label: {
                Text("Version")
            }
            LabeledContent {
                Text(BundleUtil.appBuild)
            } label: {
                Text("Build")
            }
        }
        .navigationTitle("About This App")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PreviewContainer {
        SettingsView()
    }
}
