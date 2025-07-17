//
//  GroupPreviewService.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import Foundation
import VRCKit

final actor GroupPreviewService: APIService, GroupServiceProtocol {
    public let client: APIClient
    
    init(client: APIClient) {
        self.client = client
    }
    
    public func fetchUserGroups(userId: String) async throws -> [VRCGroup] {
        return [
            VRCGroup(
                id: "gmem_1",
                groupId: "grp_1",
                name: "VRChat Korea",
                shortCode: "VRCK",
                discriminator: "0001",
                description: "한국 VRChat 커뮤니티",
                bannerId: nil,
                bannerUrl: nil,
                iconId: nil,
                iconUrl: nil,
                ownerId: "usr_owner",
                privacy: .public,
                memberCount: 1500,
                memberVisibility: .visible,
                mutualGroup: true,
                isRepresenting: false,
                lastPostCreatedAt: Date().addingTimeInterval(-86400 * 7),
                lastPostReadAt: Date().addingTimeInterval(-86400 * 1),
                rules: "친절하게 대화해주세요",
                isVerified: true,
                joinState: .open,
                tags: ["korea", "community"],
                languages: ["korean", "english"],
                galleries: nil,
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date(),
                memberships: [
                    GroupMembership(
                        id: "mem_1",
                        groupId: "grp_1",
                        userId: userId,
                        isRepresenting: false,
                        isSubscribedToAnnouncements: true,
                        visibility: .visible,
                        isSubscribedToEvents: true,
                        roleIds: ["role_member"],
                        joinedAt: Date().addingTimeInterval(-86400 * 7),
                        rolePermissions: nil,
                        roleOrder: nil
                    )
                ],
                roles: [
                    GroupRole(
                        id: "role_member",
                        groupId: "grp_1",
                        name: "Member",
                        description: "일반 멤버",
                        isSelfAssignable: false,
                        permissions: ["read"],
                        isManagementRole: false,
                        requiresTwoFactor: false,
                        requiresPurchase: false,
                        order: 1,
                        createdAt: nil,
                        updatedAt: nil
                    )
                ],
                representable: true,
                myMember: GroupMembership(
                    id: "mem_1",
                    groupId: "grp_1",
                    userId: userId,
                    isRepresenting: false,
                    isSubscribedToAnnouncements: true,
                    visibility: .visible,
                    isSubscribedToEvents: true,
                    roleIds: ["role_member"],
                    joinedAt: Date().addingTimeInterval(-86400 * 7),
                    rolePermissions: nil,
                    roleOrder: nil
                )
            ),
            VRCGroup(
                id: "gmem_2",
                groupId: "grp_2",
                name: "VRChat Developers",
                shortCode: "VRCD",
                discriminator: "0002",
                description: "VRChat 개발자 커뮤니티",
                bannerId: nil,
                bannerUrl: nil,
                iconId: nil,
                iconUrl: nil,
                ownerId: "usr_owner2",
                privacy: .private,
                memberCount: 500,
                memberVisibility: .visible,
                mutualGroup: true,
                isRepresenting: true,
                lastPostCreatedAt: Date().addingTimeInterval(-86400 * 14),
                lastPostReadAt: Date().addingTimeInterval(-86400 * 2),
                rules: "개발 관련 토론만 허용",
                isVerified: false,
                joinState: .invite,
                tags: ["development", "technical"],
                languages: ["english"],
                galleries: nil,
                createdAt: Date().addingTimeInterval(-86400 * 60),
                updatedAt: Date(),
                memberships: [
                    GroupMembership(
                        id: "mem_2",
                        groupId: "grp_2",
                        userId: userId,
                        isRepresenting: true,
                        isSubscribedToAnnouncements: true,
                        visibility: .visible,
                        isSubscribedToEvents: true,
                        roleIds: ["role_admin"],
                        joinedAt: Date().addingTimeInterval(-86400 * 14),
                        rolePermissions: nil,
                        roleOrder: nil
                    )
                ],
                roles: [
                    GroupRole(
                        id: "role_admin",
                        groupId: "grp_2",
                        name: "Admin",
                        description: "관리자",
                        isSelfAssignable: false,
                        permissions: ["read", "write", "manage"],
                        isManagementRole: true,
                        requiresTwoFactor: false,
                        requiresPurchase: false,
                        order: 0,
                        createdAt: nil,
                        updatedAt: nil
                    )
                ],
                representable: true,
                myMember: GroupMembership(
                    id: "mem_2",
                    groupId: "grp_2",
                    userId: userId,
                    isRepresenting: true,
                    isSubscribedToAnnouncements: true,
                    visibility: .visible,
                    isSubscribedToEvents: true,
                    roleIds: ["role_admin"],
                    joinedAt: Date().addingTimeInterval(-86400 * 14),
                    rolePermissions: nil,
                    roleOrder: nil
                )
            )
        ]
    }
    
    public func fetchUserRepresentedGroups(userId: String) async throws -> [VRCGroup] {
        let allGroups = try await fetchUserGroups(userId: userId)
        return allGroups.filter { $0.isRepresenting == true }
    }
    
    public func fetchGroup(groupId: String) async throws -> VRCGroup {
        return VRCGroup(
            id: "gmem_sample",
            groupId: groupId,
            name: "Sample Group",
            shortCode: "SAMPLE",
            discriminator: "0003",
            description: "샘플 그룹입니다",
            bannerId: nil,
            bannerUrl: nil,
            iconId: nil,
            iconUrl: nil,
            ownerId: "usr_owner3",
            privacy: .public,
            memberCount: 100,
            memberVisibility: .visible,
            mutualGroup: true,
            isRepresenting: false,
            lastPostCreatedAt: Date().addingTimeInterval(-86400 * 10),
            lastPostReadAt: Date().addingTimeInterval(-86400 * 5),
            rules: "샘플 규칙",
            isVerified: false,
            joinState: .open,
            tags: ["sample"],
            languages: ["korean"],
            galleries: nil,
            createdAt: Date().addingTimeInterval(-86400 * 10),
            updatedAt: Date(),
            memberships: nil,
            roles: nil,
            representable: true,
            myMember: GroupMembership(
                id: "mem_sample",
                groupId: groupId,
                userId: "usr_sample",
                isRepresenting: false,
                isSubscribedToAnnouncements: true,
                visibility: .visible,
                isSubscribedToEvents: true,
                roleIds: ["role_member"],
                joinedAt: Date().addingTimeInterval(-86400 * 10),
                rolePermissions: nil,
                roleOrder: nil
            )
        )
    }
    
    public func fetchGroupRawJSON(groupId: String) async throws -> Data {
        let mockGroup = try await fetchGroup(groupId: groupId)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(mockGroup)
    }
}
