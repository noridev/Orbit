//
//  BadgeListView.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import SwiftUI
import VRCKit

struct BadgeListView: View {
    @State private var selectedBadge: Badge?
    let badges: [Badge]
    let isMe: Bool
    
    var body: some View {
        if badges.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: IconSet.medal.systemName)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("No badges yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        else {
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(badges) { badge in
                        Button {
                            selectedBadge = badge
                        } label: {
                            VStack(spacing: 4) {
                                AsyncImage(url: badge.badgeImageUrl) { image in
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 48, height: 48)
                                
                                /*
                                Text(badge.badgeName)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                                 */
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(badge.badgeName) badge")
                        .accessibilityHint("Tap to view badge details")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .popover(item: $selectedBadge) { badge in
                BadgePopoverView(badge: badge, isMe: isMe)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

struct BadgePopoverView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    @State private var isShowcased: Bool
    @State private var isHidden: Bool
    @State private var isUpdating = false
    let badge: Badge
    let isMe: Bool
    
    init(badge: Badge, isMe: Bool) {
        self.badge = badge
        self.isMe = isMe
        self._isShowcased = State(initialValue: badge.showcased)
        self._isHidden = State(initialValue: badge.hidden ?? false)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                AsyncImage(url: badge.badgeImageUrl) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: IconSet.medal.systemName)
                        .font(.title)
                        .foregroundStyle(.secondary)
                        .frame(width: 64, height: 64)
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                
                VStack(spacing: 4) {
                    Text(badge.badgeName)
                        .font(.headline)
                    
                    Text(badge.badgeDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        if badge.showcased {
                            Label("Showcased", systemImage: IconSet.favoriteFilled.systemName)
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                        
                        if badge.hidden == true {
                            Label("Hidden", systemImage: IconSet.hidden.systemName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if isMe {
                    VStack(spacing: 8) {
                        if let assignedAt = badge.assignedAt {
                            VStack(spacing: 2) {
                                Text("Assigned")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Text(assignedAt, formatter: dateFormatter)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        if let updatedAt = badge.updatedAt {
                            VStack(spacing: 2) {
                                Text("Last Updated")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Text(updatedAt, formatter: dateFormatter)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                
                if isMe {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Badge Settings")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Label("Showcased", systemImage: IconSet.favoriteFilled.systemName)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                if isUpdating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                
                                Toggle("", isOn: $isShowcased)
                                    .labelsHidden()
                                    .disabled(isUpdating)
                                    .onChange(of: isShowcased) { _, newValue in
                                        Task {
                                            await updateBadgeShowcased(newValue)
                                        }
                                    }
                            }
                            
                            HStack {
                                Label("Hidden", systemImage: IconSet.hidden.systemName)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                if isUpdating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                
                                Toggle("", isOn: $isHidden)
                                    .labelsHidden()
                                    .disabled(isUpdating)
                                    .onChange(of: isHidden) { _, newValue in
                                        Task {
                                            await updateBadgeHidden(newValue)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
            .navigationTitle(badge.badgeName)
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Badge details for \(badge.badgeName)")
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }
    
    private func updateBadgeShowcased(_ showcased: Bool) async {
        guard isMe else { return }
        
        isUpdating = true
        defer { isUpdating = false }
        
        do {
            guard let currentUser = appVM.user else {
                throw ApplicationError(text: "User not found")
            }
            
            let request = BadgeUpdateRequest(showcased: showcased)
            let partialUpdate = try await appVM.services.userService.updateBadge(
                currentUserId: currentUser.id,
                badgeId: badge.badgeId,
                request: request
            )
            
            print("✅ [updateBadgeShowcased] Badge showcased updated to: \(showcased)")
            print("✅ [updateBadgeShowcased] Partial update received: showcased=\(partialUpdate.showcased?.description ?? "nil"), hidden=\(partialUpdate.hidden?.description ?? "nil")")
            
            // Refresh user data to get updated badge information
            await refreshUserData()
            
        } catch {
            print("❌ [updateBadgeShowcased] Error updating badge showcased: \(error)")
            appVM.handleError(error)
            
            // Revert the toggle if update failed
            isShowcased = badge.showcased
        }
    }
    
    private func updateBadgeHidden(_ hidden: Bool) async {
        guard isMe else { return }
        
        isUpdating = true
        defer { isUpdating = false }
        
        do {
            guard let currentUser = appVM.user else {
                throw ApplicationError(text: "User not found")
            }
            
            let request = BadgeUpdateRequest(hidden: hidden)
            let partialUpdate = try await appVM.services.userService.updateBadge(
                currentUserId: currentUser.id,
                badgeId: badge.badgeId,
                request: request
            )
            
            print("✅ [updateBadgeHidden] Badge hidden updated to: \(hidden)")
            print("✅ [updateBadgeHidden] Partial update received: showcased=\(partialUpdate.showcased?.description ?? "nil"), hidden=\(partialUpdate.hidden?.description ?? "nil")")
            
            // Refresh user data to get updated badge information
            await refreshUserData()
            
        } catch {
            print("❌ [updateBadgeHidden] Error updating badge hidden: \(error)")
            appVM.handleError(error)
            
            // Revert the toggle if update failed
            isHidden = badge.hidden ?? false
        }
    }
    
    private func refreshUserData() async {
        guard let currentUser = appVM.user else { return }
        
        do {
            let updatedUserDetail = try await appVM.services.userService.fetchUser(userId: currentUser.id)
            
            // Update the current user with new badge information
            let updatedUser = User(
                activeFriends: currentUser.activeFriends,
                ageVerificationStatus: updatedUserDetail.ageVerificationStatus,
                ageVerified: updatedUserDetail.ageVerified,
                allowAvatarCopying: currentUser.allowAvatarCopying,
                badges: updatedUserDetail.badges,
                bio: updatedUserDetail.bio,
                bioLinks: updatedUserDetail.bioLinks,
                currentAvatar: currentUser.currentAvatar,
                avatarImageUrl: updatedUserDetail.avatarImageUrl,
                avatarThumbnailUrl: updatedUserDetail.avatarThumbnailUrl,
                dateJoined: updatedUserDetail.dateJoined,
                displayName: updatedUserDetail.displayName,
                friendKey: updatedUserDetail.friendKey,
                friends: currentUser.friends,
                homeLocation: currentUser.homeLocation,
                id: updatedUserDetail.id,
                isFriend: updatedUserDetail.isFriend,
                lastActivity: updatedUserDetail.lastActivity,
                lastLogin: updatedUserDetail.lastLogin,
                lastPlatform: updatedUserDetail.lastPlatform,
                offlineFriends: currentUser.offlineFriends,
                onlineFriends: currentUser.onlineFriends,
                pastDisplayNames: currentUser.pastDisplayNames,
                profilePicOverride: updatedUserDetail.profilePicOverride,
                pronouns: updatedUserDetail.pronouns,
                state: updatedUserDetail.state,
                status: updatedUserDetail.status,
                statusDescription: updatedUserDetail.statusDescription,
                tags: updatedUserDetail.tags,
                twoFactorAuthEnabled: currentUser.twoFactorAuthEnabled,
                userIcon: updatedUserDetail.userIcon,
                userLanguage: currentUser.userLanguage,
                userLanguageCode: currentUser.userLanguageCode,
                presence: currentUser.presence,
                platform: updatedUserDetail.platform
            )
            
            appVM.user = updatedUser
            print("✅ [refreshUserData] User data refreshed with updated badges")
            
        } catch {
            print("❌ [refreshUserData] Error refreshing user data: \(error)")
            appVM.handleError(error)
        }
    }
}
