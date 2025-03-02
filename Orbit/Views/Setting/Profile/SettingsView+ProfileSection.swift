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
                .padding(.vertical, 4)
            }
            .tag(SettingsDestination.userDetail)
            .padding(8)

            Button("Edit", systemImage: IconSet.edit.systemName) {
                isPresentedForm.toggle()
            }
            
            Button("Account Settings", systemImage: IconSet.account.systemName) {
                isPresentedBrowser.toggle()
            }
        }
        .textCase(nil)
    }
}
