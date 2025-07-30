//
//  GroupGalleryView.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

struct GroupGalleryView: View {
    @Binding var selectedImageURL: URL?
    @Binding var reloadTrigger: Bool
    @State private var isLoading = true
    let galleries: [GroupGallery]?
    let groupId: String

    var body: some View {
        let displayGalleries = galleries ?? []
        let _ = reloadTrigger

        Group {
            if displayGalleries.isEmpty && !isLoading {
                ContentUnavailableView {
                    Label("갤러리가 없습니다", systemImage: "photo.on.rectangle")
                        .foregroundColor(.gray)
                } description: {
                    Text("이 그룹에는 아직 갤러리가 없습니다")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(displayGalleries) { gallery in
                            GalleryRowView(selectedImageURL: $selectedImageURL, gallery: gallery, groupId: groupId, scrollProxy: nil, isLoading: isLoading)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .refreshable { reloadTrigger.toggle() }
                .redacted(reason: isLoading ? .placeholder : [])
            }
        }
        .task {
            isLoading = true
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLoading = false
        }

        .onChange(of: reloadTrigger) {
            isLoading = true
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                isLoading = false
            }
        }
    }
}

struct GalleryRowView: View {
    @Environment(AppViewModel.self) var appVM
    @Binding var selectedImageURL: URL?
    @State private var images: [GroupGalleryImage] = []
    let gallery: GroupGallery
    let groupId: String
    let scrollProxy: ScrollViewProxy?
    let isLoading: Bool

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gallery.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let createdAt = gallery.createdAt {
                            Text("\(createdAt.formatted(date: .numeric, time: .shortened)) (\(relativeTimeString(from: createdAt)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if gallery.membersOnly {
                            HStack {
                                HStack(spacing: 2) {
                                    Image(systemName: IconSet.newFriend.systemName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("멤버 전용")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .padding(.top, 2)
                        }
                    }
                    Spacer()
                }
                
                if let description = gallery.description {
                    VStack(alignment: .leading, spacing: 8) {
                        ShowMoreText(
                            text: description,
                            lineLimit: 3,
                            scrollProxy: scrollProxy,
                            scrollTargetId: gallery.id
                        )
                        .font(.body)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if !images.isEmpty {
                            ForEach(images) { image in
                                Button {
                                    selectedImageURL = image.imageUrl
                                } label: {
                                    AsyncImage(url: image.imageUrl) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable()
                                                 .aspectRatio(contentMode: .fill)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .foregroundColor(.secondary)
                                        case .empty:
                                            ProgressView()
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        } else if !isLoading {
                            Text("이 갤러리에는 이미지가 없습니다")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .groupBoxStyle(.card)
        .onAppear {
            if images.isEmpty {
                fetchImages()
            }
        }
        .onChange(of: isLoading) { _, newValue in
            if newValue && images.isEmpty {
                fetchImages()
            }
        }
    }
    
    private func fetchImages() {
        Task {
            do {
                let fetchedImages = try await appVM.services.groupService.fetchGroupGalleryImages(
                    groupId: groupId,
                    galleryId: gallery.id
                )
                await MainActor.run {
                    self.images = fetchedImages
                }
            } catch {
                print("Failed to fetch gallery images for galleryId \(gallery.id): \(error)")
            }
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
