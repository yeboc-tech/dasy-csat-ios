//
//  CanvasPDFPage.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import PDFKit
import PencilKit

class CanvasPDFPage: PDFPage {
    var drawing: PKDrawing?
    weak var canvasView: PKCanvasView?
} 