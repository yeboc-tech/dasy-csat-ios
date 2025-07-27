//
//  CanvasProvider.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import PDFKit
import PencilKit

final class CanvasProvider: NSObject, PDFPageOverlayViewProvider {
    private var cache: [PDFPage: PKCanvasView] = [:]

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

        if let window = pdfView.window,
           let picker = PKToolPicker.shared(for: window) {
            picker.addObserver(canvas)
            picker.setVisible(true, forFirstResponder: canvas)
            
            // Force light mode for the tool picker
            if #available(iOS 13.0, *) {
                picker.overrideUserInterfaceStyle = .light
            }
            
            // Set the pen color to a specific black that won't adapt to appearance
            let blackColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
            let blackPen = PKInkingTool(.pen, color: blackColor, width: 1.0)
            picker.selectedTool = blackPen
            
            // Make the canvas the first responder to activate the tool
            canvas.becomeFirstResponder()
        }

        cache[page] = canvas
        return canvas
    }

    func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
        guard let canvas = overlayView as? PKCanvasView,
              let canvasPage = page as? CanvasPDFPage else { return }

        canvasPage.drawing = canvas.drawing
        cache.removeValue(forKey: page)
    }
} 