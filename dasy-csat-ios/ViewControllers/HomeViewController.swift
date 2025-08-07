import UIKit
import PDFKit

// MARK: - Filter Types
enum GradeFilter: String, CaseIterable {
    case 고1 = "고1"
    case 고2 = "고2"
    case 고3 = "고3"
}

enum SubjectFilter: String, CaseIterable {
    case 국어 = "국어"
    case 수학 = "수학"
    case 영어 = "영어"
    case 한국사 = "한국사"
    case 사회탐구 = "사회탐구"
    case 과학탐구 = "과학탐구"
    case 직업탐구 = "직업탐구"
    case 제2외국어 = "제2외국어"
}

enum MonthFilter: String, CaseIterable {
    case 월3 = "3월"
    case 월4 = "4월"
    case 월5 = "5월"
    case 월6 = "6월"
    case 월7 = "7월"
    case 월9 = "9월"
    case 월10 = "10월"
    case 월11 = "11월"
}

enum YearFilter: String, CaseIterable {
    case year2024 = "2024"
    case year2023 = "2023"
    case year2022 = "2022"
    case year2021 = "2021"
    case year2020 = "2020"
}

class HomeViewController: UIViewController {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let filterPanel: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let filterPanelBorder: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let contentPanel: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let filterScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let filterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 24, right: 24)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Data
    private var filteredDocuments: [Document] = []
    private var isLoading = false
    
    // MARK: - Filter States
    private var currentFilters = DocumentFilters()
    private var availableFilters: AvailableFilters?
    private var filterButtons: [String: UIButton] = [:]
    
    // MARK: - Constraints
    private var filterScrollViewTopConstraint: NSLayoutConstraint?
    private var collectionViewTopConstraint: NSLayoutConstraint?
    
    weak var coordinator: AppCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupFilters()
        fetchDocuments()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTopPadding()
    }
    
    private func updateTopPadding() {
        let topInset = view.safeAreaInsets.top
        if topInset > 0 {
            // Update filter scroll view top constraint to account for safe area
            // Add extra padding (20) to the safe area top inset
            filterScrollViewTopConstraint?.constant = topInset + 20
            
            // Set collection view content insets to account for status bar
            // Much smaller top padding to align with filter panel content
            collectionView.contentInset = UIEdgeInsets(top: topInset - 8, left: 0, bottom: 0, right: 0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(containerView)
        containerView.addSubview(filterPanel)
        filterPanel.addSubview(filterPanelBorder)
        containerView.addSubview(contentPanel)
        
        filterPanel.addSubview(filterScrollView)
        filterScrollView.addSubview(filterStackView)
        
        contentPanel.addSubview(collectionView)
        contentPanel.addSubview(loadingIndicator)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TestPreviewCell.self, forCellWithReuseIdentifier: "TestPreviewCell")
    }
    
    private func setupConstraints() {
        // Set up the filter scroll view top constraint separately
        filterScrollViewTopConstraint = filterScrollView.topAnchor.constraint(equalTo: filterPanel.topAnchor, constant: 20)
        
        // Set up the collection view top constraint separately - starts from very top
        collectionViewTopConstraint = collectionView.topAnchor.constraint(equalTo: contentPanel.topAnchor)
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Filter panel (left side - fixed width of 280) - extends to very top
            filterPanel.topAnchor.constraint(equalTo: containerView.topAnchor),
            filterPanel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            filterPanel.widthAnchor.constraint(equalToConstant: 280),
            filterPanel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Content panel (right side - fills remaining space)
            contentPanel.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentPanel.leadingAnchor.constraint(equalTo: filterPanel.trailingAnchor),
            contentPanel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentPanel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Filter panel border
            filterPanelBorder.topAnchor.constraint(equalTo: filterPanel.topAnchor),
            filterPanelBorder.trailingAnchor.constraint(equalTo: filterPanel.trailingAnchor),
            filterPanelBorder.bottomAnchor.constraint(equalTo: filterPanel.bottomAnchor),
            filterPanelBorder.widthAnchor.constraint(equalToConstant: 1),
            
            // Filter scroll view - with dynamic top padding for status bar
            filterScrollViewTopConstraint!,
            filterScrollView.leadingAnchor.constraint(equalTo: filterPanel.leadingAnchor, constant: 16),
            filterScrollView.trailingAnchor.constraint(equalTo: filterPanel.trailingAnchor, constant: -16),
            filterScrollView.bottomAnchor.constraint(equalTo: filterPanel.bottomAnchor, constant: -20),
            
            // Filter stack view
            filterStackView.topAnchor.constraint(equalTo: filterScrollView.topAnchor),
            filterStackView.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor),
            filterStackView.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor),
            filterStackView.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor),
            filterStackView.widthAnchor.constraint(equalTo: filterScrollView.widthAnchor),
            
            // Collection view
            collectionViewTopConstraint!,
            collectionView.leadingAnchor.constraint(equalTo: contentPanel.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentPanel.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentPanel.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: contentPanel.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentPanel.centerYAnchor)
        ])
    }
    
    private func setupFilters() {
        // Load available filters from API
        Task {
            await loadAvailableFilters()
        }
    }
    
    private func loadAvailableFilters() async {
        do {
            availableFilters = try await DocumentService.shared.fetchAvailableFilters()
            
            await MainActor.run {
                setupFilterSections()
            }
        } catch {
            print("Error loading available filters: \(error)")
            print("Falling back to hardcoded filters")
            // Fallback to hardcoded filters if API fails
            await MainActor.run {
                setupFallbackFilters()
            }
        }
    }
    
    private func setupFilterSections() {
        guard let availableFilters = availableFilters else { return }
        
        // Clear existing filter sections
        filterStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 학년 (Grade) Filter
        let gradeSection = createFilterSection(title: "학년", options: availableFilters.gradeLevels)
        filterStackView.addArrangedSubview(gradeSection)
        
        // 카테고리 (Category) Filter
        let categorySection = createFilterSection(title: "카테고리", options: availableFilters.categories)
        filterStackView.addArrangedSubview(categorySection)
        
        // 시행 연도 (Year) Filter
        let yearSection = createFilterSection(title: "시행 연도", options: availableFilters.examYears.map(String.init))
        filterStackView.addArrangedSubview(yearSection)
        
        // 시행 월 (Month) Filter
        let monthSection = createFilterSection(title: "시행 월", options: availableFilters.examMonths.map { "\($0)월" })
        filterStackView.addArrangedSubview(monthSection)
    }
    
    private func setupFallbackFilters() {
        // Fallback to hardcoded filters if API fails
        let gradeSection = createFilterSection(title: "학년", options: GradeFilter.allCases.map { $0.rawValue })
        filterStackView.addArrangedSubview(gradeSection)
        
        let subjectSection = createFilterSection(title: "영역", options: SubjectFilter.allCases.map { $0.rawValue })
        filterStackView.addArrangedSubview(subjectSection)
        
        let monthSection = createFilterSection(title: "시행 월", options: MonthFilter.allCases.map { $0.rawValue })
        filterStackView.addArrangedSubview(monthSection)
        
        let yearSection = createFilterSection(title: "시행 연도", options: YearFilter.allCases.map { $0.rawValue })
        filterStackView.addArrangedSubview(yearSection)
    }
    
    private func createFilterSection(title: String, options: [String]) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonContainerView = UIView()
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create buttons with flex row and wrap layout
        var currentRow: UIStackView?
        var currentRowWidth: CGFloat = 0
        let maxRowWidth: CGFloat = 248 // 280 - 32 (left and right margins)
        let buttonSpacing: CGFloat = 8
        let buttonHeight: CGFloat = 32
        
        for option in options {
            let button = createFilterButton(title: option)
            button.translatesAutoresizingMaskIntoConstraints = false
            
            // Calculate button width based on text
            let buttonWidth = calculateButtonWidth(for: option)
            
            // Check if we need a new row
            if currentRow == nil || (currentRowWidth + buttonWidth + buttonSpacing) > maxRowWidth {
                // Create new row
                currentRow = UIStackView()
                currentRow?.axis = .horizontal
                currentRow?.spacing = buttonSpacing
                currentRow?.alignment = .top
                currentRow?.translatesAutoresizingMaskIntoConstraints = false
                buttonContainerView.addSubview(currentRow!)
                
                // Position the new row
                if let previousRow = buttonContainerView.subviews.dropLast().last {
                    currentRow?.topAnchor.constraint(equalTo: previousRow.bottomAnchor, constant: 8).isActive = true
                } else {
                    currentRow?.topAnchor.constraint(equalTo: buttonContainerView.topAnchor).isActive = true
                }
                currentRow?.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor).isActive = true
                currentRow?.trailingAnchor.constraint(lessThanOrEqualTo: buttonContainerView.trailingAnchor).isActive = true
                
                currentRowWidth = buttonWidth
            } else {
                currentRowWidth += buttonWidth + buttonSpacing
            }
            
            currentRow?.addArrangedSubview(button)
            
            // Set button constraints
            button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
            button.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        }
        
        // Set bottom constraint for the last row
        if let lastRow = buttonContainerView.subviews.last {
            lastRow.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor).isActive = true
        }
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(buttonContainerView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            buttonContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            buttonContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func calculateButtonWidth(for title: String) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 14, weight: .regular)
        let textSize = (title as NSString).size(withAttributes: [.font: font])
        let padding: CGFloat = 24 // 12 on each side
        return textSize.width + padding
    }
    
    private func createFilterButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.backgroundColor = .systemGray5
        button.layer.cornerRadius = 6
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
        
        // Store button reference for later use
        filterButtons[title] = button
        
        return button
    }
    
    @objc private func filterButtonTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        
        // Toggle button selection
        sender.isSelected.toggle()
        sender.backgroundColor = sender.isSelected ? .systemBlue : .systemGray5
        
        // Update filter states based on button title
        updateFilterState(title: title, isSelected: sender.isSelected)
        
        // Apply filters immediately
        Task {
            await applyFilters()
        }
    }
    
    private func updateFilterState(title: String, isSelected: Bool) {
        print("🔍 Filter button tapped: '\(title)', isSelected: \(isSelected)")
        
        // Determine which filter category this button belongs to
        if let availableFilters = availableFilters {
            print("📋 Available filters - GradeLevels: \(availableFilters.gradeLevels)")
            print("📋 Available filters - Categories: \(availableFilters.categories)")
            print("📋 Available filters - Years: \(availableFilters.examYears)")
            print("📋 Available filters - Months: \(availableFilters.examMonths)")
            
            if availableFilters.gradeLevels.contains(title) {
                print("✅ Matched grade level: \(title)")
                if isSelected {
                    if !currentFilters.gradeLevels.contains(title) {
                        currentFilters.gradeLevels.append(title)
                        print("➕ Added grade level: \(title)")
                    }
                } else {
                    currentFilters.gradeLevels.removeAll { $0 == title }
                    print("➖ Removed grade level: \(title)")
                }
            } else if availableFilters.categories.contains(title) {
                print("✅ Matched category: \(title)")
                if isSelected {
                    if !currentFilters.categories.contains(title) {
                        currentFilters.categories.append(title)
                        print("➕ Added category: \(title)")
                    }
                } else {
                    currentFilters.categories.removeAll { $0 == title }
                    print("➖ Removed category: \(title)")
                }
            } else if availableFilters.examYears.contains(Int(title) ?? 0) {
                let year = Int(title) ?? 0
                print("✅ Matched year: \(year)")
                if isSelected {
                    if !currentFilters.examYears.contains(year) {
                        currentFilters.examYears.append(year)
                        print("➕ Added year: \(year)")
                    }
                } else {
                    currentFilters.examYears.removeAll { $0 == year }
                    print("➖ Removed year: \(year)")
                }
            } else if availableFilters.examMonths.contains(where: { "\($0)월" == title }) {
                let month = Int(title.replacingOccurrences(of: "월", with: "")) ?? 0
                print("✅ Matched month: \(month)")
                if isSelected {
                    if !currentFilters.examMonths.contains(month) {
                        currentFilters.examMonths.append(month)
                        print("➕ Added month: \(month)")
                    }
                } else {
                    currentFilters.examMonths.removeAll { $0 == month }
                    print("➖ Removed month: \(month)")
                }
            } else {
                print("❌ No match found for: \(title)")
            }
        } else {
            print("🔄 Using fallback filter logic")
            // Fallback to hardcoded filter logic
            if GradeFilter.allCases.map({ $0.rawValue }).contains(title) {
                print("✅ Fallback matched grade level: \(title)")
                if isSelected {
                    if !currentFilters.gradeLevels.contains(title) {
                        currentFilters.gradeLevels.append(title)
                        print("➕ Added grade level: \(title)")
                    }
                } else {
                    currentFilters.gradeLevels.removeAll { $0 == title }
                    print("➖ Removed grade level: \(title)")
                }
            } else if SubjectFilter.allCases.map({ $0.rawValue }).contains(title) {
                print("✅ Fallback matched category: \(title)")
                if isSelected {
                    if !currentFilters.categories.contains(title) {
                        currentFilters.categories.append(title)
                        print("➕ Added category: \(title)")
                    }
                } else {
                    currentFilters.categories.removeAll { $0 == title }
                    print("➖ Removed category: \(title)")
                }
            } else if MonthFilter.allCases.map({ $0.rawValue }).contains(title) {
                let month = Int(title.replacingOccurrences(of: "월", with: "")) ?? 0
                print("✅ Fallback matched month: \(month)")
                if isSelected {
                    if !currentFilters.examMonths.contains(month) {
                        currentFilters.examMonths.append(month)
                        print("➕ Added month: \(month)")
                    }
                } else {
                    currentFilters.examMonths.removeAll { $0 == month }
                    print("➖ Removed month: \(month)")
                }
            } else if YearFilter.allCases.map({ $0.rawValue }).contains(title) {
                let year = Int(title) ?? 0
                print("✅ Fallback matched year: \(year)")
                if isSelected {
                    if !currentFilters.examYears.contains(year) {
                        currentFilters.examYears.append(year)
                        print("➕ Added year: \(year)")
                    }
                } else {
                    currentFilters.examYears.removeAll { $0 == year }
                    print("➖ Removed year: \(year)")
                }
            } else {
                print("❌ Fallback no match found for: \(title)")
            }
        }
        
        print("📊 Current filters - GradeLevels: \(currentFilters.gradeLevels)")
        print("📊 Current filters - Categories: \(currentFilters.categories)")
        print("📊 Current filters - Years: \(currentFilters.examYears)")
        print("📊 Current filters - Months: \(currentFilters.examMonths)")
    }
    
    private func applyFilters() async {
        await MainActor.run {
            isLoading = true
            loadingIndicator.startAnimating()
        }
        
        do {
            let filteredDocuments = try await DocumentService.shared.fetchFilteredDocuments(filters: currentFilters)
            
            await MainActor.run {
                self.filteredDocuments = filteredDocuments
                self.collectionView.reloadData()
                self.isLoading = false
                self.loadingIndicator.stopAnimating()
                
                // Show empty state if no documents found
                if filteredDocuments.isEmpty {
                    showEmptyState()
                } else {
                    hideEmptyState()
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.loadingIndicator.stopAnimating()
                self.showError("필터 적용 중 오류가 발생했습니다: \(error.localizedDescription)")
            }
        }
    }
    
    private func showEmptyState() {
        // Remove existing empty state view if present
        hideEmptyState()
        
        let emptyStateView = UIView()
        emptyStateView.backgroundColor = .systemBackground
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        let emptyStateLabel = UILabel()
        emptyStateLabel.text = "선택한 필터에 맞는 문서가 없습니다"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .systemGray
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateView.addSubview(emptyStateLabel)
        contentPanel.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: contentPanel.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: contentPanel.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: contentPanel.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: contentPanel.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor)
        ])
        
        emptyStateView.tag = 999 // Tag for easy removal
    }
    
    private func hideEmptyState() {
        if let emptyStateView = contentPanel.viewWithTag(999) {
            emptyStateView.removeFromSuperview()
        }
    }
    
    private func fetchDocuments() {
        // Load initial documents with no filters
        Task {
            await applyFilters()
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredDocuments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TestPreviewCell", for: indexPath) as! TestPreviewCell
        let document = filteredDocuments[indexPath.item]
        cell.configure(with: document)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let document = filteredDocuments[indexPath.item]
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        coordinator?.showDocumentView(with: document)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 16
        let sectionInset: CGFloat = 48 // 24 on each side
        let availableWidth = collectionView.bounds.width - sectionInset
        
        // Calculate number of items per row based on available width
        let itemsPerRow: CGFloat
        
        if availableWidth >= 600 { // Large screens
            itemsPerRow = 4
        } else if availableWidth >= 400 { // Medium screens
            itemsPerRow = 3
        } else { // Small screens
            itemsPerRow = 2
        }
        
        // Calculate item width with consistent spacing
        let totalSpacing = spacing * (itemsPerRow - 1)
        let itemWidth = (availableWidth - totalSpacing) / itemsPerRow
        let itemHeight = itemWidth * 1.4 + 50 // A4 ratio + more space for 2-line title
        
        return CGSize(width: itemWidth, height: itemHeight)
    }
}

