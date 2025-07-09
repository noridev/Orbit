//
//  UserDetailView.swift
//  Orbit
//
//  Created by makinosp on 2024/03/16.
//

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
    @State var lastActivity = ""
    @State var isPresentedNoteEditor = false
    @State var isRequesting = false
    @State private var isPresentedAlert = false
    @State private var isPresentedSettings = false
    @State private var isPresentedForm = false
    @State private var isPresentedBrowser = false
    @State private var isPresentedJsonView = false
    
    private let headerHeight: CGFloat = 250

    init(user: UserDetail) {
        _user = State(initialValue: user)
    }

    var body: some View {
        ScrollView {
            VStack {
                GeometryReader { geometry in
                    GradientOverlayImageView(
                        imageUrl: user.imageUrl(.x1024),
                        thumbnailImageUrl: user.imageUrl(.x256),
                        size: CGSize(
                            width: max(geometry.size.width, 1), 
                            height: max(headerHeight, 1)
                        ),
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
        .toolbar {
            UserDetailToolbarMenu(
                isRequesting: $isRequesting,
                isPresentedAlert: $isPresentedAlert,
                isPresentedSettings: $isPresentedSettings,
                isPresentedForm: $isPresentedForm,
                isPresentedBrowser: $isPresentedBrowser,
                isPresentedJsonView: $isPresentedJsonView,
                user: user
            )
        }
        .alert("Unfriend", isPresented: $isPresentedAlert) {
            unfriendTaskButton
        } message: {
            Text("Are you sure you want to unfriend?")
        }
        .sheet(isPresented: $isPresentedSettings) { SettingsView() }
        .sheet(isPresented: $isPresentedForm) {
            if let user = appVM.user { ProfileEditView(user: user) }
        }
        .sheet(isPresented: $isPresentedBrowser) {
            if let url = URL(string: "https://vrchat.com/home/profile") {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $isPresentedJsonView) {
            UserDetailJsonDetailView(userDetail: user)
        }
        .task {
            if case let .id(id) = user.location { await fetchInstance(id: id) }
        }
        .task {
            if let lastActivity = user.lastActivity {
                self.lastActivity = await DateUtil.shared.formatRelative(from: lastActivity)
            }
        }
    }
    
    private var contentStacks: some View {
        VStack {
            locationSection
            noteSection
            
            if let friend = friendVM.getFriend(id: user.id) {
                historySection(friend: friend)
            }

            bioSection(user.bio)

            if !user.tags.languageTags.isEmpty {
                languageSection
            }
            let urls = user.bioLinks.wrappedValue
            if !urls.isEmpty {
                socialLinksSection(urls)
            }
            activitySection
            
            Spacer()
        }
    }
    
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

    private func fetchInstance(id: String) async {
        do {
            defer { isRequesting = false }
            isRequesting = true
            let service = appVM.services.instanceService
            instance = try await service.fetchInstance(location: id)
        } catch {
            if !error.isCancelled {
                appVM.handleError(error)
            }
        }
    }

    private var unfriendTaskButton: some View {
        Button("Unfriend", role: .destructive) {
            Task {
                do {
                    try await appVM.services.friendService.unfriend(id: user.id)
                } catch {
                    appVM.handleError(error)
                }
                await friendVM.fetchAllFriends { error in
                    appVM.handleError(error)
                }
                dismiss()
            }
        }
    }
}
