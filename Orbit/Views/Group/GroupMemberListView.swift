//
//  GroupMemberListView.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

struct UserIdWrapper: Identifiable, Hashable {
    let id: String
}

struct GroupMemberListView: View {
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @Binding var reloadTrigger: Bool
    @State private var members: [GroupMembership] = []
    @State private var userDetails: [String: UserDetail] = [:]
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selected: String?
    @State private var selectedUserId: UserIdWrapper?
    @State private var currentOffset = 0
    @State private var hasMoreMembers = true
    let groupId: String
    let currentGroup: VRCKit.VRCGroup?
    
    private var canViewAllMembers: Bool {
        guard let currentGroup = currentGroup,
              let myMember = currentGroup.myMember,
              let roles = currentGroup.roles else {
            return false
        }
        
        for roleId in myMember.roleIds {
            if let role = roles.first(where: { $0.id == roleId }) {
                if role.permissions.contains("*") || role.permissions.contains("group-members-viewall") {
                    return true
                }
            }
        }
        return false
    }
    
    private var headerText: String {
        if canViewAllMembers {
            return "전체 멤버"
        } else {
            return "친구인 멤버"
        }
    }
    
    private var memberCount: Int {
        isLoading ? 0 : members.count
    }
    
    private var placeholderMembers: [GroupMembership] {
        (0..<8).map { i in
            GroupMembership(
                id: "placeholder_\(i)",
                groupId: "grp_placeholder",
                userId: "usr_placeholder_\(i)",
                isRepresenting: false,
                isSubscribedToAnnouncements: false,
                visibility: .hidden,
                isSubscribedToEvents: false,
                roleIds: ["role_placeholder"],
                joinedAt: Date(),
                rolePermissions: nil,
                roleOrder: nil
            )
        }
    }

    var body: some View {
        let displayMembers = isLoading ? placeholderMembers : members

        Group {
            if !isLoading && members.isEmpty {
                if let error = error {
                    VStack {
                        Text("멤버를 불러오지 못했습니다")
                        Text(error.localizedDescription).font(.caption).foregroundColor(.secondary)
                    }
                } else {
                    ContentUnavailableView {
                        Label("멤버가 없습니다", systemImage: "person.3.fill")
                            .foregroundColor(.gray)
                    } description: {
                        Text("이 그룹에는 아직 멤버가 없습니다")
                    }
                }
            } else {
                GroupMemberList(
                    displayMembers: displayMembers,
                    hasMoreMembers: hasMoreMembers,
                    loadMoreMembers: { await loadMoreMembers() },
                    headerText: headerText,
                    memberCount: memberCount,
                    isLoading: isLoading,
                    userDetails: userDetails,
                    getRoleNames: getRoleNames,
                    isManager: isManager,
                    selected: $selected,
                    selectedUserId: $selectedUserId
                )
                .refreshable {
                    await loadMembers(force: true)
                }
            }
        }
        .onAppear {
            isLoading = true
            Task { await loadMembers(force: true) }
        }
        .onChange(of: reloadTrigger) { _, _ in
            Task { await loadMembers(force: true) }
        }
    }
    
    private func getDisplayName(for userId: String) -> String {
        if let friend = friendVM.getFriend(id: userId) {
            return friend.displayName
        } else if let userDetail = userDetails[userId] {
            return userDetail.displayName
        } else {
            return userId
        }
    }
    
    private func getRoleNames(for roleIds: [String]) -> [String] {
        guard let roles = currentGroup?.roles else { return roleIds }
        
        return roleIds.compactMap { roleId in
            roles.first { role in
                role.id == roleId
            }?.name ?? roleId
        }
    }
    
    @MainActor
    private func loadMembers(force: Bool = false) async {
        if !force {
            guard members.isEmpty, !isLoading else { return }
        }

        currentOffset = 0
        hasMoreMembers = true
        isLoading = true
        error = nil

        do {
            let result = try await appVM.services.groupService.fetchGroupMembers(
                groupId: groupId,
                offset: 0,
                n: 100
            )
            var finalResult = result
            if let currentUser = appVM.user,
               let currentGroup = currentGroup,
               let myMember = currentGroup.myMember,
               !result.contains(where: { $0.userId == currentUser.id }) {
                finalResult.append(myMember)
                await loadUserDetails(for: [myMember])
            }
            await loadUserDetails(for: result)
            self.members = finalResult
            self.hasMoreMembers = !result.isEmpty
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
            self.hasMoreMembers = false
        }
    }
    
