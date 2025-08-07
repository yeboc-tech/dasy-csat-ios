//
//  APIConfiguration.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import Foundation

/// Centralized configuration for all API endpoints and base URLs
/// 
/// SECURITY NOTE: 
/// - Base URLs are public and safe to expose
/// - No API keys or sensitive credentials are stored here
/// - All endpoints use HTTPS for secure communication
struct APIConfiguration {
    
    // MARK: - Base URLs (Public - Safe to expose)
    
    /// Main API server base URL
    /// This is a public API endpoint designed for client access
    static let apiBaseURL = "https://api.dasy-csat.y3c.kr"
    
    /// AWS S3 base URL for file storage
    /// This is a public S3 bucket for educational content
    static let s3BaseURL = "https://dasy-csat.s3.ap-northeast-2.amazonaws.com"
    
    // MARK: - API Endpoints
    
    struct Endpoints {
        /// Get available filter options
        static let availableFilters = "\(apiBaseURL)/documents/filters/available"
        
        /// Get filtered documents
        static let filteredDocuments = "\(apiBaseURL)/documents/filtered"
        
        /// Get all documents
        static let allDocuments = "\(apiBaseURL)/documents"
        
        /// Get documents by category
        static func documentsByCategory(_ category: String) -> String {
            return "\(apiBaseURL)/documents/category/\(category)"
        }
        
        /// Get documents by subject
        static func documentsBySubject(_ subject: String) -> String {
            return "\(apiBaseURL)/documents/subject/\(subject)"
        }
        
        /// Get document by ID
        static func documentById(_ id: String) -> String {
            return "\(apiBaseURL)/documents/\(id)"
        }
        
        /// Get available categories
        static let availableCategories = "\(apiBaseURL)/documents/categories/list"
        
        /// Get available subjects
        static let availableSubjects = "\(apiBaseURL)/documents/subjects/list"
    }
    
    // MARK: - S3 File URLs
    
    struct S3Endpoints {
        /// Get PDF document URL
        static func pdfDocument(_ documentId: String) -> String {
            return "\(s3BaseURL)/documents/\(documentId).pdf"
        }
        
        /// Get thumbnail URL
        static func thumbnail(_ documentId: String) -> String {
            return "\(s3BaseURL)/thumbnails/\(documentId).png"
        }
    }
    
    // MARK: - Environment Configuration
    
    /// Current environment configuration
    /// 
    /// SECURITY: Development URLs are removed from production builds
    enum Environment {
        case development
        case staging
        case production
        
        /// Get the appropriate base URL for the current environment
        var apiBaseURL: String {
            switch self {
            case .development:
                // Development URLs should be configured via build settings
                // or environment variables in production builds
                fatalError("Development environment not configured for production builds")
            case .staging:
                return "https://staging-api.dasy-csat.com" // Replace with actual staging URL
            case .production:
                return "https://api.dasy-csat.y3c.kr" // Your actual production API
            }
        }
        
        var s3BaseURL: String {
            // S3 URL remains the same across environments
            return "https://dasy-csat.s3.ap-northeast-2.amazonaws.com"
        }
    }
    
    /// Current environment (can be changed based on build configuration)
    static let currentEnvironment: Environment = .production
}

// MARK: - Convenience Extensions

extension APIConfiguration {
    /// Get the current API base URL based on environment
    static var currentAPIBaseURL: String {
        return currentEnvironment.apiBaseURL
    }
    
    /// Get the current S3 base URL based on environment
    static var currentS3BaseURL: String {
        return currentEnvironment.s3BaseURL
    }
} 