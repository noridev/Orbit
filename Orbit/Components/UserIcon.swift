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
    private let borderWidth: CGFloat = 3

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
        let imageWithBorder = CircleURLImage(imageUrl: user.imageUrl(.x256), size: size)
            .overlay {
                if showTrustRankBorder {
                    Circle()
                        .stroke(borderColor, lineWidth: borderWidth * 2)
                }
            }
            .clipShape(Circle())

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
