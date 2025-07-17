//
//  GroupViewModel.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import Foundation
import Combine
import VRCKit

@MainActor
final class GroupViewModel: ObservableObject {
    static let shared = GroupViewModel()
    
    @Published var userGroups: [VRCGroup] = []
    @Published var representedGroups: [VRCGroup] = []
    @Published var isLoading = true
    @Published var error: Error?
    
    private var groupService: GroupServiceProtocol?
    private var currentUserId: String?
    
    private init() {}
    
    func configure(groupService: GroupServiceProtocol, userId: String) {
        self.groupService = groupService
        self.currentUserId = userId
    }
    
    func loadUserGroups(userId: String? = nil) async {
        guard let groupService = groupService,
              let userId = userId ?? currentUserId else {
            print("❌ [GroupViewModel] GroupService or userId not configured")
            return
        }
        
        await MainActor.run {
            isLoading = true
            error = nil
            objectWillChange.send()
        }
        
        var userGroupsError: Error?
        var representedGroupsError: Error?
        
        do {
            let groups = try await groupService.fetchUserGroups(userId: userId)
            await MainActor.run {
                self.userGroups = groups
                objectWillChange.send()
            }
        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                print("ℹ️ [GroupViewModel] User groups request was cancelled")
                return
            }
            print("❌ [GroupViewModel] Failed to load user groups: \(error)")
            await MainActor.run {
                self.userGroups = []
                objectWillChange.send()
            }
            userGroupsError = error
        }
        
        do {
            let represented = try await groupService.fetchUserRepresentedGroups(userId: userId)
            await MainActor.run {
                self.representedGroups = represented
                objectWillChange.send()
            }
        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                print("ℹ️ [GroupViewModel] Represented groups request was cancelled")
                return
            }
            print("❌ [GroupViewModel] Failed to load represented groups: \(error)")
            await MainActor.run {
                self.representedGroups = []
                objectWillChange.send()
            }
            representedGroupsError = error
        }
        
        await MainActor.run {
            if userGroupsError != nil && representedGroupsError != nil {
                self.error = userGroupsError ?? representedGroupsError
            }
            self.isLoading = false
            objectWillChange.send()
        }
    }
    
    func refreshGroups(userId: String? = nil) async {
        guard let groupService = groupService,
              let userId = userId ?? currentUserId else {
            print("❌ [GroupViewModel] GroupService or userId not configured")
            return
        }
        
        await MainActor.run {
            isLoading = true
            error = nil
            objectWillChange.send()
        }
        
        var userGroupsError: Error?
        var representedGroupsError: Error?
        
        do {
            let groups = try await groupService.fetchUserGroups(userId: userId)
            await MainActor.run {
                self.userGroups = groups
                objectWillChange.send()
            }
        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                print("ℹ️ [GroupViewModel] User groups request was cancelled")
                return
            }
            print("❌ [GroupViewModel] Failed to load user groups: \(error)")
            await MainActor.run {
                self.userGroups = []
                objectWillChange.send()
            }
            userGroupsError = error
        }
        
        do {
            let represented = try await groupService.fetchUserRepresentedGroups(userId: userId)
            await MainActor.run {
                self.representedGroups = represented
                objectWillChange.send()
            }
        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                print("ℹ️ [GroupViewModel] Represented groups request was cancelled")
                return
            }
            print("❌ [GroupViewModel] Failed to load represented groups: \(error)")
            await MainActor.run {
                self.representedGroups = []
                objectWillChange.send()
            }
            representedGroupsError = error
        }
        
        await MainActor.run {
            if userGroupsError != nil && representedGroupsError != nil {
                self.error = userGroupsError ?? representedGroupsError
            }
            self.isLoading = false
            objectWillChange.send()
        }
    }
    
    func resetState() {
        Task { @MainActor in
            isLoading = false
            error = nil
            userGroups = []
            representedGroups = []
            objectWillChange.send()
        }
    }
    
    var allGroups: [VRCGroup] {
        userGroups
    }
    
    var managedGroups: [VRCGroup] {
        userGroups.filter { group in
            canManageGroup(group)
        }
    }
    
    private func canManageGroup(_ group: VRCGroup) -> Bool {
        let isOwner = group.ownerId == currentUserId
        
        let hasManagementRole = group.memberships?.contains { membership in
            membership.roleIds.contains { roleId in
                group.roles?.contains { role in
                    role.id == roleId && role.isManagementRole
                } ?? false
            }
        } ?? false
        
        return isOwner || hasManagementRole
    }
    
    var isRepresentingAnyGroup: Bool {
        !representedGroups.isEmpty
    }
    
    var hasGroups: Bool {
        !userGroups.isEmpty
    }
}
