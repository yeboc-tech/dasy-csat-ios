import UIKit
import PDFKit

class HomeViewController: UIViewController {
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 24
        layout.sectionInset = UIEdgeInsets(top: 32, left: 24, bottom: 32, right: 24)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let tests: [TestItem] = [
        TestItem(title: "test", year: "2024", subject: "Mathematics", fileName: "test")
    ]
    
    weak var coordinator: AppCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TestPreviewCell.self, forCellWithReuseIdentifier: "TestPreviewCell")
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TestPreviewCell", for: indexPath) as! TestPreviewCell
        let test = tests[indexPath.item]
        cell.configure(with: test)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let test = tests[indexPath.item]
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        coordinator?.showDocumentView()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 16
        let sectionInset: CGFloat = 48 // 24 on each side
        let availableWidth = collectionView.bounds.width - sectionInset - spacing
        
        // Calculate number of items per row based on screen width
        let screenWidth = UIScreen.main.bounds.width
        let itemsPerRow: CGFloat
        
        if screenWidth >= 768 { // iPad
            itemsPerRow = 6
        } else if screenWidth >= 428 { // iPhone 14 Pro Max, 15 Pro Max
            itemsPerRow = 5
        } else if screenWidth >= 390 { // iPhone 12, 13, 14, 15
            itemsPerRow = 4
        } else { // Smaller iPhones
            itemsPerRow = 3
        }
        
        let itemWidth = availableWidth / itemsPerRow
        let itemHeight = itemWidth * 1.4 + 30 // A4 ratio + space for title
        
        return CGSize(width: itemWidth, height: itemHeight)
    }
}

// MARK: - TestItem Model
struct TestItem {
    let title: String
    let year: String
    let subject: String
    let fileName: String
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
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            pdfImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            pdfImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pdfImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pdfImageView.heightAnchor.constraint(equalTo: pdfImageView.widthAnchor, multiplier: 1.4), // A4 ratio
            
            titleLabel.topAnchor.constraint(equalTo: pdfImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with test: TestItem) {
        titleLabel.text = test.title
        
        // Try to load PDF preview
        var pdfURL: URL?
        
        if let url = Bundle.main.url(forResource: test.fileName, withExtension: "pdf") {
            pdfURL = url
        } else if let url = Bundle.main.url(forResource: test.fileName, withExtension: "pdf", subdirectory: "Resources") {
            pdfURL = url
        } else if let url = Bundle.main.url(forResource: test.fileName, withExtension: "pdf", subdirectory: "dasy-csat-ios/Resources") {
            pdfURL = url
        }
        
        guard let url = pdfURL, let pdfDocument = PDFDocument(url: url) else {
            // Show placeholder if PDF not found
            pdfImageView.image = UIImage(systemName: "doc.text")
            pdfImageView.tintColor = .systemGray3
            return
        }
        
        // Get the first page and render it as an image
        if let firstPage = pdfDocument.page(at: 0) {
            let pageRect = firstPage.bounds(for: .mediaBox)
            
            // Higher resolution for better quality
            let scale: CGFloat = 0.4
            let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: scaledSize)
            
            let image = renderer.image { context in
                // Fill with white background
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: scaledSize))
                
                // Draw the PDF page
                context.cgContext.translateBy(x: 0, y: scaledSize.height)
                context.cgContext.scaleBy(x: scale, y: -scale)
                firstPage.draw(with: .mediaBox, to: context.cgContext)
            }
            
            pdfImageView.image = image
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        pdfImageView.image = nil
        titleLabel.text = nil
    }
} 