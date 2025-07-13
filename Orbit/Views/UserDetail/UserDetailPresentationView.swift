//
//  UserDetailPresentationView.swift
//  Orbit
//
//  Created by makinosp on 2024/07/28.
//

import SwiftUI
import VRCKit

struct UserDetailPresentationView: View {
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @State var userDetail: UserDetail?
    @State private var id: String

    init(id: String) {
        _id = State(initialValue: id)
    }

    init(selected: Selected) {
        _id = State(initialValue: selected.id)
    }

    var body: some View {
        Group {
            if let userDetail = userDetail {
                UserDetailView(user: userDetail)
                    .refreshable {
                        await fetchUser(id: id)
                    }
                    .id("\(userDetail.id)_\(userDetail.status.rawValue)_\(userDetail.statusDescription)_\(userDetail.bio ?? "")_\(userDetail.displayName)_\(userDetail.pronouns ?? "")_\(userDetail.badges.hashValue)")
            } else {
                ProgressScreen()
                    .task {
                        await fetchUser(id: id)
                    }
                    .navigationTitle("Loading...")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileUpdated)) { notification in
            if let updatedUser = notification.object as? User, updatedUser.id == id {
                print("🔔 [onReceive] Profile update notification received, refreshing user data")
                Task {
                    await fetchUser(id: id)
                }
            }
        }
    }

    private func fetchUser(id: String) async {
        do {
            userDetail = try await appVM.services.userService.fetchUser(userId: id)
            print("✅ [fetchUser] Successfully fetched user data for: \(userDetail?.displayName ?? id)")
            
            if let user = userDetail, let currentUser = appVM.user, currentUser.id == user.id {
                print("🔄 [fetchUser] This is current user, updating AppViewModel user")
                await updateAppVMUser(from: user)
            }
        } catch {
            print("❌ [fetchUser] Error fetching user: \(error)")
            appVM.handleError(error)
        }
    }
    
    private func updateAppVMUser(from userDetail: UserDetail) async {
        guard let currentUser = appVM.user else { return }
        
        let updatedUser = User(
            activeFriends: currentUser.activeFriends,
            ageVerificationStatus: userDetail.ageVerificationStatus,
            ageVerified: userDetail.ageVerified,
            allowAvatarCopying: currentUser.allowAvatarCopying,
            badges: userDetail.badges,
            bio: userDetail.bio,
            bioLinks: userDetail.bioLinks,
            currentAvatar: currentUser.currentAvatar,
            avatarImageUrl: userDetail.avatarImageUrl,
            avatarThumbnailUrl: userDetail.avatarThumbnailUrl,
            dateJoined: userDetail.dateJoined,
            displayName: userDetail.displayName,
            friendKey: userDetail.friendKey,
            friends: currentUser.friends,
            homeLocation: currentUser.homeLocation,
            id: userDetail.id,
            isFriend: userDetail.isFriend,
            lastActivity: userDetail.lastActivity,
            lastLogin: userDetail.lastLogin,
            lastPlatform: userDetail.lastPlatform,
            offlineFriends: currentUser.offlineFriends,
            onlineFriends: currentUser.onlineFriends,
            pastDisplayNames: currentUser.pastDisplayNames,
            profilePicOverride: userDetail.profilePicOverride,
            pronouns: userDetail.pronouns,
            state: userDetail.state,
            status: userDetail.status,
            statusDescription: userDetail.statusDescription,
            tags: userDetail.tags,
            twoFactorAuthEnabled: currentUser.twoFactorAuthEnabled,
            userIcon: userDetail.userIcon,
            userLanguage: currentUser.userLanguage,
            userLanguageCode: currentUser.userLanguageCode,
            presence: currentUser.presence,
            platform: userDetail.platform
        )
        
        appVM.user = updatedUser
        print("✅ [updateAppVMUser] AppViewModel user updated from server data")
    }
}