    @MainActor
    private func loadMoreMembers() async {
        guard !isLoading, hasMoreMembers else { return }
        
        currentOffset += 100
        do {
            let newMembers = try await appVM.services.groupService.fetchGroupMembers(
                groupId: groupId,
                offset: currentOffset,
                n: 100
            )
            await loadUserDetails(for: newMembers)
            self.members.append(contentsOf: newMembers)
            self.hasMoreMembers = !newMembers.isEmpty
        } catch {
            print("Failed to load more members: \(error)")
            self.hasMoreMembers = false
        }
    }
    
    @MainActor
    private func loadUserDetails(for members: [GroupMembership]) async {
        let membersToFetch = members.filter { member in
            friendVM.getFriend(id: member.userId) == nil && userDetails[member.userId] == nil
        }
        
        guard !membersToFetch.isEmpty else { return }
        
        await withTaskGroup(of: (String, UserDetail?).self) { group in
            for member in membersToFetch {
                group.addTask {
                    do {
                        let userDetail = try await appVM.services.userService.fetchUser(userId: member.userId)
                        return (member.userId, userDetail)
                    } catch {
                        print("Failed to fetch user detail for \(member.userId): \(error)")
                        return (member.userId, nil)
                    }
                }
            }
            
            for await (userId, userDetail) in group {
                if let userDetail = userDetail {
                    self.userDetails[userId] = userDetail
                }
            }
        }
    }
    
    private func isManager(for member: GroupMembership) -> Bool {
        guard let roles = currentGroup?.roles else { return false }
        return member.roleIds.contains { roleId in
            roles.first(where: { $0.id == roleId })?.isManagementRole == true
        }
    }
}

struct GroupMemberList: View {
    let displayMembers: [GroupMembership]
    let hasMoreMembers: Bool
    let loadMoreMembers: () async -> Void
    let headerText: String
    let memberCount: Int
    let isLoading: Bool
    let userDetails: [String: UserDetail]
    let getRoleNames: ([String]) -> [String]
    let isManager: (GroupMembership) -> Bool
    @Environment(FriendViewModel.self) var friendVM
    @Binding var selected: String?
    @Binding var selectedUserId: UserIdWrapper?

    var body: some View {
        List(selection: $selected) {
            Section(header: HStack {
                Text(headerText)
                Spacer()
                Text("\(memberCount)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                    .redacted(reason: isLoading ? .placeholder : [])
            }) {
                ForEach(displayMembers, id: \.userId) { member in
                    NavigationLabel {
                        HStack(alignment: .center, spacing: 12) {
                            if let user = friendVM.getFriend(id: member.userId) {
                                UserRowContent(
                                    user: user,
                                    joinedAt: member.joinedAt,
                                    roles: getRoleNames(member.roleIds),
                                    isManager: isManager(member),
                                    isLoading: isLoading,
                                    iconSize: Constants.IconSize.userDetailThumbnail
                                )
                            } else if let userDetail = userDetails[member.userId] {
                                UserRowContent(
                                    user: userDetail,
                                    joinedAt: member.joinedAt,
                                    roles: getRoleNames(member.roleIds),
                                    isManager: isManager(member),
                                    isLoading: isLoading,
                                    iconSize: Constants.IconSize.userDetailThumbnail
                                )
                            } else {
                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 44, height: 44)
                                    Text("알 수 없는 유저")
                                }
                            }
                        }
                    }
                    .tag(UserIdWrapper(id: member.userId))
                    .redacted(reason: isLoading ? .placeholder : [])
                    .onAppear {
                        if member.id == displayMembers.last?.id && hasMoreMembers {
                            Task { await loadMoreMembers() }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(item: $selectedUserId) { wrapper in
            UserDetailPresentationView(id: wrapper.id)
        }
        .onChange(of: selected) { _, newValue in
            if let userId = newValue {
                selected = nil
                selectedUserId = UserIdWrapper(id: userId)
            }
        }
    }
}
