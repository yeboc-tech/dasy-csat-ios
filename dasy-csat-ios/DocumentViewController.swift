//
//  DocumentViewController.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import UIKit
import PDFKit
import PencilKit

class DocumentViewController: UIViewController, PDFDocumentDelegate, ToolbarViewDelegate, OMRMarkingViewDelegate {
    private let pdfView = PDFView()
    private let overlayProvider = CanvasProvider()
    private let toolbarView = ToolbarView()
    private let omrMarkingView = OMRMarkingView()
    
    private var currentCanvas: PKCanvasView?
    private var isInitialLoad = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupDelegates()
        loadPDF()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Re-scale PDF when view layout changes, but only if it's the initial load
        if pdfView.document != nil && isInitialLoad {
            scalePDFToFitWidth()
            goToFirstPage()
            isInitialLoad = false
        }
        
        // Ensure scroll view bounce configuration is maintained
        configureScrollViewForBounce()
    }
    
    private func setupUI() {
        // Add toolbar at the top
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbarView)
        
        // Add OMR marking view on the left
        omrMarkingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(omrMarkingView)
        
        // Add PDF view
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Toolbar at the top
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            // OMR marking view on the left
            omrMarkingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            omrMarkingView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            omrMarkingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // PDF view fills the remaining space
            pdfView.leadingAnchor.constraint(equalTo: omrMarkingView.trailingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.isInMarkupMode = true
        pdfView.backgroundColor = .white
        
        // Set initial scale factors - will be properly set after document loads
        pdfView.minScaleFactor = 0.1
        pdfView.maxScaleFactor = 4.0
        
        // Disable any PDFView-specific scroll restrictions
        pdfView.usePageViewController(false)
        
        // Set up the overlay provider with reference to this view controller
        overlayProvider.documentViewController = self
        pdfView.pageOverlayViewProvider = overlayProvider
        
        // Configure scroll view for proper bounce behavior
        configureScrollViewForBounce()
    }
    
    private func configureScrollViewForBounce() {
        // Find the underlying scroll view and configure it for bounce
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.alwaysBounceVertical = true
            scrollView.bounces = true
            scrollView.contentInsetAdjustmentBehavior = .automatic
        }
    }
    

    
    private func setupDelegates() {
        toolbarView.delegate = self
        omrMarkingView.delegate = self
    }
    
    private func loadPDF() {
        if let url = Bundle.main.url(forResource: "test", withExtension: "pdf"),
           let doc = PDFDocument(url: url) {
            doc.delegate = self
            pdfView.document = doc
            
            // Ensure PDF scales to fit width after document is loaded
            DispatchQueue.main.async { [weak self] in
                self?.scalePDFToFitWidth()
                if self?.isInitialLoad == true {
                    self?.goToFirstPage()
                    self?.isInitialLoad = false
                }
            }
        }
    }
    
    private func goToFirstPage() {
        // Go to the first page
        if let firstPage = pdfView.document?.page(at: 0) {
            pdfView.go(to: firstPage)
        }
        
        // Scroll to the very top by accessing the underlying scroll view
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let scrollView = self.pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                // Ensure scroll view is properly configured for bounce
                scrollView.alwaysBounceVertical = true
                scrollView.bounces = true
                scrollView.contentInsetAdjustmentBehavior = .automatic
                
                // Scroll to top with animation
                scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            }
        }
    }
    
    private func scalePDFToFitWidth() {
        // Force layout update
        pdfView.layoutIfNeeded()
        
        // Set scale to fit width
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        
        // Ensure minimum scale is set to fit width
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        
        // Auto-scale to fit
        pdfView.autoScales = true
        
        // Force another layout to ensure proper scaling
        pdfView.layoutIfNeeded()
    }

    func classForPage() -> AnyClass {
        return CanvasPDFPage.self
    }
    
    // MARK: - PDFDocumentDelegate
    
    func documentDidBeginDocumentFind(_ notification: Notification) {
        // Handle document find operations if needed
    }
    
    func documentDidEndDocumentFind(_ notification: Notification) {
        // Handle document find operations if needed
    }
    
    // MARK: - ToolbarViewDelegate
    
    func toolbarView(_ toolbarView: ToolbarView, didSelectTool tool: PKTool?) {
        // Apply the selected tool to the current canvas
        if let canvas = currentCanvas {
            if let tool = tool {
                canvas.tool = tool
                print("Tool applied to canvas: \(tool)")
            } else {
                // Clear action - clear the current canvas
                canvas.drawing = PKDrawing()
                print("Canvas cleared")
            }
        }
        
        // Also apply tool to all canvases in the overlay provider cache
        if let overlayProvider = pdfView.pageOverlayViewProvider as? CanvasProvider {
            for (_, canvas) in overlayProvider.cache {
                if let tool = tool {
                    canvas.tool = tool
                }
            }
        }
    }
    
    // MARK: - OMRMarkingViewDelegate
    
    func omrMarkingView(_ omrView: OMRMarkingView, didMarkQuestion questionNumber: Int, withAnswer answer: Int) {
        print("Question \(questionNumber) marked with answer \(answer)")
        // Here you can implement additional logic for OMR marking
        // For example, you could draw marks on the PDF or store the answers
    }
    
    // MARK: - Canvas Management
    
    func setCurrentCanvas(_ canvas: PKCanvasView) {
        currentCanvas = canvas
        if let tool = toolbarView.getCurrentTool() {
            canvas.tool = tool
        }
    }
} 
