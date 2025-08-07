import Foundation

// MARK: - Document Models
struct Document: Codable {
    let id: String
    let title: String
    let subject: String
    let category: String
    let examYear: Int
    let examMonth: Int
    let examType: String
    let selection: String
    let gradeLevel: String
    let filename: String
    let storagePath: String
    let createdAt: String
    let source: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, subject, category, selection, filename, source
        case examYear = "exam_year"
        case examMonth = "exam_month"
        case examType = "exam_type"
        case storagePath = "storage_path"
        case createdAt = "created_at"
        case gradeLevel = "grade_level"
    }
}

struct DocumentsResponse: Codable {
    let success: Bool
    let data: [Document]
    let count: Int
}

// MARK: - Filter Data Models
struct DocumentFilters {
    var gradeLevels: [String] = []
    var categories: [String] = []
    var examYears: [Int] = []
    var examMonths: [Int] = []
}

struct FilterResponse: Codable {
    let success: Bool
    let data: AvailableFilters
}

struct AvailableFilters: Codable {
    let gradeLevels: [String]
    let categories: [String]
    let examYears: [Int]
    let examMonths: [Int]
    
    enum CodingKeys: String, CodingKey {
        case gradeLevels = "grade_levels"
        case categories
        case examYears = "exam_years"
        case examMonths = "exam_months"
    }
}

// MARK: - Document Service
class DocumentService {
    static let shared = DocumentService()
    
    private init() {}
    
    // Fetch available filter options
    func fetchAvailableFilters() async throws -> AvailableFilters {
        guard let url = URL(string: APIConfiguration.Endpoints.availableFilters) else {
            throw URLError(.badURL)
        }
        
        print("🌐 Fetching available filters from: \(url)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check HTTP response status
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        // Debug: Print the raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Raw API response: \(responseString)")
        }
        
        let filterResponse = try JSONDecoder().decode(FilterResponse.self, from: data)
        return filterResponse.data
    }
    
    // Fetch filtered documents
    func fetchFilteredDocuments(filters: DocumentFilters) async throws -> [Document] {
        var components = URLComponents(string: APIConfiguration.Endpoints.filteredDocuments)!
        var queryItems: [URLQueryItem] = []
        
        print("🔍 API Debug - Filters being sent:")
        print("   Grade Levels: \(filters.gradeLevels)")
        print("   Categories: \(filters.categories)")
        print("   Years: \(filters.examYears)")
        print("   Months: \(filters.examMonths)")
        
        if !filters.gradeLevels.isEmpty {
            queryItems.append(URLQueryItem(name: "grade_levels", value: filters.gradeLevels.joined(separator: ",")))
        }
        
        if !filters.categories.isEmpty {
            queryItems.append(URLQueryItem(name: "categories", value: filters.categories.joined(separator: ",")))
        }
        
        if !filters.examYears.isEmpty {
            queryItems.append(URLQueryItem(name: "exam_years", value: filters.examYears.map(String.init).joined(separator: ",")))
        }
        
        if !filters.examMonths.isEmpty {
            queryItems.append(URLQueryItem(name: "exam_months", value: filters.examMonths.map(String.init).joined(separator: ",")))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        print("🌐 API URL: \(url)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check HTTP response status
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        let documentsResponse = try JSONDecoder().decode(DocumentsResponse.self, from: data)
        return documentsResponse.data
    }
} 