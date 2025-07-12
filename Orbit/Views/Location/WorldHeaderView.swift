//
//  WorldHeaderView.swift
//  Orbit
//
//  Created by NoriDev on 7/12/25.
//

import SwiftUI
import VRCKit

struct WorldHeaderView<Content: View>: View {
    let world: World
    @ViewBuilder let content: Content
    private let isRequesting: Bool
    
    init(world: World, @ViewBuilder content: () -> Content) {
        self.world = world
        self.content = content()
        self.isRequesting = false
    }
    
    init(redacted: Bool, world: World, @ViewBuilder content: () -> Content) {
        self.isRequesting = redacted
        self.world = world
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                GradientOverlayImageView(
                    imageUrl: world.imageUrl(.x512),
                    thumbnailImageUrl: world.imageUrl(.x256),
                    size: CGSize(width: 80, height: 65)
                )
                .frame(width: 80, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack {
                    HStack {
                        Spacer()
                        if !isRequesting {
                           PlatformIconView(platform: world.platform)
                        }
                    }
                    Spacer()
                }
                .frame(width: 80, height: 65)
                
                if isRequesting {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.regularMaterial)
                        .frame(width: 80, height: 65)
                    ProgressView().scaleEffect(0.8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(world.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                content
            }
            
            Spacer()
        }
        .redacted(reason: isRequesting ? .placeholder : [])
    }
}
