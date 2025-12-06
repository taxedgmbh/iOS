//
//  AnnotatablePDFView.swift
//  TaxedGmbH_IOS
//
//  Interactive PDF viewer with rectangle annotation support
//  Wraps PDFKit in SwiftUI with touch handling for drawing
//

import SwiftUI
import PDFKit

/// SwiftUI wrapper for annotatable PDF viewing with drawing capabilities
struct AnnotatablePDFView: UIViewRepresentable {
    let pdfURL: URL
    @Binding var annotations: [PDFAnnotationRect]
    @Binding var isDrawingMode: Bool
    var onAnnotationAdded: ((PDFAnnotationRect) -> Void)?

    func makeUIView(context: Context) -> AnnotatablePDFUIView {
        let view = AnnotatablePDFUIView()
        view.coordinator = context.coordinator
        view.loadPDF(from: pdfURL)
        return view
    }

    func updateUIView(_ uiView: AnnotatablePDFUIView, context: Context) {
        uiView.isDrawingEnabled = isDrawingMode
        uiView.updateAnnotations(annotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: AnnotatablePDFView

        init(_ parent: AnnotatablePDFView) {
            self.parent = parent
        }

        func annotationAdded(_ annotation: PDFAnnotationRect) {
            parent.annotations.append(annotation)
            parent.onAnnotationAdded?(annotation)
        }
    }
}

// MARK: - UIKit PDF View with Annotation Support

class AnnotatablePDFUIView: UIView {
    private var pdfView: PDFView!
    var coordinator: AnnotatablePDFView.Coordinator?
    var isDrawingEnabled = false

    // Drawing state
    private var currentDrawStart: CGPoint?
    private var currentDrawRect: CGRect?
    private var drawingLayer: CAShapeLayer?
    private var annotationLayers: [String: CAShapeLayer] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPDFView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPDFView()
    }

    private func setupPDFView() {
        pdfView = PDFView(frame: bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        addSubview(pdfView)

        // Disable PDFView's built-in gestures when drawing
        pdfView.isUserInteractionEnabled = true
    }

    func loadPDF(from url: URL) {
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            pdfView.goToFirstPage(nil)
        }
    }

    func updateAnnotations(_ annotations: [PDFAnnotationRect]) {
        // Remove layers for deleted annotations
        let currentIDs = Set(annotations.map { $0.id })
        for (id, layer) in annotationLayers {
            if !currentIDs.contains(id) {
                layer.removeFromSuperlayer()
                annotationLayers.removeValue(forKey: id)
            }
        }

        // Add or update annotation layers
        for annotation in annotations {
            if annotationLayers[annotation.id] == nil {
                addAnnotationLayer(for: annotation)
            }
        }
    }

    private func addAnnotationLayer(for annotation: PDFAnnotationRect) {
        guard let page = pdfView.document?.page(at: annotation.page) else {
            return
        }

        // Convert normalized coordinates to view coordinates
        let pageBounds = page.bounds(for: .mediaBox)
        let rect = annotation.rect.toCGRect(pageBounds: pageBounds)

        // Convert PDF coordinates to view coordinates
        let viewRect = pdfView.convert(rect, from: page)

        // Create shape layer for the annotation
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(rect: viewRect).cgPath
        layer.strokeColor = UIColor(hex: annotation.color)?.cgColor ?? UIColor.red.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = annotation.strokeWidth
        layer.lineDashPattern = nil

        pdfView.layer.addSublayer(layer)
        annotationLayers[annotation.id] = layer
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingEnabled, let touch = touches.first else {
            super.touchesBegan(touches, with: event)
            return
        }

        let location = touch.location(in: self)
        currentDrawStart = location
        currentDrawRect = CGRect(origin: location, size: .zero)

        // Create temporary drawing layer
        drawingLayer = CAShapeLayer()
        drawingLayer?.strokeColor = UIColor(red: 227/255, green: 30/255, blue: 36/255, alpha: 1.0).cgColor
        drawingLayer?.fillColor = UIColor.clear.cgColor
        drawingLayer?.lineWidth = 2.0
        drawingLayer?.lineDashPattern = [5, 3]  // Dashed line while drawing
        layer.addSublayer(drawingLayer!)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingEnabled,
              let touch = touches.first,
              let startPoint = currentDrawStart else {
            super.touchesMoved(touches, with: event)
            return
        }

        let currentPoint = touch.location(in: self)
        let rect = CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )

        currentDrawRect = rect

        // Update drawing layer
        drawingLayer?.path = UIBezierPath(rect: rect).cgPath
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawingEnabled,
              let rect = currentDrawRect,
              rect.width > 10 && rect.height > 10,  // Minimum size threshold
              let page = pdfView.currentPage else {
            // Clean up if drawing was too small or invalid
            drawingLayer?.removeFromSuperlayer()
            drawingLayer = nil
            currentDrawStart = nil
            currentDrawRect = nil
            super.touchesEnded(touches, with: event)
            return
        }

        // Convert view rect to PDF page coordinates
        let pdfRect = pdfView.convert(rect, to: page)
        let pageBounds = page.bounds(for: .mediaBox)

        // Create normalized annotation
        let normalizedRect = NormalizedRect(from: pdfRect, pageBounds: pageBounds)
        let annotation = PDFAnnotationRect(
            page: pdfView.document!.index(for: page),
            rect: normalizedRect,
            color: "#E71E24",
            strokeWidth: 2.0
        )

        // Notify coordinator
        coordinator?.annotationAdded(annotation)

        // Clean up drawing layer
        drawingLayer?.removeFromSuperlayer()
        drawingLayer = nil
        currentDrawStart = nil
        currentDrawRect = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Clean up on cancel
        drawingLayer?.removeFromSuperlayer()
        drawingLayer = nil
        currentDrawStart = nil
        currentDrawRect = nil
        super.touchesCancelled(touches, with: event)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var annotations: [PDFAnnotationRect] = []
        @State private var isDrawing = true

        var body: some View {
            VStack {
                Text("Draw rectangles on PDF")
                    .font(.headline)

                if let url = Bundle.main.url(forResource: "sample", withExtension: "pdf") {
                    AnnotatablePDFView(
                        pdfURL: url,
                        annotations: $annotations,
                        isDrawingMode: $isDrawing,
                        onAnnotationAdded: { annotation in
                            print("Added annotation: \(annotation.id)")
                        }
                    )
                } else {
                    Text("No PDF available")
                }

                Toggle("Drawing Mode", isOn: $isDrawing)
                    .padding()
            }
        }
    }

    return PreviewWrapper()
}
