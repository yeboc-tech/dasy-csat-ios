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
    
    // Properties to control visibility of UI elements
    private var isSaveButtonHidden = true
    private var isAutoGradingButtonHidden = true
    private var isOMRCardHidden = true
    
    weak var coordinator: AppCoordinator?
    var document: Document?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DEBUG: DocumentViewController viewDidLoad called")
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupDelegates()
        loadPDF()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG: DocumentViewController viewWillAppear called")
        // Hide navigation bar to merge with toolbar
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show navigation bar when leaving
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("DEBUG: DocumentViewController viewDidAppear called")
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
        toolbarView.delegate = self
        view.addSubview(toolbarView)
        
        // Add OMR marking view on the left (hidden by default)
        omrMarkingView.translatesAutoresizingMaskIntoConstraints = false
        omrMarkingView.isHidden = isOMRCardHidden
        view.addSubview(omrMarkingView)
        
        // Add PDF view
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Toolbar at the top (now includes navigation elements)
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            // OMR marking view on the left (hidden by default)
            omrMarkingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            omrMarkingView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            omrMarkingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // PDF view fills the remaining space (or full width when OMR is hidden)
            pdfView.leadingAnchor.constraint(equalTo: isOMRCardHidden ? view.leadingAnchor : omrMarkingView.trailingAnchor),
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
        omrMarkingView.delegate = self
    }
    
    private func loadPDF() {
        guard let document = document else {
            print("DEBUG: No document provided")
            showError("문서 정보가 없습니다.")
            return
        }
        PDFFileService.shared.getPDFURL(for: document) { [weak self] result in
            switch result {
            case .success(let url):
                print("DEBUG: Successfully loaded PDF from: \(url)")
                if let doc = PDFDocument(url: url) {
                    doc.delegate = self
                    self?.pdfView.document = doc
                    DispatchQueue.main.async {
                        self?.scalePDFToFitWidth()
                        if self?.isInitialLoad == true {
                            self?.goToFirstPage()
                            self?.isInitialLoad = false
                        }
                    }
                } else {
                    self?.showError("PDF 문서를 열 수 없습니다.")
                }
            case .failure(let error):
                print("DEBUG: Failed to load PDF: \(error)")
                self?.showError("PDF를 불러오는 데 실패했습니다: \(error.localizedDescription)")
            }
        }
    }
    
    private func goToFirstPage() {
        print("DEBUG: Going to first page")
        // Go to the first page
        if let firstPage = pdfView.document?.page(at: 0) {
            pdfView.go(to: firstPage)
            print("DEBUG: Successfully went to first page")
        } else {
            print("DEBUG: Failed to get first page")
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
                print("DEBUG: Scrolled to top")
            } else {
                print("DEBUG: Could not find scroll view")
            }
        }
    }
    
    private func scalePDFToFitWidth() {
        print("DEBUG: Scaling PDF to fit width")
        // Force layout update
        pdfView.layoutIfNeeded()
        
        // Set scale to fit width
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        print("DEBUG: Set scale factor to: \(pdfView.scaleFactor)")
        
        // Ensure minimum scale is set to fit width
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        print("DEBUG: Set min scale factor to: \(pdfView.minScaleFactor)")
        
        // Auto-scale to fit
        pdfView.autoScales = true
        
        // Force another layout to ensure proper scaling
        pdfView.layoutIfNeeded()
        print("DEBUG: PDF scaling completed")
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
        if let tool = tool {
            // Apply the selected tool to the current canvas
            if let canvas = currentCanvas {
                canvas.tool = tool
                print("Tool applied to canvas: \(tool)")
            }
            
            // Also apply tool to all canvases in the overlay provider cache
            if let overlayProvider = pdfView.pageOverlayViewProvider as? CanvasProvider {
                for (_, canvas) in overlayProvider.cache {
                    canvas.tool = tool
                }
            }
        } else {
            // Clear action - show confirmation dialog before clearing all drawings
            showClearConfirmationDialog()
        }
    }
    
    func toolbarViewDidTapBack(_ toolbarView: ToolbarView) {
        // Handle back button tap
        navigationController?.popViewController(animated: true)
    }
    
    func toolbarViewDidTapAutoGrading(_ toolbarView: ToolbarView) {
        performAutoGrading()
    }
    
    func toolbarViewDidTapSave(_ toolbarView: ToolbarView) {
        saveDrawingsToPDF()
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
    
    private func showClearConfirmationDialog() {
        let alert = UIAlertController(
            title: "모두 지우기",
            message: "모든 펜 입력과 OMR 답안을 지우시겠습니까? 이 작업은 되돌릴 수 없습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "지우기", style: .destructive) { _ in
            self.clearAllDrawings()
        })
        
        present(alert, animated: true)
    }
    
    private func clearAllDrawings() {
        print("Starting to clear all drawings...")
        
        // Clear all canvases in the cache
        if let overlayProvider = pdfView.pageOverlayViewProvider as? CanvasProvider {
            print("Clearing \(overlayProvider.cache.count) canvases from cache")
            for (_, canvas) in overlayProvider.cache {
                canvas.drawing = PKDrawing()
                print("Cleared canvas for page")
            }
        }
        
        // Clear all saved drawings from all pages
        if let document = pdfView.document {
            print("Clearing saved drawings from \(document.pageCount) pages")
            for i in 0..<document.pageCount {
                if let page = document.page(at: i) as? CanvasPDFPage {
                    page.drawing = nil
                    print("Cleared saved drawing from page \(i)")
                }
            }
        }
        
        // Clear current canvas
        if let canvas = currentCanvas {
            canvas.drawing = PKDrawing()
            print("Cleared current canvas")
        }
        
        // Clear OMR inputs
        omrMarkingView.clearAllMarks()
        print("Cleared all OMR inputs")
        
        // Force refresh of the PDF view to show cleared drawings
        pdfView.setNeedsDisplay()
        pdfView.layoutIfNeeded()
        
        // Also force refresh of all visible canvases
        if let overlayProvider = pdfView.pageOverlayViewProvider as? CanvasProvider {
            for (_, canvas) in overlayProvider.cache {
                canvas.setNeedsDisplay()
            }
        }
        
        print("All drawings and OMR inputs cleared from PDF")
    }
    
    // MARK: - Auto Grading
    
    private func performAutoGrading() {
        let answers = omrMarkingView.getMarkedAnswers()
        let gradingService = GradingService.shared
        
        if gradingService.isAllQuestionsAnswered(answers) {
            // All questions answered, proceed with grading
            performGradingAndUpdateOMR(answers: answers)
        } else {
            // Not all questions answered, show confirmation dialog
            showIncompleteGradingConfirmation(answers: answers)
        }
    }
    
    private func showIncompleteGradingConfirmation(answers: [Int: Int]) {
        let alert = UIAlertController(
            title: "채점 확인",
            message: "모든 문제를 풀지 않았습니다. 현재 상태로 채점하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "채점하기", style: .default) { _ in
            self.performGradingAndUpdateOMR(answers: answers)
        })
        
        present(alert, animated: true)
    }
    
    private func performGradingAndUpdateOMR(answers: [Int: Int]) {
        let gradingService = GradingService.shared
        let result = gradingService.gradeAnswers(answers)
        
        // Update OMR marking view with grading results
        omrMarkingView.showGradingResults(result: result)
    }
    
    // MARK: - Save Drawings to PDF
    
    private func saveDrawingsToPDF() {
        guard let document = pdfView.document else {
            showSaveErrorAlert(message: "PDF 문서를 찾을 수 없습니다.")
            return
        }
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: "저장 중...", message: "그림을 PDF에 저장하고 있습니다.", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Save all current drawings to the PDF pages first
            self?.saveAllDrawingsToPages()
            
            // Create a new PDF document with drawings burned in as annotations
            let newDocument = self?.createPDFWithAnnotations(from: document)
            
            if let newDocument = newDocument {
                // Save to Files app so user can access it
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let savedPDFURL = documentsPath.appendingPathComponent("test_with_drawings.pdf")
                
                // Write the new document with annotations to the Documents directory
                newDocument.write(to: savedPDFURL)
                
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        self?.showSaveSuccessAlertWithShare(savedURL: savedPDFURL)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        self?.showSaveErrorAlert(message: "PDF 생성 중 오류가 발생했습니다.")
                    }
                }
            }
        }
    }
    

    
    private func createPDFWithAnnotations(from originalDocument: PDFDocument) -> PDFDocument? {
        let newDocument = PDFDocument()
        
        for i in 0..<originalDocument.pageCount {
            guard let originalPage = originalDocument.page(at: i) as? CanvasPDFPage else { continue }
            
            // Create a new page with the same bounds
            let pageBounds = originalPage.bounds(for: .mediaBox)
            
            // Create a graphics context to render the page with drawings
            UIGraphicsBeginImageContextWithOptions(pageBounds.size, false, 2.0)
            guard let context = UIGraphicsGetCurrentContext() else { continue }
            
            // Flip the coordinate system to match PDF coordinates
            context.translateBy(x: 0, y: pageBounds.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            
            // Draw the original PDF page
            originalPage.draw(with: .mediaBox, to: context)
            
            // Draw the PKDrawing on top if it exists
            if let drawing = originalPage.drawing, !drawing.bounds.isEmpty {
                // Convert PKDrawing to image and draw it
                let drawingImage = drawing.image(from: drawing.bounds, scale: 2.0)
                drawingImage.draw(in: drawing.bounds)
            }
            
            // Get the rendered image
            let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let image = renderedImage {
                // Create a new PDF page from the rendered image
                let newPage = PDFPage(image: image)
                newDocument.insert(newPage!, at: i)
            }
        }
        
        return newDocument
    }
    
    private func saveAllDrawingsToPages() {
        guard let document = pdfView.document else { return }
        
        // Save drawings from all canvases in the cache
        if let overlayProvider = pdfView.pageOverlayViewProvider as? CanvasProvider {
            for (page, canvas) in overlayProvider.cache {
                if let canvasPage = page as? CanvasPDFPage {
                    canvasPage.drawing = canvas.drawing
                }
            }
        }
        
        // Also save drawings from all pages that might not be in cache
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) as? CanvasPDFPage {
                // If the page has a drawing but no canvas view, keep the drawing
                // If the page has a canvas view in cache, the drawing is already saved above
                if page.canvasView == nil && page.drawing != nil {
                    // Drawing is already saved, no action needed
                }
            }
        }
    }
    

    
    private func showSaveSuccessAlertWithShare(savedURL: URL) {
        let alert = UIAlertController(
            title: "저장 완료",
            message: "그림이 PDF에 성공적으로 저장되었습니다.\n파일을 저장하거나 공유하려면 아래 옵션을 선택하세요.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "파일 저장하기", style: .default) { _ in
            self.showShareSheet(for: savedURL)
        })
        
        alert.addAction(UIAlertAction(title: "확인", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showSaveSuccessAlert() {
        let alert = UIAlertController(
            title: "저장 완료",
            message: "그림이 PDF에 성공적으로 저장되었습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        present(alert, animated: true)
    }
    
    private func showShareSheet(for url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // For iPad, set the popover presentation
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    
    private func showSaveErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "저장 실패",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - Visibility Control Methods
    
    func setSaveButtonHidden(_ hidden: Bool) {
        isSaveButtonHidden = hidden
        toolbarView.setSaveButtonHidden(hidden)
    }
    
    func setAutoGradingButtonHidden(_ hidden: Bool) {
        isAutoGradingButtonHidden = hidden
        toolbarView.setAutoGradingButtonHidden(hidden)
    }
    
    func setOMRCardHidden(_ hidden: Bool) {
        isOMRCardHidden = hidden
        omrMarkingView.isHidden = hidden
        
        // Update PDF view constraints when OMR card visibility changes
        if let pdfLeadingConstraint = view.constraints.first(where: { 
            $0.firstItem === pdfView && $0.firstAttribute == .leading 
        }) {
            pdfLeadingConstraint.isActive = false
            view.removeConstraint(pdfLeadingConstraint)
        }
        
        let newLeadingConstraint = pdfView.leadingAnchor.constraint(
            equalTo: hidden ? view.leadingAnchor : omrMarkingView.trailingAnchor
        )
        newLeadingConstraint.isActive = true
        view.addConstraint(newLeadingConstraint)
        
        // Animate the change
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func getSaveButtonHidden() -> Bool {
        return isSaveButtonHidden
    }
    
    func getAutoGradingButtonHidden() -> Bool {
        return isAutoGradingButtonHidden
    }
    
    func getOMRCardHidden() -> Bool {
        return isOMRCardHidden
    }
} 
