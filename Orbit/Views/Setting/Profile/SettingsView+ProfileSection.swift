//
//  SettingsView+ProfileSection.swift
//  Orbit
//
//  Created by makinosp on 2024/08/20.
//

import SwiftUI
import VRCKit

extension SettingsView {
    func profileSection(user: User) -> some View {
        Section(header: Text("Profile")) {
            NavigationLabel {
                Label {
                    Text(user.displayName)
                        .padding(.leading, 4)
                } icon: {
                    UserIcon(user: user, size: Constants.IconSize.ll)
                }
                .padding(.vertical, 8)
            }
            .tag(SettingsDestination.userDetail)
            .padding(8)

            Button("Edit", systemImage: IconSet.edit.systemName) {
                isPresentedForm.toggle()
            }
            if let url = URL(string: "https://vrchat.com/home/profile") {
                ExternalLink(
                    title: String(localized: "Account Settings"),
                    url: url,
                    systemImage: IconSet.account.systemName
                )
            }
        }
        .textCase(nil)
    }
}
