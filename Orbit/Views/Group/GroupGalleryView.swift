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
    let galleries: [GroupGallery]?
    let groupId: String
    let isLoading: Bool

    private var placeholderGalleries: [GroupGallery] {
        (0..<3).map { i in
            GroupGallery(
                id: "placeholder_gal_\(i)",
                name: "Placeholder Gallery",
                description: "Loading gallery description...",
                membersOnly: false,
                roleIdsToView: nil,
                roleIdsToSubmit: nil,
                roleIdsToAutoApprove: nil,
                roleIdsToManage: nil,
                createdAt: nil,
                updatedAt: nil
            )
        }
    }

    var body: some View {
        let displayGalleries = isLoading ? placeholderGalleries : (galleries ?? [])
        let _ = reloadTrigger

        if !isLoading && displayGalleries.isEmpty {
            ContentUnavailableView {
                Label("갤러리가 없습니다", systemImage: "photo.on.rectangle")
                    .foregroundColor(.gray)
            } description: {
                Text("이 그룹에는 아직 갤러리가 없습니다")
            }
        } else {
            LazyVStack(spacing: 12) {
                ForEach(displayGalleries) { gallery in
                    GalleryRowView(
                        gallery: gallery,
                        groupId: groupId,
                        selectedImageURL: $selectedImageURL
                    )
                }
            }
            .id(reloadTrigger)
            .padding(.bottom, 32)
            .redacted(reason: isLoading ? .placeholder : [])
            .disabled(isLoading)
        }
    }
}

struct GalleryRowView: View {
    @Environment(AppViewModel.self) var appVM
    let gallery: GroupGallery
    let groupId: String
    @Binding var selectedImageURL: URL?

    @State private var images: [GroupGalleryImage] = []
    @State private var isLoadingImages = false
    
    private var placeholderImages: [GroupGalleryImage] {
        (0..<5).map { i in
            GroupGalleryImage(
                id: "placeholder_img_\(i)",
                groupId: "grp_placeholder",
                galleryId: "ggal_placeholder",
                fileId: "file_placeholder",
                imageUrl: URL(string: "https://placehold.co/100x100")!,
                createdAt: Date(),
                submittedByUserId: "usr_placeholder",
                approved: nil,
                approvedByUserId: nil,
                approvedAt: nil
            )
        }
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gallery.name)
                            .font(.headline)
                            .fontWeight(.medium)
                        if let desc = gallery.description, !desc.isEmpty {
                            Text(desc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 6)

                let displayImages = isLoadingImages ? placeholderImages : images

                if !displayImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(displayImages) { image in
                                Button {
                                    if !isLoadingImages {
                                        selectedImageURL = image.imageUrl
                                    }
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
                        }
                    }
                    .redacted(reason: isLoadingImages ? .placeholder : [])
                    .disabled(isLoadingImages)
                } else if !isLoadingImages && images.isEmpty {
                    Text("This gallery has no images.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .groupBoxStyle(.card)
        .onAppear {
            if images.isEmpty && !isLoadingImages {
                fetchImages()
            }
        }
    }

    private func fetchImages() {
        isLoadingImages = true
        Task {
            do {
                let fetchedImages = try await appVM.services.groupService.fetchGroupGalleryImages(
                    groupId: groupId,
                    galleryId: gallery.id
                )
                await MainActor.run {
                    self.images = fetchedImages
                    self.isLoadingImages = false
                }
            } catch {
                print("Failed to fetch gallery images for galleryId \(gallery.id): \(error)")
                await MainActor.run {
                    self.isLoadingImages = false
                }
            }
        }
    }
}
