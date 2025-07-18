//
//  GroupDetailView+HeaderSection.swift
//  Orbit
//
//  Created by NoriDev on 7/17/25.
//

import SwiftUI
import VRCKit

extension GroupDetailView {
    var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let bannerUrl = currentGroup.bannerUrl {
                AsyncImage(url: bannerUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 200)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
            }
            
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            
            HStack(spacing: 12) {
                if let iconUrl = currentGroup.iconUrl {
                    AsyncImage(url: iconUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(currentGroup.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if currentGroup.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(group.memberCount)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(Color(.systemGray6))
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
                            }
                        )
                        .clipShape(Capsule())
                        
                        Text("#\(currentGroup.shortCode).\(currentGroup.discriminator)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                ZStack {
                                    Capsule()
                                        .fill(Color(.systemGray6))
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                }
                            )
                            .lineLimit(1)
                    }
                    
                    ScrollView(.horizontal) {
                        HStack {
                            Text(privacyDisplayText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    ZStack {
                                        Capsule()
                                            .fill(Color(.systemGray6))
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                    }
                                )
                                .lineLimit(1)
                            
                            if let joinState = currentGroup.joinState {
                                Text(joinState.rawValue.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        ZStack {
                                            Capsule()
                                                .fill(Color.white)
                                            Capsule()
                                                .fill(Color.blue.opacity(0.1))
                                        }
                                    )
                                    .lineLimit(1)
                            }
                            
                            Text(currentGroup.memberVisibility.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    ZStack {
                                        Capsule()
                                            .fill(Color(.systemGray6))
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                    }
                                )
                                .lineLimit(1)
                            
                            if let isSubscribed = currentGroup.myMember?.isSubscribedToAnnouncements, isSubscribed == true {
                                Text("Subscribed")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        ZStack {
                                            Capsule()
                                                .fill(Color(.systemGray6))
                                            Capsule()
                                                .fill(Color.blue.opacity(0.1))
                                        }
                                    )
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    private var privacyDisplayText: String {
        switch currentGroup.privacy {
        case .private:
            return "Private"
        case .public, .default:
            return "Public"
        case .unknown:
            return "Unknown"
        }
    }
}
