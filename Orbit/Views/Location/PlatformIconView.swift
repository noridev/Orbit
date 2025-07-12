//
//  PlatformIconView.swift
//  Orbit
//
//  Created by NoriDev on 7/12/25.
//

import SwiftUI
import VRCKit

struct PlatformIconView: View {
    let platform: VRCKit.World.Platform

    var body: some View {
        Image(systemName: platform == .windows ? "pc" : IconSet.platform.systemName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(4)
            .frame(width: 20, height: 20, alignment: .center)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 8,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 8
                )
                .fill(Color.black.opacity(0.3))
            )
    }
}
