//
//  DocumentViewController.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import UIKit
import PDFKit
import PencilKit

class DocumentViewController: UIViewController, PDFDocumentDelegate {
    private let pdfView = PDFView()
    private let overlayProvider = CanvasProvider()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.isInMarkupMode = true
        pdfView.pageOverlayViewProvider = overlayProvider

        if let url = Bundle.main.url(forResource: "test", withExtension: "pdf"),
           let doc = PDFDocument(url: url) {
            doc.delegate = self
            pdfView.document = doc
        }
    }

    func classForPage() -> AnyClass {
        return CanvasPDFPage.self
    }
} 