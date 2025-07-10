//
//  UserDetailMenuView.swift
//  Orbit
//
//  Created by makinosp on 2024/10/13.
//

import AsyncSwiftUI
import SwiftUI
import VRCKit

struct UserDetailToolbarMenu: ToolbarContent {
    @Environment(AppViewModel.self) var appVM
    @Environment(FavoriteViewModel.self) var favoriteVM
    @Environment(FriendViewModel.self) var friendVM
    @Binding var isRequesting: Bool
    @Binding var isPresentedAlert: Bool
    @Binding var isPresentedSettings: Bool
    @Binding var isPresentedForm: Bool
    @Binding var isPresentedBrowser: Bool
    @Binding var isPresentedJsonView: Bool
    let user: UserDetail

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if let isMe = appVM.user, user.id == isMe.id {
                presentSettingsButton
            }

            Menu {
                if user.isFriend { favoriteMenu }
                if let url = user.url { ShareLink(item: url) }
                if let isMe = appVM.user, user.id == isMe.id {
                    presentEditProfileButton
                    presentAccountSettingsButton
                }
                Divider()
                presentJsonViewButton
                if user.isFriend {
                    Divider()
                    presentUnfriendAlertButton
                }
            } label: {
                if isRequesting {
                    ProgressView()
                } else {
                    IconSet.dots.icon
                }
            }
        }
    }

    private var presentSettingsButton: some View {
        Button { isPresentedSettings.toggle() } label: { IconSet.setting.icon }
    }

    private var presentUnfriendAlertButton: some View {
        Button("Unfriend", systemImage: IconSet.unfriend.systemName, role: .destructive) {
            isPresentedAlert.toggle()
        }
        .tint(.red)
    }

    private var presentEditProfileButton: some View {
        Button("Edit", systemImage: IconSet.edit.systemName) {
            isPresentedForm.toggle()
        }
    }

    private var presentAccountSettingsButton: some View {
        Button("Account Settings", systemImage: IconSet.account.systemName) {
            isPresentedBrowser.toggle()
        }
    }
    
    private var favoriteMenu: some View {
        Menu {
            ForEach(favoriteVM.favoriteGroups(.friend)) { group in
                favoriteMenuItem(group: group)
            }
        } label: {
            Label { Text("Favorite") } icon: {
                Image(systemName: favoriteVM.isAdded(friendId: user.id) ? "star.fill" : "star")
            }
        }
    }

    private func favoriteMenuItem(group: FavoriteGroup) -> some View {
        AsyncButton {
            await updateFavoriteAction(friendId: user.id, group: group)
        } label: {
            Label { Text(group.displayName) } icon: {
                if favoriteVM.isInFavoriteGroup(friendId: user.id, groupId: group.id) {
                    IconSet.check.icon
                }
            }
        }
    }

    private func updateFavoriteAction(friendId: String, group: FavoriteGroup) async {
        guard let friend = friendVM.getFriend(id: friendId) else { return }
        isRequesting = true
        defer { isRequesting = false }
        do {
            try await favoriteVM.updateFavorite(
                service: appVM.services.favoriteService,
                friend: friend,
                targetGroup: group
            )
            friendVM.favoriteFriends = favoriteVM.favoriteFriends
        } catch {
            appVM.handleError(error)
        }
    }

    private var presentJsonViewButton: some View {
        Button("JSON Data", systemImage: "doc.text") {
            isPresentedJsonView.toggle()
        }
    }
}
