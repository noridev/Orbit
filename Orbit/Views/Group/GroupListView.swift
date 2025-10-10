//
//  GroupListView.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import SwiftUI
import VRCKit

struct GroupListView: View {
    @Environment(AppViewModel.self) var appVM
    @Environment(\.dismiss) private var dismiss
    @StateObject var groupViewModel = GroupViewModel.shared
    @State var searchText = ""
    @State var sortType: SortType = .name
    @State var isPresentedSheet = false
    let userId: String
    let userName: String?
    let groupService: GroupProvidable
    var isPresentedAsSheet: Binding<Bool>?

    init(userId: String, userName: String? = nil, groupService: GroupProvidable, isPresentedAsSheet: Binding<Bool>? = nil) {
        self.userId = userId
        self.userName = userName
        self.groupService = groupService
        self.isPresentedAsSheet = isPresentedAsSheet
    }
    
    var body: some View {
        List {
            if !filteredRepresentedGroups.isEmpty {
                Section {
                    ForEach(filteredRepresentedGroups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group, isRepresenting: false, isManagedGroup: false, isMutualGroup: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: { 
                    GroupSectionHeader(
                        iconName: "star.fill",
                        iconColor: .yellow,
                        title: "Representing"
                    )
                }
            }
            
            if !filteredManagedGroups.isEmpty {
                Section {
                    ForEach(filteredManagedGroups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group, isRepresenting: false, isManagedGroup: false, isMutualGroup: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: { 
                    GroupSectionHeader(
                        iconName: IconSet.shield.systemName,
                        iconColor: .blue,
                        title: "관리 중인 그룹",
                        count: filteredManagedGroups.count
                    )
                }
            }
            
            if !filteredMutualGroups.isEmpty && userId != appVM.user?.id {
                Section {
                    ForEach(filteredMutualGroups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group, isRepresenting: false, isManagedGroup: false, isMutualGroup: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: { 
                    GroupSectionHeader(
                        iconName: "person.2.circle.fill",
                        iconColor: .purple,
                        title: "함께 속한 그룹",
                        count: filteredMutualGroups.count
                    )
                }
            }
            
            if !filteredRegularGroups.isEmpty || (userId == appVM.user?.id && !filteredMutualGroups.isEmpty) {
                Section {
                    ForEach(userId == appVM.user?.id ? (filteredRegularGroups + filteredMutualGroups) : filteredRegularGroups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group, isRepresenting: false, isManagedGroup: false, isMutualGroup: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: { 
                    GroupSectionHeader(
                        iconName: "person.3.fill",
                        iconColor: .green,
                        title: "소속된 그룹",
                        count: userId == appVM.user?.id ? (filteredRegularGroups.count + filteredMutualGroups.count) : filteredRegularGroups.count
                    )
                }
            }
        }
        .overlay { overlayView }
        .refreshable {
            await groupViewModel.loadUserGroups()
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $isPresentedSheet) {
            FilterSheetView(
                sortType: $sortType,
                statusFilter: .constant([]),
                favoriteGroupFilter: .constant([]),
                eventFilter: .constant([]),
                excludeWebUsers: .constant(false),
                sortContext: .groups,
                visibleSections: []
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            groupViewModel.configure(groupService: groupService, userId: userId)
            
            if groupViewModel.userGroups.isEmpty && !groupViewModel.isLoading {
                Task {
                    await groupViewModel.loadUserGroups()
                }
            } else if groupViewModel.isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if groupViewModel.isLoading {
                        groupViewModel.resetState()
                        Task {
                            await groupViewModel.loadUserGroups()
                        }
                    }
                }
            }
        }
        .task {
            groupViewModel.configure(groupService: groupService, userId: userId)
            await groupViewModel.loadUserGroups()
        }
        .onReceive(groupViewModel.objectWillChange) { _ in
            // Force view update when view model changes
        }
    }
}

#Preview {
    GroupListView(
        userId: "usr_preview",
        groupService: GroupPreviewService(client: APIClient())
    )
}
