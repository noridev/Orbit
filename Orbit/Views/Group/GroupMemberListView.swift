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
    let currentGroup: VRCGroup?
    @State private var members: [GroupMembership] = []
    @State private var userDetails: [String: UserDetail] = [:]
    @State private var isLoading = false
    @State private var error: Error?
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("로딩 중...")
            } else if let error = error {
                VStack {
                    Text("멤버를 불러오지 못했습니다")
                    Text(error.localizedDescription).font(.caption).foregroundColor(.secondary)
                }
            } else if members.isEmpty {
                Text("멤버가 없습니다")
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(members, id: \.id) { member in
                        NavigationLink {
                            UserDetailPresentationView(id: member.userId)
                        } label: {
                            GroupBox {
                                HStack(alignment: .center, spacing: 12) {
                                    if let user = friendVM.getFriend(id: member.userId) {
                                        UserIcon(
                                            user: user,
                                            size: Constants.IconSize.userDetailThumbnail,
                                            showStatusIndicator: true,
                                            showTrustRankBorder: true
                                        )
                                    } else if let userDetail = userDetails[member.userId] {
                                        UserIcon(
                                            user: userDetail,
                                            size: Constants.IconSize.userDetailThumbnail,
                                            showStatusIndicator: true,
                                            showTrustRankBorder: true
                                        )
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white.opacity(0.7))
                                            )
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(getDisplayName(for: member.userId))
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        if let joinedAt = member.joinedAt {
                                            HStack(spacing: 4) {
                                                IconSet.calendar.icon
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text("가입일: \(joinedAt, style: .date)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        if !member.roleIds.isEmpty {
                                            HStack(spacing: 6) {
                                                Text("\(getRoleNames(for: member.roleIds).joined(separator: ", "))")
                                                    .font(.caption2)
                                                    .foregroundStyle(isManager(for: member) ? .blue : .primary)
                                                
                                                if isManager(for: member) {
                                                    Image(systemName: IconSet.shield.systemName)
                                                        .font(.caption2)
                                                        .foregroundStyle(.blue)
                                                }
                                            }
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Capsule())
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
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear(perform: loadMembers)
        .refreshable { loadMembers() }
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
    
    private func loadMembers() {
        isLoading = true
        error = nil
        Task {
            do {
                let result = try await appVM.services.groupService.fetchGroupMembers(groupId: groupId)
                await MainActor.run {
                    self.members = result
                    self.isLoading = false
                }
                await loadUserDetails(for: result)
                await addCurrentUserIfNeeded()
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    private func addCurrentUserIfNeeded() async {
        guard let currentUser = appVM.user,
              let currentGroup = currentGroup,
              let myMember = currentGroup.myMember else { return }
        
        let isCurrentUserInList = members.contains { member in
            member.userId == currentUser.id
        }
        
        if !isCurrentUserInList {
            await MainActor.run {
                self.members.append(myMember)
            }
            
            await loadUserDetails(for: [myMember])
        }
    }
    
    private func loadUserDetails(for members: [GroupMembership]) async {
        let nonFriendMembers = members.filter { member in
            friendVM.getFriend(id: member.userId) == nil
        }
        
        await withTaskGroup(of: (String, UserDetail?).self) { group in
            for member in nonFriendMembers {
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
