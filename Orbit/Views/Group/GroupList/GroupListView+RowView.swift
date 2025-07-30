//
//  GroupListView+RowView.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import SwiftUI
import VRCKit

struct GroupRowView: View {
    let group: VRCGroup
    let isRepresenting: Bool
    let isManagedGroup: Bool
    let isMutualGroup: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = group.iconUrl {
                AsyncImage(url: icon) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .padding(32)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                .frame(width: 80, height: 80)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
            } else {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 80, height: 80)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if group.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    if isRepresenting {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    if isManagedGroup {
                        Image(systemName: IconSet.shield.systemName)
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                    
                    if isMutualGroup {
                        Image(systemName: "person.2.circle.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                
                ScrollView(.horizontal) {
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
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                        
                        Text("#\(group.shortCode).\(group.discriminator)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule()).lineLimit(1)
                        
                        Spacer()
                    }
                }
                
                if let description = group.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
