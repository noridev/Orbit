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
                onlineMemberCount: 123,
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
                links: ["https://discord.gg/koreacommunity", "https://twitter.com/koreacommunity"],
                galleries: [
                    GroupGallery(
                        id: "ggal_1",
                        name: "Test Gallery 1",
                        description: "Test Description",
                        membersOnly: false,
                        roleIdsToView: nil,
                        roleIdsToSubmit: nil,
                        roleIdsToAutoApprove: nil,
                        roleIdsToManage: nil,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                ],
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
                onlineMemberCount: 123,
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
                links: ["https://github.com/vrchat", "https://discord.gg/vrchatdev"],
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
    
    public func fetchGroup(groupId: String, includeRoles: Bool = true, includeMembers: Bool = true) async throws -> VRCGroup {
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
            onlineMemberCount: 123,
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
            links: ["https://discord.gg/samplegroup"],
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
    
    public func fetchGroupMembers(groupId: String, offset: Int, n: Int) async throws -> [GroupMembership] {
        return [
            GroupMembership(
                id: "mem_preview_1",
                groupId: groupId,
                userId: "usr_preview_friend_1",
                isRepresenting: false,
                isSubscribedToAnnouncements: true,
                visibility: .visible,
                isSubscribedToEvents: true,
                roleIds: ["role_member"],
                joinedAt: Date(),
                rolePermissions: nil,
                roleOrder: nil
            ),
            GroupMembership(
                id: "mem_preview_2",
                groupId: groupId,
                userId: "usr_preview_friend_2",
                isRepresenting: false,
                isSubscribedToAnnouncements: true,
                visibility: .visible,
                isSubscribedToEvents: true,
                roleIds: ["role_member"],
                joinedAt: Date(),
                rolePermissions: nil,
                roleOrder: nil
            )
        ]
    }
    
    public func fetchGroupRawJSON(groupId: String) async throws -> Data {
        let mockGroup = try await fetchGroup(groupId: groupId)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(mockGroup)
    }
    
    public func fetchGroupPosts(groupId: String) async throws -> [GroupPost] {
        return [
            GroupPost(
                id: "post_1",
                groupId: groupId,
                authorId: "usr_preview_1",
                editorId: "usr_preview_1",
                visibility: "public",
                roleId: ["role_member"],
                title: "첫 번째 포스트",
                text: "첫 번째 샘플 포스트입니다!",
                imageId: nil,
                imageUrl: nil,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date().addingTimeInterval(-1800)
            ),
            GroupPost(
                id: "post_2",
                groupId: groupId,
                authorId: "usr_preview_2",
                editorId: "usr_preview_2",
                visibility: "public",
                roleId: ["role_member"],
                title: "두 번째 포스트",
                text: "두 번째 포스트, 사진도 있어요!",
                imageId: "file_sample",
                imageUrl: "https://placehold.co/80x80",
                createdAt: Date().addingTimeInterval(-7200),
                updatedAt: Date().addingTimeInterval(-3600)
            )
        ]
    }

    func fetchGroupGalleryImages(groupId: String, galleryId: String) async throws -> [GroupGalleryImage] {
        return [
            GroupGalleryImage(
                id: "ggim_1",
                groupId: groupId,
                galleryId: galleryId,
                fileId: "file_1",
                imageUrl: URL(string: "https://placehold.co/100x100")!,
                createdAt: Date(),
                submittedByUserId: "usr_preview",
                approved: true,
                approvedByUserId: "usr_preview",
                approvedAt: Date()
            ),
            GroupGalleryImage(
                id: "ggim_2",
                groupId: groupId,
                galleryId: galleryId,
                fileId: "file_2",
                imageUrl: URL(string: "https://placehold.co/100x100")!,
                createdAt: Date(),
                submittedByUserId: "usr_preview",
                approved: true,
                approvedByUserId: "usr_preview",
                approvedAt: Date()
            ),
            GroupGalleryImage(
                id: "ggim_3",
                groupId: groupId,
                galleryId: galleryId,
                fileId: "file_3",
                imageUrl: URL(string: "https://placehold.co/100x100")!,
                createdAt: Date(),
                submittedByUserId: "usr_preview",
                approved: true,
                approvedByUserId: "usr_preview",
                approvedAt: Date()
            ),
        ]
    }

    func fetchGroupInstances(userId: String, groupId: String) async throws -> [Instance] {
        return [
            PreviewData.instanceMap[PreviewData.instanceId(PreviewData.bar)]!,
            PreviewData.instanceMap[PreviewData.instanceId(PreviewData.chillRoom)]!,
            PreviewData.instanceMap[PreviewData.instanceId(PreviewData.fuji)]!
        ]
    }
}
