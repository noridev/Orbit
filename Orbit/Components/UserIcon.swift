//
//  UserIcon.swift
//  Orbit
//
//  Created by makinosp on 2024/09/20.
//

import MemberwiseInit
import SwiftUI
import VRCKit

@MemberwiseInit
struct UserIcon<T>: View where T: ProfileElementRepresentable {
    @Init(.internal) private let user: T
    @Init(.internal) private let size: CGSize
    @Init(.internal, default: true) private let showStatusIndicator: Bool
    @Init(.internal, default: true) private let showTrustRankBorder: Bool
    
    private var borderWidth: CGFloat {
        max(1, min(size.width * 0.07, 6))
    }

    private var userIconUrl: URL? {
        if let userIcon = user.userIcon {
            return userIcon
        }
        return user.imageUrl(.x256)
    }

    private var borderColor: Color {
        let uiColor = UIColor(user.trustRank.color)
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let newSaturation = saturation * 0.75
            return Color(UIColor(hue: hue, saturation: newSaturation, brightness: brightness, alpha: alpha))
        }
        
        return user.trustRank.color
    }

    var body: some View {
        let imageWithBorder = CircleURLImage(imageUrl: userIconUrl, size: size)
            .overlay {
                if showTrustRankBorder {
                    Circle()
                        .stroke(borderColor, lineWidth: borderWidth * 1.25)
                } else {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 1)
                }
            }
            .clipShape(Circle())

        ZStack {
            Circle()
                .fill(Color(.systemGray5).opacity(0.7))
                .frame(width: size.width, height: size.height)

            if showStatusIndicator {
                BittenView {
                    imageWithBorder
                }
                .overlay {
                    StatusIndicator(
                        user.status.color,
                        outerSize: size,
                        isCutOut: user.platform == .some(.web)
                    )
                }
            } else {
                imageWithBorder
            }
        }
    }
}
