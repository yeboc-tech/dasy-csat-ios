//
//  CanvasProvider.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import PDFKit
import PencilKit

final class CanvasProvider: NSObject, PDFPageOverlayViewProvider {
    var cache: [PDFPage: PKCanvasView] = [:]
    weak var documentViewController: DocumentViewController?

    func pdfView(_ pdfView: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        if let existing = cache[page] {
            return existing
        }

        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        
        // Force light mode for the canvas to ensure black pen
        if #available(iOS 13.0, *) {
            canvas.overrideUserInterfaceStyle = .light
        }

        // Restore saved drawing if it exists
        if let canvasPage = page as? CanvasPDFPage, let savedDrawing = canvasPage.drawing {
            canvas.drawing = savedDrawing
        }

        // Set up the canvas with the current tool from toolbar
        if let docVC = documentViewController {
            docVC.setCurrentCanvas(canvas)
        }

        cache[page] = canvas
        return canvas
    }

    func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
        guard let canvas = overlayView as? PKCanvasView,
              let canvasPage = page as? CanvasPDFPage else { return }

        // Save the drawing to the page
        canvasPage.drawing = canvas.drawing
        canvasPage.canvasView = nil // Clear the reference to avoid retain cycles
        cache.removeValue(forKey: page)
    }
} 