// MARK: - TestPreviewCell
class TestPreviewCell: UICollectionViewCell {
    
    private let pdfImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(pdfImageView)
        contentView.addSubview(titleContainerView)
        titleContainerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            pdfImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            pdfImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pdfImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pdfImageView.heightAnchor.constraint(equalTo: pdfImageView.widthAnchor, multiplier: 1.4), // A4 ratio
            
            titleContainerView.topAnchor.constraint(equalTo: pdfImageView.bottomAnchor, constant: 4),
            titleContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: titleContainerView.topAnchor, constant: 4),
            titleLabel.centerXAnchor.constraint(equalTo: titleContainerView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleContainerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: titleContainerView.trailingAnchor)
        ])
    }
    
    func configure(with document: Document) {
        titleLabel.text = document.title
        
        // Load thumbnail from S3
        let thumbnailURLString = APIConfiguration.S3Endpoints.thumbnail(document.id)
        
        guard let thumbnailURL = URL(string: thumbnailURLString) else {
            // Show placeholder if URL is invalid
            pdfImageView.image = UIImage(systemName: "doc.text")
            pdfImageView.tintColor = .systemGray3
            return
        }
        
        // Load image asynchronously
        URLSession.shared.dataTask(with: thumbnailURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self?.pdfImageView.image = image
                } else {
                    // Show placeholder if image loading fails
                    self?.pdfImageView.image = UIImage(systemName: "doc.text")
                    self?.pdfImageView.tintColor = .systemGray3
                }
            }
        }.resume()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        pdfImageView.image = nil
        titleLabel.text = nil
    }
} 