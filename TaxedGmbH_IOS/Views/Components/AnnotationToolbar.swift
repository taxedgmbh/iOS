//
//  AnnotationToolbar.swift
//  TaxedGmbH_IOS
//
//  Toolbar for PDF annotation controls (draw, undo, clear)
//  Apple HIG compliant floating toolbar design
//

import SwiftUI

struct AnnotationToolbar: View {
    @Binding var isDrawingMode: Bool
    @Binding var annotations: [PDFAnnotationRect]
    var onUndo: (() -> Void)?
    var onClear: (() -> Void)?

    @State private var showClearConfirmation = false

    var body: some View {
        HStack(spacing: 0) {
            // Draw/View Toggle
            Button(action: {
                isDrawingMode.toggle()
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isDrawingMode ? "hand.draw.fill" : "hand.draw")
                        .font(.system(size: 16, weight: .medium))
                    Text(isDrawingMode ? "annotate.drawing".localized : "annotate.viewing".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(isDrawingMode ? Color(red: 227/255, green: 30/255, blue: 36/255) : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isDrawingMode ? Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.1) : Color(UIColor.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .frame(height: 24)
                .padding(.horizontal, 8)

            // Undo Button
            Button(action: {
                guard !annotations.isEmpty else { return }
                onUndo?()
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .medium))
                    Text("annotate.undo".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(annotations.isEmpty ? .secondary : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(annotations.isEmpty)

            Divider()
                .frame(height: 24)
                .padding(.horizontal, 8)

            // Clear All Button
            Button(action: {
                guard !annotations.isEmpty else { return }
                showClearConfirmation = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                    Text("annotate.clear".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(annotations.isEmpty ? .secondary : .red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(annotations.isEmpty)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .confirmationDialog(
            "annotate.clear_confirmation_title".localized,
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("annotate.clear_all".localized, role: .destructive) {
                onClear?()
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("annotate.clear_confirmation_message".localized)
        }
    }
}

// Compact variant for smaller spaces
struct CompactAnnotationToolbar: View {
    @Binding var isDrawingMode: Bool
    @Binding var annotations: [PDFAnnotationRect]
    var onUndo: (() -> Void)?
    var onClear: (() -> Void)?

    @State private var showClearConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Draw/View Toggle (Icon only)
            Button(action: {
                isDrawingMode.toggle()
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                Image(systemName: isDrawingMode ? "hand.draw.fill" : "hand.draw")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDrawingMode ? Color(red: 227/255, green: 30/255, blue: 36/255) : .primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isDrawingMode ? Color(red: 227/255, green: 30/255, blue: 36/255).opacity(0.1) : Color(UIColor.systemGray6))
                    )
            }
            .buttonStyle(PlainButtonStyle())

            // Undo Button
            Button(action: {
                guard !annotations.isEmpty else { return }
                onUndo?()
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(annotations.isEmpty ? .secondary : .primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(UIColor.systemGray6))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(annotations.isEmpty)

            // Clear All Button
            Button(action: {
                guard !annotations.isEmpty else { return }
                showClearConfirmation = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(annotations.isEmpty ? .secondary : .red)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(UIColor.systemGray6))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(annotations.isEmpty)
        }
        .padding(8)
        .background(
            Capsule()
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .confirmationDialog(
            "annotate.clear_confirmation_title".localized,
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("annotate.clear_all".localized, role: .destructive) {
                onClear?()
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("annotate.clear_confirmation_message".localized)
        }
    }
}

#Preview("Full Toolbar") {
    VStack(spacing: 40) {
        AnnotationToolbar(
            isDrawingMode: .constant(false),
            annotations: .constant([]),
            onUndo: { print("Undo") },
            onClear: { print("Clear") }
        )

        AnnotationToolbar(
            isDrawingMode: .constant(true),
            annotations: .constant([
                PDFAnnotationRect(page: 0, rect: NormalizedRect(x: 0.1, y: 0.1, width: 0.2, height: 0.1))
            ]),
            onUndo: { print("Undo") },
            onClear: { print("Clear") }
        )
    }
    .padding()
}

#Preview("Compact Toolbar") {
    VStack(spacing: 40) {
        CompactAnnotationToolbar(
            isDrawingMode: .constant(false),
            annotations: .constant([]),
            onUndo: { print("Undo") },
            onClear: { print("Clear") }
        )

        CompactAnnotationToolbar(
            isDrawingMode: .constant(true),
            annotations: .constant([
                PDFAnnotationRect(page: 0, rect: NormalizedRect(x: 0.1, y: 0.1, width: 0.2, height: 0.1))
            ]),
            onUndo: { print("Undo") },
            onClear: { print("Clear") }
        )
    }
    .padding()
}
