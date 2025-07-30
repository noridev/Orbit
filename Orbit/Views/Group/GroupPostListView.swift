//
//  GroupPostListView.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

struct GroupPostListView: View {
    @Environment(AppViewModel.self) var appVM
    @Binding var selectedImageURL: URL?
    @Binding var reloadTrigger: Bool
    @State private var posts: [GroupPost] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    let groupId: String

    private var placeholderPosts: [GroupPost] {
        (0..<6).map { i in
            GroupPost(
                id: "placeholder_\(i)",
                groupId: "grp_placeholder",
                authorId: "usr_placeholder",
                editorId: nil,
                visibility: "public",
                roleId: ["role_placeholder"],
                title: "Placeholder Title",
                text: "This is a placeholder text for the post content. Loading...",
                imageId: nil,
                imageUrl: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
    
    var body: some View {
        let displayPosts = isLoading ? placeholderPosts : posts
        
        Group {
            if !isLoading && displayPosts.isEmpty {
                ContentUnavailableView {
                    Label("포스트가 없습니다", systemImage: "doc.text")
                        .foregroundColor(.gray)
                } description: {
                    Text("이 그룹에는 아직 포스트가 없습니다")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(displayPosts) { post in
                            PostCardView(post: post, selectedImageURL: $selectedImageURL, scrollProxy: nil)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .refreshable {
                    loadPosts(force: true)
                    reloadTrigger.toggle()
                }
                .redacted(reason: isLoading ? .placeholder : [])
            }
        }
        .onAppear { loadPosts() }
        .onChange(of: reloadTrigger) { loadPosts(force: true) }
    }
    
    private func loadPosts(force: Bool = false) {
        if !force {
            guard posts.isEmpty, !isLoading else { return }
        }
        isLoading = true
        error = nil
        Task {
            do {
                let result = try await appVM.services.groupService.fetchGroupPosts(groupId: groupId)
                await MainActor.run {
                    self.posts = result
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
}

struct PostCardView: View {
    let post: GroupPost
    @Binding var selectedImageURL: URL?
    @State private var authorUser: UserDetail?
    @State private var isLoadingAuthor = false
    @Environment(AppViewModel.self) var appVM
    let scrollProxy: ScrollViewProxy?
    
    init(post: GroupPost, selectedImageURL: Binding<URL?>, scrollProxy: ScrollViewProxy?) {
        self.post = post
        self._selectedImageURL = selectedImageURL
        self.scrollProxy = scrollProxy
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let createdAt = post.createdAt {
                            Text("\(createdAt.formatted(date: .numeric, time: .shortened)) (\(relativeTimeString(from: createdAt)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            if let visibility = post.visibility {
                                Text(visibility.capitalized)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                            
                            if let roleId = post.roleId, !roleId.isEmpty {
                                Text("\(roleId.joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 2)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ShowMoreText(
                        text: post.content,
                        lineLimit: 3,
                        scrollProxy: scrollProxy,
                        scrollTargetId: post.id
                    )
                    .font(.body)
                }
                
                if let images = post.images, !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(images, id: \.self) { url in
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        )
                                }
                                .frame(width: 120, height: 120)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                                )
                                .onTapGesture {
                                    selectedImageURL = url
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                Divider()
                
                HStack(spacing: 8) {
                    authorInfoView
                    Spacer()
                }
            }
        }
        .groupBoxStyle(.card)
        .onAppear {
            loadAuthorInfo()
        }
    }
    
    @ViewBuilder
    private var authorInfoView: some View {
        if let authorUser = authorUser {
            NavigationLink(destination: UserDetailPresentationView(id: authorUser.id)) {
                HStack(spacing: 8) {
                    UserIcon(
                        user: authorUser,
                        size: CGSize(width: 24, height: 24),
                        showStatusIndicator: false,
                        showTrustRankBorder: false
                    )
                    Text(authorUser.displayName)
                        .font(.subheadline)
                }
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                Text(authorUser?.displayName ?? post.authorId)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .redacted(reason: isLoadingAuthor ? .placeholder : [])
        }
    }
    
    private func loadAuthorInfo() {
        guard authorUser == nil, !isLoadingAuthor else { return }
        
        isLoadingAuthor = true
        Task {
            do {
                let user = try await appVM.services.userService.fetchUser(userId: post.authorId)
                await MainActor.run {
                    self.authorUser = user
                    self.isLoadingAuthor = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingAuthor = false
                }
                print("❌ [PostCardView] Failed to fetch author info: \(error)")
            }
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ImageViewer: View {
    let imageUrl: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                },
                            DragGesture()
                                .onChanged { value in
                                    let delta = CGSize(
                                        width: value.translation.width - lastOffset.width,
                                        height: value.translation.height - lastOffset.height
                                    )
                                    lastOffset = value.translation
                                    offset = CGSize(
                                        width: offset.width + delta.width,
                                        height: offset.height + delta.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = .zero
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if scale > 1 {
                                scale = 1
                                offset = .zero
                            } else {
                                scale = 2
                            }
                        }
                    }
            } placeholder: {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}
