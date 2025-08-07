//
//  PDFFileService.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import Foundation
import UIKit
import PDFKit
import PencilKit

class PDFFileService {
    static let shared = PDFFileService()
    
    private let documentsDirectory: URL
    private let fileManager = FileManager.default
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func isPDFCached(for documentId: String) -> Bool {
        let pdfURL = getLocalPDFURL(for: documentId)
        return fileManager.fileExists(atPath: pdfURL.path)
    }
    
    func getLocalPDFURL(for documentId: String) -> URL {
        return documentsDirectory.appendingPathComponent("\(documentId).pdf")
    }
    
    func getLocalPDFWithDrawingsURL(for documentId: String) -> URL {
        return documentsDirectory.appendingPathComponent("\(documentId)_with_drawings.pdf")
    }
    
    func downloadPDF(for document: Document, completion: @escaping (Result<URL, Error>) -> Void) {
        let documentURLString = APIConfiguration.S3Endpoints.pdfDocument(document.id)
        guard let documentURL = URL(string: documentURLString) else {
            completion(.failure(PDFFileError.invalidURL))
            return
        }
        let localURL = getLocalPDFURL(for: document.id)
        let task = URLSession.shared.downloadTask(with: documentURL) { tempURL, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let tempURL = tempURL else {
                    completion(.failure(PDFFileError.noData))
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    guard httpResponse.statusCode == 200 else {
                        completion(.failure(PDFFileError.serverError(httpResponse.statusCode)))
                        return
                    }
                }
                do {
                    if self.fileManager.fileExists(atPath: localURL.path) {
                        try self.fileManager.removeItem(at: localURL)
                    }
                    try self.fileManager.moveItem(at: tempURL, to: localURL)
                    completion(.success(localURL))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    func getPDFURL(for document: Document, completion: @escaping (Result<URL, Error>) -> Void) {
        if isPDFCached(for: document.id) {
            let localURL = getLocalPDFURL(for: document.id)
            completion(.success(localURL))
        } else {
            downloadPDF(for: document, completion: completion)
        }
    }
    
    func savePDFWithDrawings(documentId: String, originalPDF: PDFDocument, drawings: [PKDrawing], completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let newDocument = PDFDocument()
                for i in 0..<originalPDF.pageCount {
                    guard let originalPage = originalPDF.page(at: i) else { continue }
                    let pageBounds = originalPage.bounds(for: .mediaBox)
                    UIGraphicsBeginImageContextWithOptions(pageBounds.size, false, 2.0)
                    guard let context = UIGraphicsGetCurrentContext() else { continue }
                    context.translateBy(x: 0, y: pageBounds.size.height)
                    context.scaleBy(x: 1.0, y: -1.0)
                    originalPage.draw(with: .mediaBox, to: context)
                    if i < drawings.count {
                        let drawing = drawings[i]
                        if !drawing.bounds.isEmpty {
                            let drawingImage = drawing.image(from: drawing.bounds, scale: 2.0)
                            drawingImage.draw(in: drawing.bounds)
                        }
                    }
                    let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    if let image = renderedImage {
                        let newPage = PDFPage(image: image)
                        newDocument.insert(newPage!, at: i)
                    }
                }
                let savedURL = self.getLocalPDFWithDrawingsURL(for: documentId)
                if self.fileManager.fileExists(atPath: savedURL.path) {
                    try self.fileManager.removeItem(at: savedURL)
                }
                newDocument.write(to: savedURL)
                DispatchQueue.main.async {
                    completion(.success(savedURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func clearCache() throws {
        let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        let pdfFiles = files.filter { $0.pathExtension == "pdf" }
        for file in pdfFiles {
            try fileManager.removeItem(at: file)
        }
    }
    
    func getCacheSize() -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.fileSizeKey])
            let pdfFiles = files.filter { $0.pathExtension == "pdf" }
            var totalSize: Int64 = 0
            for file in pdfFiles {
                let resourceValues = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
            return totalSize
        } catch {
            return 0
        }
    }
    
    func listCachedPDFs() -> [URL] {
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return files.filter { $0.pathExtension == "pdf" }
        } catch {
            return []
        }
    }
}

enum PDFFileError: Error, LocalizedError {
    case invalidURL
    case noData
    case serverError(Int)
    case fileNotFound
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .serverError(let code):
            return "Server error: HTTP \(code)"
        case .fileNotFound:
            return "File not found"
        }
    }
}