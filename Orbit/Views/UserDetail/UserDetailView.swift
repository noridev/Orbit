import AsyncSwiftUI
import NukeUI
import VRCKit

struct UserDetailView: View {
    @Environment(AppViewModel.self) var appVM
    @Environment(FavoriteViewModel.self) var favoriteVM
    @Environment(FriendViewModel.self) var friendVM
    @Environment(\.dismiss) private var dismiss
    @State var user: UserDetail
    @State var instance: Instance?
    @State var isRequesting = false
    @State var lastActivity = ""
    @State var isPresentedNoteEditor = false
    private let headerHeight: CGFloat = 250

    // init은 기존과 동일
    init(user: UserDetail) {
        self.user = user
    }

    var body: some View {
        ScrollView {
            VStack {
                GeometryReader { geometry in
                    GradientOverlayImageView(
                        imageUrl: user.imageUrl(.x1024),
                        thumbnailImageUrl: user.imageUrl(.x256),
                        size: CGSize(width: geometry.size.width, height: headerHeight),
                        topContent: { topOverlay },
                        bottomContent: { bottomOverlay }
                    )
                }
                .frame(height: headerHeight)
                contentStacks
            }
        }
        .navigationTitle(user.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .toolbar { toolbar }
        .task {
            if case let .id(id) = user.location {
                await fetchInstance(id: id)
            }
        }
        .task {
            lastActivity = await DateUtil.shared.formatRelative(from: user.lastActivity)
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem { UserDetailToolbarMenu(user: user) }
    }

    private var contentStacks: some View {
        VStack {
            locationSection
            noteSection
            
            // --- 추가된 부분 시작 ---
            if let friend = friendVM.getFriend(id: user.id) {
                historySection(friend: friend)
            }
            // --- 추가된 부분 끝 ---

            if let bio = user.bio {
                bioSection(bio)
            }
            if !user.tags.languageTags.isEmpty {
                languageSection
            }
            let urls = user.bioLinks.wrappedValue
            if !urls.isEmpty {
                socialLinksSection(urls)
            }
            activitySection
        }
    }
    
    // --- 아래 함수 추가 ---
    private func historySection(friend: Friend) -> some View {
        GroupBox {
            NavigationLink(destination: FriendHistoryView(friend: friend)) {
                HStack {
                    Label("Friend History", systemImage: "clock.arrow.circlepath")
                    Spacer()
                    IconSet.forward.icon
                }
            }
            .foregroundStyle(Color.primary)
        }
        .groupBoxStyle(.card)
    }
    // --- 추가된 함수 끝 ---

    private func fetchInstance(id: String) async {
        do {
            defer { isRequesting = false }
            isRequesting = true
            let service = appVM.services.instanceService
            instance = try await service.fetchInstance(location: id)
        } catch {
            appVM.handleError(error)
        }
    }
}
// Preview는 기존과 동일
#Preview {
    PreviewContainer { userDetail in
        UserDetailView(user: userDetail)
    }
}
