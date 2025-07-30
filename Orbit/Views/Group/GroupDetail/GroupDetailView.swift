//
//  GroupDetailView.swift
//  Orbit
//
//  Created by NoriDev on 7/17/25.
//

import SwiftUI
import VRCKit

struct GroupDetailView: View {
    let group: VRCGroup
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    @State private var isLoading = false
    @State private var isPresentedJsonView = false
    @State var ownerUserState: OwnerUserState = .loading
    @State var currentGroup: VRCGroup
    @State private var members: [GroupMembership]?
    @State private var selectedTab: Tab = .info
    @State private var selectedImageURL: URL?
    @State private var reloadTrigger = false
    @State private var groupInstances: [Instance] = []
    @State private var isLoadingInstances = false
    @State private var instanceError: Error?
    
    enum Tab: String, CaseIterable, Identifiable {
        case info = "정보"
        case posts = "포스트"
        case members = "멤버"
        case gallery = "갤러리"
        case instances = "인스턴스"
        var id: String { rawValue }
    }
    
    enum OwnerUserState {
        case loading
        case loaded(UserDetail)
        case notFound
        case error(Error)
    }
    
    init(group: VRCGroup) {
        self.group = group
        self._currentGroup = State(initialValue: group)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Tabs", selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding([.bottom, .horizontal])
            
            Group {
                switch selectedTab {
                case .info:
                    GroupInfoView(group: currentGroup, reloadTrigger: $reloadTrigger, headerSection: AnyView(headerSection))
                case .posts:
                    GroupPostListView(selectedImageURL: $selectedImageURL, reloadTrigger: $reloadTrigger, groupId: currentGroup.groupId ?? currentGroup.id)
                case .members:
                    GroupMemberListView(reloadTrigger: $reloadTrigger, groupId: currentGroup.groupId ?? currentGroup.id, currentGroup: currentGroup)
                case .gallery:
                    GroupGalleryView(selectedImageURL: $selectedImageURL, reloadTrigger: $reloadTrigger, galleries: currentGroup.galleries, groupId: currentGroup.actualGroupId)
                case .instances:
                    GroupInstanceListView(reloadTrigger: $reloadTrigger, groupId: currentGroup.groupId ?? currentGroup.id, groupName: currentGroup.name)
                }
            }
        }
        .navigationTitle(currentGroup.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("JSON Data", systemImage: "doc.text") {
                        isPresentedJsonView = true
                    }
                } label: {
                    Image(systemName: IconSet.dots.systemName)
                }
            }
        }
        .sheet(isPresented: $isPresentedJsonView) {
            GroupJsonDetailView(group: currentGroup)
        }
        .fullScreenCover(item: $selectedImageURL) { url in
            ImageViewer(imageUrl: url)
        }
        .refreshable {
            await refreshData()
            reloadTrigger.toggle()
        }
        .onChange(of: selectedTab) {
            if selectedTab == .instances && groupInstances.isEmpty && !isLoadingInstances {
                Task { await loadGroupInstances() }
            }
        }
        .task {
            await refreshData()
            if selectedTab == .instances {
                await loadGroupInstances()
            }
        }
    }
    
    private func refreshData() async {
        isLoading = true
        defer { isLoading = false }

        await fetchGroupDetails()
        await fetchOwnerUser()
        await fetchMembers()
    }
    
    @MainActor
    private func fetchGroupDetails() async {
        do {
            let updatedGroup = try await appVM.services.groupService.fetchGroup(
                groupId: currentGroup.groupId ?? currentGroup.id,
                includeRoles: true,
                includeMembers: true
            )
            self.currentGroup = updatedGroup
        } catch {
            print("❌ [GroupDetailView] Failed to fetch group details: \(error)")
        }
    }
    
    @MainActor
    private func fetchOwnerUser() async {
        do {
            let user = try await appVM.services.userService.fetchUser(userId: currentGroup.ownerId)
            self.ownerUserState = .loaded(user)
        } catch {
            let isNotFound: Bool
            if let vrcError = error as? VRCKitError {
                switch vrcError {
                case .apiError(let details):
                    isNotFound = details.contains("404") || details.lowercased().contains("not found")
                default:
                    isNotFound = false
                }
            } else {
                isNotFound = error.localizedDescription.lowercased().contains("not found") ||
                            (error as NSError).code == 404
            }
            
            self.ownerUserState = isNotFound ? .notFound : .error(error)
            print("❌ [GroupDetailView] Failed to fetch owner user: \(error)")
        }
    }
    
    @MainActor
    private func fetchMembers() async {
        do {
            let groupMembers = try await appVM.services.groupService.fetchGroupMembers(
                groupId: currentGroup.groupId ?? currentGroup.id,
                offset: 0,
                n: 100
            )
            self.members = groupMembers
        } catch {
            print("❌ [GroupDetailView] Failed to fetch group members: \(error)")
        }
    }
    
    @MainActor
    private func loadGroupInstances() async {
        isLoadingInstances = true
        instanceError = nil
        do {
            let userId = appVM.user?.id ?? "me"
            let groupId = currentGroup.groupId ?? currentGroup.id
            let instances = try await appVM.services.groupService.fetchGroupInstances(userId: userId, groupId: groupId)
            self.groupInstances = instances
            self.isLoadingInstances = false
        } catch {
            self.instanceError = error
            self.isLoadingInstances = false
        }
    }
}

struct GroupJsonDetailView: View {
    let group: VRCGroup
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            JsonDetailView(
                userId: group.groupId ?? group.id,
                cachedData: group,
                isLocalDataView: false,
                title: group.name,
                subTitle: "Group JSON Data",
                useNavigationStack: true,
                showToolbar: true,
                onDismiss: { dismiss() }
            )
        }
    }
}

#Preview {
    NavigationView {
        GroupDetailView(group: PreviewData.sampleGroup)
    }
}
