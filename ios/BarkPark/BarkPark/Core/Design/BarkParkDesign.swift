//
//  BarkParkDesign.swift
//  BarkPark
//
//  Apple-style design system for BarkPark
//

import SwiftUI

struct BarkParkDesign {
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let accent = Color.accentColor
        
        // Background colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        static let surface = Color(.secondarySystemBackground)
        
        // Text colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(.tertiaryLabel)
        
        // Background colors
        static let cardBackground = Color(.secondarySystemBackground)
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Custom colors
        static let dogPrimary = Color.orange
        static let dogSecondary = Color.brown
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let large = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions
extension View {
    func barkParkShadow(_ shadow: Shadow = BarkParkDesign.Shadows.medium) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func barkParkCard() -> some View {
        self
            .background(BarkParkDesign.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
            .barkParkShadow()
    }
    
    func barkParkButton() -> some View {
        self
            .font(BarkParkDesign.Typography.headline)
            .foregroundColor(.white)
            .padding(BarkParkDesign.Spacing.md)
            .background(BarkParkDesign.Colors.dogPrimary)
            .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
    }
    
    func barkParkSecondaryButton() -> some View {
        self
            .font(BarkParkDesign.Typography.headline)
            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
            .padding(BarkParkDesign.Spacing.md)
            .background(BarkParkDesign.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium)
                    .stroke(BarkParkDesign.Colors.dogPrimary, lineWidth: 1)
            )
    }
}