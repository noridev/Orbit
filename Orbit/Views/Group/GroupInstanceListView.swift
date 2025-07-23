import SwiftUI
import VRCKit

struct GroupInstanceListView: View {
    let instances: [Instance]
    let groupName: String
    @State private var selectedInstance: Instance?
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    
    var body: some View {
        LazyVStack(spacing: 12) {
            if instances.isEmpty {
                ContentUnavailableView {
                    Label("인스턴스가 없습니다", systemImage: "person.3.fill")
                        .foregroundColor(.gray)
                } description: {
                    Text("이 그룹에는 현재 인스턴스가 없습니다")
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ForEach(instances) { instance in
                    Button(action: { selectedInstance = instance }) {
                        GroupBox {
                            InstanceCardContent(instance: instance)
                        }
                        .groupBoxStyle(.card)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 32)
        .sheet(item: $selectedInstance) { instance in
            LocationDetailViewForInstance(instance: instance, appVM: appVM, friendVM: friendVM)
        }
    }
}

private struct InstanceCardContent: View {
    let instance: Instance
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            WorldHeaderView(world: instance.world) {
                Text(InstanceUtil.getInstanceWithInstanceType(instance))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule()).lineLimit(1)
                HStack(spacing: 2) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(instance.userCount) / \(instance.capacity)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
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
}

private struct LocationDetailViewForInstance: View {
    let instance: Instance
    @Environment(\.dismiss) private var dismiss
    @State private var users: [UserDetail] = []
    @State private var isLoadingUsers = false
    @State private var userError: Error?
    var appVM: AppViewModel
    var friendVM: FriendViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section("World") {
                    WorldHeaderView(world: instance.world) {
                        Text(instance.world.description ?? "")
                            .font(.footnote)
                            .foregroundStyle(Color.gray)
                            .lineLimit(2)
                    }
                }
                
                Section("Information") {
                    LabeledContent("Instance ID", value: instance.instanceId)
                    LabeledContent("Users", value: "\(instance.userCount)")
                    LabeledContent("Capacity", value: "\(instance.capacity)")
                    LabeledContent("Region", value: instance.region.description)
                    LabeledContent("Type", value: instance.typeDescription)
                }
                
                Section("Users") {
                    if isLoadingUsers {
                        HStack {
                            Spacer()
                            ProgressView("유저 목록을 불러오는 중...")
                            Spacer()
                        }
                    } else if let error = userError {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(.orange)
                            Text("유저 목록을 불러오지 못했습니다")
                                .font(.headline)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if users.isEmpty {
                        Text("현재 이 인스턴스에 접속한 유저가 없습니다")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(users) { user in
                            NavigationLink(destination: UserDetailPresentationView(id: user.id)) {
                                SimpleUserRowContent(
                                    userId: user.id,
                                    displayName: user.displayName,
                                    userIconUrl: user.userIcon,
                                    status: user.status,
                                    statusDescription: user.statusDescription,
                                    location: user.location,
                                    isFriend: friendVM.isFriend(id: user.id)
                                )
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(instance.world.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadUsers) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoadingUsers)
                }
            }
            .task {
                loadUsers()
            }
        }
    }
    
    private func loadUsers() {
        guard !isLoadingUsers else { return }
        
        isLoadingUsers = true
        userError = nil
        
        Task {
            do {
                let userId = appVM.user?.id ?? "me"
                let groupId = instance.location.getGroupId() ?? ""
                let instanceId = instance.location.getInstanceId() ?? ""
                
                if !groupId.isEmpty && !instanceId.isEmpty {
                    let fetchedUsers = try await appVM.services.groupService.fetchUsersInGroupInstance(
                        userId: userId,
                        groupId: groupId,
                        instanceId: instanceId
                    )
                    await MainActor.run {
                        self.users = fetchedUsers
                        self.isLoadingUsers = false
                    }
                } else {
                    throw VRCKitError.invalidResponse("Invalid group or instance ID")
                }
            } catch {
                await MainActor.run {
                    self.userError = error
                    self.isLoadingUsers = false
                }
            }
        }
    }
} 