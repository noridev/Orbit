//
//  UserDetailMenuView.swift
//  Orbit
//
//  Created by makinosp on 2024/10/13.
//

import AsyncSwiftUI
import VRCKit

struct UserDetailToolbarMenu: View {
    @Environment(AppViewModel.self) var appVM
    @Environment(FavoriteViewModel.self) var favoriteVM
    @Environment(FriendViewModel.self) var friendVM
    @Environment(\.dismiss) private var dismiss
    @State private var isRequesting = false
    @State private var isPresentedAlert = false
    @State private var isPresentedSettings = false
    @State private var isPresentedForm = false
    @State private var isPresentedBrowser = false
    let user: UserDetail

    var body: some View {
        HStack {
            if let isMe = appVM.user, user.id == isMe.id {
                presentSettingsButton
            }

            Menu {
                if user.isFriend {
                    favoriteMenu
                }
                if let url = user.url {
                    ShareLink(item: url)
                }
                if user.isFriend {
                    presentUnfriendAlertButton
                }
                if let isMe = appVM.user, user.id == isMe.id {
                    presentEditProfileButton
                    presentAccountSettingsButton
                }
            } label: {
                if isRequesting {
                    ProgressView()
                } else {
                    IconSet.dots.icon
                }
            }
            .alert("Unfriend", isPresented: $isPresentedAlert) {
                unfriendTaskButton
            } message: {
                Text("Are you sure you want to unfriend?")
            }
            .sheet(isPresented: $isPresentedSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isPresentedForm) {
                if let user = appVM.user {
                    ProfileEditView(user: user)
                }
            }
            .sheet(isPresented: $isPresentedBrowser) {
                if let url = URL(string: "https://vrchat.com/home/profile") {
                    SafariView(url: url)
                }
            }
        }
    }

    private var presentUnfriendAlertButton: Button<some View> {
        Button("Unfriend", systemImage: IconSet.unfriend.systemName, role: .destructive) {
            isPresentedAlert.toggle()
        }
    }

    private var unfriendTaskButton: Button<some View> {
        Button("Unfriend", role: .destructive) {
            Task {
                do {
                    try await appVM.services.friendService.unfriend(id: user.id)
                } catch {
                    appVM.handleError(error)
                }
                await friendVM.fetchAllFriends { error in
                    appVM.handleError(error)
                }
                dismiss()
            }
        }
    }

    private var favoriteMenu: some View {
        Menu {
            ForEach(favoriteVM.favoriteGroups(.friend)) { group in
                favoriteMenuItem(group: group)
            }
        } label: {
            Label {
                Text("Favorite")
            } icon: {
                if favoriteVM.isAdded(friendId: user.id) {
                    IconSet.favoriteFilled.icon
                } else {
                    IconSet.favorite.icon
                }
            }
        }
    }

    private func favoriteMenuItem(group: FavoriteGroup) -> some View {
        AsyncButton {
            await updateFavoriteAction(friendId: user.id, group: group)
        } label: {
            Label {
                Text(group.displayName)
            } icon: {
                if favoriteVM.isInFavoriteGroup(
                    friendId: user.id,
                    groupId: group.id
                ) {
                    IconSet.check.icon
                }
            }
        }
    }

    private func updateFavoriteAction(friendId: String, group: FavoriteGroup) async {
        guard let friend = friendVM.getFriend(id: friendId) else { return }
        defer { isRequesting = false }
        isRequesting = true
        do {
            try await favoriteVM.updateFavorite(
                service: appVM.services.favoriteService,
                friend: friend,
                targetGroup: group
            )
        } catch {
            appVM.handleError(error)
        }
    }
    
    private var presentSettingsButton: Button<some View> {
        Button { isPresentedForm.toggle() } label: { IconSet.edit.icon }
    }
    
    private var presentEditProfileButton: Button<some View> {
        Button("Edit", systemImage: IconSet.edit.systemName, action: {
            isPresentedForm.toggle()
        })
    }

    private var presentAccountSettingsButton: Button<some View> {
        Button("Account Settings", systemImage: IconSet.account.systemName, action: {
            isPresentedBrowser.toggle()
        })
    }
}
