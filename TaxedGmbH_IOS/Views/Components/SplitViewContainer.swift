//
//  SplitViewContainer.swift
//  TaxedGmbH_IOS
//
//  Responsive split-view container for PDF and properties panel
//  Adapts between 60/40 split (landscape) and stacked (portrait)
//

import SwiftUI

struct SplitViewContainer: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let leftContent: AnyView
    let rightContent: AnyView

    @State private var dividerPosition: CGFloat = 0.6  // 60% for left panel
    @State private var isDraggingDivider = false

    init<L: View, R: View>(@ViewBuilder left: () -> L, @ViewBuilder right: () -> R) {
        self.leftContent = AnyView(left())
        self.rightContent = AnyView(right())
    }

    var body: some View {
        GeometryReader { geometry in
            if shouldUseSplitView(geometry: geometry) {
                // Landscape/Wide: Side-by-side split view
                HStack(spacing: 0) {
                    // Left Panel (PDF Viewer) - 60%
                    leftContent
                        .frame(width: geometry.size.width * dividerPosition)
                        .clipped()

                    // Divider with drag handle
                    DividerView(isDragging: $isDraggingDivider)
                        .frame(width: 12)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDraggingDivider = true
                                    let newPosition = (geometry.size.width * dividerPosition + value.translation.width) / geometry.size.width
                                    // Constrain divider between 40% and 80%
                                    dividerPosition = min(max(newPosition, 0.4), 0.8)
                                }
                                .onEnded { _ in
                                    isDraggingDivider = false
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                        )

                    // Right Panel (Properties) - 40%
                    rightContent
                        .frame(width: geometry.size.width * (1 - dividerPosition) - 12)
                        .clipped()
                }
            } else {
                // Portrait/Compact: Stacked view with tabs
                VStack(spacing: 0) {
                    TabView {
                        leftContent
                            .tabItem {
                                Label("document.pdf".localized, systemImage: "doc.fill")
                            }

                        rightContent
                            .tabItem {
                                Label("document.properties".localized, systemImage: "info.circle.fill")
                            }
                    }
                }
            }
        }
    }

    private func shouldUseSplitView(geometry: GeometryProxy) -> Bool {
        // Use split view in landscape or on iPad
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return true // iPad
        }
        return geometry.size.width > geometry.size.height && geometry.size.width > 600
    }
}

// MARK: - Divider View

struct DividerView: View {
    @Binding var isDragging: Bool

    var body: some View {
        ZStack {
            // Background divider line
            Rectangle()
                .fill(Color(UIColor.separator))
                .frame(width: 1)

            // Drag handle
            VStack(spacing: 2) {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(isDragging ? Color(red: 227/255, green: 30/255, blue: 36/255) : Color(UIColor.tertiaryLabel))
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.vertical, 20)
            .background(
                Capsule()
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 20, height: 50)
                    .opacity(isDragging ? 1 : 0)
            )
            .animation(.easeInOut(duration: 0.2), value: isDragging)
        }
    }
}

// MARK: - Responsive Split View Wrapper

struct ResponsiveSplitView<PDFView: View, PropertiesView: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ViewBuilder let pdfView: () -> PDFView
    @ViewBuilder let propertiesView: () -> PropertiesView

    @State private var selectedTab = 0
    @State private var showPropertiesSheet = false

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 700 {
                // Wide layout: Split view
                SplitViewContainer(
                    left: { pdfView() },
                    right: { propertiesView() }
                )
            } else {
                // Narrow layout: PDF with floating properties button
                ZStack {
                    pdfView()

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()

                            // Floating properties button
                            Button(action: {
                                showPropertiesSheet = true
                            }) {
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        Circle()
                                            .fill(Color(red: 227/255, green: 30/255, blue: 36/255))
                                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    )
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .sheet(isPresented: $showPropertiesSheet) {
                    NavigationView {
                        propertiesView()
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("common.done".localized) {
                                        showPropertiesSheet = false
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}

#Preview("Split View") {
    SplitViewContainer(
        left: {
            ZStack {
                Color.blue.opacity(0.1)
                Text("PDF Viewer (60%)")
                    .font(.largeTitle)
            }
        },
        right: {
            ZStack {
                Color.green.opacity(0.1)
                Text("Properties Panel (40%)")
                    .font(.title)
            }
        }
    )
}

#Preview("Responsive View") {
    ResponsiveSplitView(
        pdfView: {
            ZStack {
                Color.blue.opacity(0.1)
                Text("PDF Content")
                    .font(.largeTitle)
            }
        },
        propertiesView: {
            List {
                Section("Properties") {
                    Text("Category: Income")
                    Text("Amount: CHF 5,000")
                    Text("Date: 2024")
                }
            }
        }
    )
}