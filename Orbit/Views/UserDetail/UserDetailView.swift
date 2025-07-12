//
//  UserDetailView.swift
//  Orbit
//
//  Created by makinosp on 2024/03/16.
//

import AsyncSwiftUI
import SwiftUI
import NukeUI
import VRCKit

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

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
                header
                userInfoSection
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
            UserDetailJsonDetailView(userId: user.id, cachedUserDetail: user)
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
        VStack(spacing: 12) {
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
                    print("✅ [unfriendTaskButton] Successfully unfriended user: \(user.displayName)")
                    
                    await friendVM.fetchAllFriends { error in
                        appVM.handleError(error)
                    }
                    dismiss()
                } catch {
                    print("❌ [unfriendTaskButton] Error unfriending user: \(error)")
                    appVM.handleError(error)
                }
            }
        }
    }
}

extension UserDetailView {
    var header: some View {
        GeometryReader { geometry in
            GradientOverlayImageView(
                imageUrl: user.imageUrl(.x1024),
                thumbnailImageUrl: user.imageUrl(.x256),
                size: CGSize(
                    width: max(geometry.size.width, 1),
                    height: max(headerHeight, 1)
                ),
                topContent: { topOverlay }
            )
        }
        .frame(height: headerHeight)
    }
    
    var userInfoSection: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight])
                    .fill(Color(.secondarySystemGroupedBackground))
                    //.shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            
            ZStack {
                Circle()
                    .fill(user.trustRank.color.opacity(0.25))
                    .frame(width: 120, height: 120)
                    .blur(radius: 12)
                    .offset(y: 6)
                
                UserIcon(
                    user: user,
                    size: CGSize(width: 104, height: 104),
                    showStatusIndicator: true,
                    showTrustRankBorder: true
                )
            }
            .offset(y: -60)

            VStack(spacing: 12) {
                Spacer().frame(height: 52)
                
                VStack(spacing: 4) {
                    Text(user.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)

                    Text(statusDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                badges
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 0)
        .padding(.bottom, 4)
    }

    var badges: some View {
        HStack(spacing: 10) {
            if user.vrcPlus.isSupporter {
                badgeView(icon: IconSet.vrcplus.icon, text: "VRC+", color: user.vrcPlus.color)
            }
            if let ageVerificationStatusLabel = user.ageVerification.ageVerificationStatusLabel {
                badgeView(icon: IconSet.ageVerification.icon, text: ageVerificationStatusLabel, color: user.ageVerification.ageVerificationStatus.color)
            }
            badgeView(icon: IconSet.shield.icon, text: user.trustRank.description, color: user.trustRank.color)
        }
    }

    func badgeView(icon: some View, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            icon.font(.caption)
            Text(text).font(.caption.bold())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(color.opacity(0.13))
                .overlay(
                    Capsule().stroke(color.opacity(0.35), lineWidth: 1)
                )
        )
        .foregroundStyle(color)
    }
}
