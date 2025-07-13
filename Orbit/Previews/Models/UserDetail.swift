//
//  UserDetail.swift
//  Orbit
//
//  Created by makinosp on 2024/10/21.
//

import Foundation
import VRCKit

extension PreviewData {
    static func userDetail(id: UUID, instance: Instance) -> UserDetail {
        UserDetail(id: id, location: .id(instance.id), state: .active, status: .active, isFriend: false)
    }

    static func userDetail(
        id: UUID,
        profile: Profile? = nil,
        location: Location,
        state: User.State,
        status: UserStatus,
        isFriend: Bool = true
    ) -> UserDetail {
        UserDetail(
            id: id,
            profile: profile,
            location: location,
            state: state,
            status: status,
            isFriend: isFriend
        )
    }
}

private extension UserDetail {
    init(
        id: UUID = UUID(),
        profile: PreviewData.Profile? = PreviewData.Profile.random,
        bio: String = "Demo",
        location: Location,
        state: User.State,
        status: UserStatus,
        statusDescription: String = "Demo",
        isFriend: Bool = true,
        dateJoined: Date = Date(),
        lastActivity: Date = Date()
    ) {
        self.init(
            ageVerificationStatus: .hidden,
            ageVerified: false,
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
            bio: bio,
            bioLinks: SafeDecodingArray(),
            avatarImageUrl: profile?.imageUrl(),
            avatarThumbnailUrl: profile?.imageUrl(),
            displayName: profile?.name ?? "",
            id: "usr_\(id.uuidString)",
            isFriend: isFriend,
            lastLogin: Date(),
            lastPlatform: "standalonewindows",
            profilePicOverride: profile?.imageUrl(),
            pronouns: "they/them",
            state: state,
            status: status,
            statusDescription: statusDescription,
            tags: UserTags(),
            userIcon: profile?.imageUrl(),
            location: location,
            friendKey: "",
            dateJoined: dateJoined,
            note: "",
            lastActivity: lastActivity,
            platform: .blank
        )
    }
}
