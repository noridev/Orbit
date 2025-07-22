//
//  GroupMemberListView.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

struct GroupMemberListView: View {
    let groupId: String
    let currentGroup: VRCKit.VRCGroup?
    @Binding var reloadTrigger: Bool
    @State private var members: [GroupMembership] = []
    @State private var userDetails: [String: UserDetail] = [:]
    @State private var isLoading = false
    @State private var error: Error?
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    
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

        LazyVStack(spacing: 12) {
            if !isLoading && members.isEmpty {
                if let error = error {
                    VStack {
                        Text("멤버를 불러오지 못했습니다")
                        Text(error.localizedDescription).font(.caption).foregroundColor(.secondary)
                    }
                } else {
                    Text("멤버가 없습니다")
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(displayMembers, id: \.id) { member in
                    NavigationLink {
                        if !isLoading {
                            UserDetailPresentationView(id: member.userId)
                        }
                    } label: {
                        GroupBox {
                            HStack(alignment: .center, spacing: 12) {
                                if let user = friendVM.getFriend(id: member.userId) {
                                    UserRowContent(
                                        user: user,
                                        joinedAt: member.joinedAt,
                                        roles: getRoleNames(for: member.roleIds),
                                        isManager: isManager(for: member),
                                        isLoading: isLoading,
                                        iconSize: Constants.IconSize.userDetailThumbnail
                                    )
                                } else if let userDetail = userDetails[member.userId] {
                                    UserRowContent(
                                        user: userDetail,
                                        joinedAt: member.joinedAt,
                                        roles: getRoleNames(for: member.roleIds),
                                        isManager: isManager(for: member),
                                        isLoading: isLoading,
                                        iconSize: Constants.IconSize.userDetailThumbnail
                                    )
                                } else {
                                    HStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 44, height: 44)
                                        Text("...")
                                    }
                                }
                                Spacer()
                                Image(systemName: IconSet.forward.systemName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .opacity(0.5)
                            }
                            .padding(.vertical, 6)
                        }
                        .groupBoxStyle(.card)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }
        }
        .padding(.bottom, 32)
        .redacted(reason: isLoading ? .placeholder : [])
        .onAppear { loadMembers() }
        .refreshable { loadMembers() }
        .onChange(of: reloadTrigger) {
            loadMembers(force: true)
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
    
    private func loadMembers(force: Bool = false) {
        if !force {
            guard members.isEmpty, !isLoading else { return }
        }
        isLoading = true
        error = nil
        Task {
            do {
                let result = try await appVM.services.groupService.fetchGroupMembers(groupId: groupId)
                await loadUserDetails(for: result)
                if let currentUser = appVM.user,
                   let currentGroup = currentGroup,
                   let myMember = currentGroup.myMember,
                   !result.contains(where: { $0.userId == currentUser.id }) {
                    var finalResult = result
                    finalResult.append(myMember)
                    await loadUserDetails(for: [myMember])
                    await MainActor.run {
                        self.members = finalResult
                    }
                } else {
                    await MainActor.run {
                        self.members = result
                    }
                }
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
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
                    await MainActor.run {
                        self.userDetails[userId] = userDetail
                    }
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
