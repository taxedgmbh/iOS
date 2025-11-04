//
//  CustomizableCategoryCard.swift
//  TaxedGmbH_IOS
//
//  Customizable category card for dashboard with edit mode
//

import SwiftUI

struct CustomizableCategoryCard: View {
    let categoryType: TaxCategoryType
    let documentCount: Int
    var isEditMode: Bool = false
    var onRemove: (() -> Void)?

    @State private var isPressed = false
    @State private var wiggleRotation: Double = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main card content with wiggle animation
            VStack(spacing: 12) {
                // Category icon with background
                ZStack {
                    Circle()
                        .fill(categoryType.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: categoryType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(categoryType.color)
                }
                .overlay(
                    // Document count badge
                    documentCount > 0 ?
                    Text("\(documentCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(categoryType.color)
                        .clipShape(Circle())
                        .offset(x: 20, y: -20)
                    : nil
                )

                // Category name
                VStack(spacing: 4) {
                    Text(categoryType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(documentCount) \(documentCount == 1 ? "document" : "documents")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(categoryType.color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            // Apply subtle wiggle animation only to the card content (Apple-style)
            .rotationEffect(
                .degrees(isEditMode ? sin(Date().timeIntervalSinceReferenceDate * 5) * 1.2 : 0),
                anchor: .center
            )
            .animation(
                isEditMode ? Animation
                    .easeInOut(duration: 0.12)
                    .repeatForever(autoreverses: true)
                : .default,
                value: isEditMode
            )

            // Delete button in edit mode (static, no animation)
            if isEditMode {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onRemove?()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 22, height: 22)

                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 8, y: -8)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1) // Ensure button stays on top
            }
        }
        .onTapGesture {
            if !isEditMode {
                // Navigate to category detail or filter documents
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Category Card") {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            CustomizableCategoryCard(
                categoryType: .salary,
                documentCount: 3,
                isEditMode: false
            )
            CustomizableCategoryCard(
                categoryType: .mortgage,
                documentCount: 0,
                isEditMode: false
            )
        }

        HStack(spacing: 16) {
            CustomizableCategoryCard(
                categoryType: .pillar3a,
                documentCount: 1,
                isEditMode: true
            )
            CustomizableCategoryCard(
                categoryType: .crypto,
                documentCount: 5,
                isEditMode: true
            )
        }
    }
    .padding()
}