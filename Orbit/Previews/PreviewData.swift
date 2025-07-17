//
//  PreviewDataProvider.swift
//  VRCKit
//
//  Created by makinosp on 2024/07/13.
//

import Foundation
import VRCKit

final class PreviewData: Sendable {
    static let shared = PreviewData()
    private let previewUserId = UUID()
    let friends: [Friend]
    let userDetails: [UserDetail]
    
    static let sampleGroup = VRCGroup(
        id: "gmem_sample_member_id",
        groupId: "grp_sample_group_id",
        name: "Sample Group",
        shortCode: "SAMPLE",
        discriminator: "1234",
        description: "This is a sample group for preview purposes. It contains various information about the group including member count, privacy settings, and other details.",
        bannerId: "file_sample_banner",
        bannerUrl: URL(string: "https://api.vrchat.cloud/api/1/file/file_sample_banner/1/file"),
        iconId: "file_sample_icon",
        iconUrl: URL(string: "https://api.vrchat.cloud/api/1/file/file_sample_icon/1/file"),
        ownerId: "usr_sample_owner",
        privacy: .default,
        memberCount: 12345,
        memberVisibility: .visible,
        mutualGroup: true,
        isRepresenting: false,
        lastPostCreatedAt: Date(),
        lastPostReadAt: nil,
        rules: nil,
        isVerified: true,
        joinState: .open,
        tags: ["sample", "preview"],
        languages: ["korean", "english"],
        galleries: nil,
        createdAt: Date(),
        updatedAt: Date(),
        memberships: nil,
        roles: nil,
        representable: true,
        myMember: GroupMembership(
            id: "mem_sample",
            groupId: "grp_sample_group_id",
            userId: "usr_sample_user",
            isRepresenting: false,
            isSubscribedToAnnouncements: true,
            visibility: .visible,
            isSubscribedToEvents: true,
            roleIds: ["role_member"],
            joinedAt: Date().addingTimeInterval(-86400 * 30),
            rolePermissions: nil,
            roleOrder: nil
        )
    )

    static let imageBaseURL = "https://images2.imgbox.com"
    static let iconImageUrl = URL(string: "\(imageBaseURL)/44/8f/IQToHkKa_o.jpg")

    private init() {
        let onlineFriendsSet: [FriendSet] = [
            (0..<10).map { _ in FriendSet(world: Self.bar, status: .joinMe) },
            (0..<5).map { _ in FriendSet(world: Self.chillRoom, status: .active) },
            (0..<3).map { _ in FriendSet(world: Self.fuji, status: .joinMe) },
            (0..<2).map { _ in FriendSet(world: Self.chinatown, status: .active) },
            [FriendSet(world: Self.nightCity, status: .joinMe)],
            (0..<25).map { _ in FriendSet(location: .private, status: .busy) }
        ].flatMap { $0 }

        var userDetails = onlineFriendsSet.map(\.userDetail)
        userDetails.append(PreviewData.userDetail(id: previewUserId, instance: Self.instance))

        self.userDetails = userDetails
        self.friends = onlineFriendsSet.map(\.friend)
    }

    var previewUser: User {
        User(
            activeFriends: [],
            ageVerificationStatus: .hidden,
            ageVerified: false,
            allowAvatarCopying: false,
            badges: [
                Badge(
                    assignedAt: Date(),
                    badgeDescription: "Awarded for gifting VRC+ (1 Month)",
                    badgeId: "bdg_123",
                    badgeImageUrl: URL(string: "https://assets.vrchat.com/badges/29/bdgai_7530140f-1374-472b-9540-5cfbcd592c9.png"),
                    badgeName: "Gift (1 Month)",
                    hidden: false,
                    showcased: true,
                    updatedAt: Date()
                ),
                Badge(
                    assignedAt: nil,
                    badgeDescription: "Awarded for subscribing to VRC+ (3 Years)",
                    badgeId: "bdg_456",
                    badgeImageUrl: URL(string: "https://assets.vrchat.com/badges/79/bdgai_b49bdd6d-0f98-4d10-a01c-c3c0a0809dd.png"),
                    badgeName: "VRC+ Subscriber (3 Years)",
                    hidden: false,
                    showcased: false,
                    updatedAt: Date()
                )
            ],
            bio: "This is the demo user.",
            bioLinks: SafeDecodingArray(),
            currentAvatar: "",
            avatarImageUrl: PreviewData.iconImageUrl,
            avatarThumbnailUrl: PreviewData.iconImageUrl,
            dateJoined: Date(),
            displayName: "Demo User",
            friendKey: "",
            friends: friends.map(\.id),
            homeLocation: "",
            id: "usr_\(previewUserId.uuidString)",
            isFriend: false,
            lastActivity: Date(),
            lastLogin: Date(),
            lastPlatform: "standalonewindows",
            offlineFriends: offlineFriends.map(\.id),
            onlineFriends: onlineFriends.map(\.id),
            pastDisplayNames: [],
            profilePicOverride: PreviewData.iconImageUrl,
            pronouns: "he/him",
            state: .active,
            status: .active,
            statusDescription: "status",
            tags: UserTags(),
            twoFactorAuthEnabled: true,
            userIcon: PreviewData.iconImageUrl,
            userLanguage: nil,
            userLanguageCode: nil,
            presence: Presence(),
            platform: .standalonewindows
        )
    }
}

private extension Presence {
    init() {
        self.init(
            groups: [],
            id: UUID().uuidString,
            instance: "",
            instanceType: "",
            platform: .android,
            status: .active,
            travelingToInstance: "",
            travelingToWorld: "",
            world: ""
        )
    }
}
