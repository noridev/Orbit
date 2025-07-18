//
//  GroupGalleryView.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

struct GroupGalleryView: View {
    let galleries: [GroupGallery]?
    
    var body: some View {
        if let galleries = galleries, !galleries.isEmpty {
            LazyVStack(spacing: 12) {
                ForEach(galleries) { gallery in
                    GroupBox {
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
                        .padding(.vertical, 6)
                    }
                    .groupBoxStyle(.card)
                }
            }
            .padding(.bottom, 32)
        } else {
            ContentUnavailableView {
                Label("갤러리가 없습니다", systemImage: "photo.on.rectangle")
                    .foregroundColor(.gray)
            } description: {
                Text("이 그룹에는 아직 갤러리가 없습니다")
            }
        }
    }
}
