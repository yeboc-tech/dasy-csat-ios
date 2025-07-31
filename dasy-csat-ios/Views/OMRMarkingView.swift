//
//  OMRMarkingView.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import UIKit

protocol OMRMarkingViewDelegate: AnyObject {
    func omrMarkingView(_ omrView: OMRMarkingView, didMarkQuestion questionNumber: Int, withAnswer answer: Int)
}

class OMRMarkingView: UIView {
    weak var delegate: OMRMarkingViewDelegate?
    
    private let collectionView: UICollectionView
    private let questionsCount = 25
    private let answersPerQuestion = 5
    private var selectedAnswers: [Int: Int] = [:]
    private var gradingResult: GradingResult?
    
    override init(frame: CGRect) {
        // Create layout
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        
        // Create collection view
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        // Create layout
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        
        // Create collection view
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor(hex: "FFFDE6")
        
        // Border styling
        layer.borderWidth = 2
        layer.borderColor = UIColor(hex: "00557F").cgColor
        
        // Setup collection view
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(OMRHeaderCell.self, forCellWithReuseIdentifier: "HeaderCell")
        collectionView.register(OMRQuestionCell.self, forCellWithReuseIdentifier: "QuestionCell")
        collectionView.showsVerticalScrollIndicator = false
        
        addSubview(collectionView)
        
        // Add vertical line
        let verticalLine = UIView()
        verticalLine.backgroundColor = UIColor(hex: "00557F")
        verticalLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verticalLine)
        
        // Constraints
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Vertical line
            verticalLine.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            verticalLine.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            verticalLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30), // After question column
            verticalLine.widthAnchor.constraint(equalToConstant: 1)
        ])
        
        // Set width constraint
        widthAnchor.constraint(equalToConstant: 180).isActive = true
    }
}

// MARK: - UICollectionViewDataSource
extension OMRMarkingView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return questionsCount + 1 // +1 for header
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            // Header cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCell", for: indexPath) as! OMRHeaderCell
            return cell
        } else {
            // Question cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuestionCell", for: indexPath) as! OMRQuestionCell
            let questionNumber = indexPath.item
            let selectedAnswer = selectedAnswers[questionNumber]
            cell.configure(questionNumber: questionNumber, selectedAnswer: selectedAnswer, gradingResult: gradingResult)
            cell.delegate = self
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension OMRMarkingView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let height: CGFloat = 44 // Fixed height for all rows
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0 // No spacing between rows
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0 // No spacing between items
    }
}

// MARK: - OMRQuestionCellDelegate
extension OMRMarkingView: OMRQuestionCellDelegate {
    func questionCell(_ cell: OMRQuestionCell, didSelectAnswer answer: Int) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let questionNumber = indexPath.item
        
        // Check if this answer is already selected (toggle behavior)
        if selectedAnswers[questionNumber] == answer {
            // Unselect the answer
            selectedAnswers.removeValue(forKey: questionNumber)
            delegate?.omrMarkingView(self, didMarkQuestion: questionNumber, withAnswer: 0) // Use 0 to indicate unselected
        } else {
            // Select the new answer
            selectedAnswers[questionNumber] = answer
            delegate?.omrMarkingView(self, didMarkQuestion: questionNumber, withAnswer: answer)
        }
        
        // Reload the cell to update visual state
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - Public Methods
extension OMRMarkingView {
    func getMarkedAnswers() -> [Int: Int] {
        return selectedAnswers
    }
    
    func clearAllMarks() {
        selectedAnswers.removeAll()
        gradingResult = nil
        collectionView.reloadData()
    }
    
    /// Reload the collection view to update all cells
    func reloadData() {
        collectionView.reloadData()
    }
    
    // MARK: - Table-like Grid Styling Methods
    
    /// Color an entire row
    func colorRow(_ rowIndex: Int, with color: UIColor) {
        guard rowIndex >= 0 && rowIndex < questionsCount else { return }
        
        if let cell = collectionView.cellForItem(at: IndexPath(item: rowIndex + 1, section: 0)) as? OMRQuestionCell {
            cell.backgroundColor = color
        }
    }
    
    /// Color the header row
    func colorHeader(with color: UIColor) {
        if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? OMRHeaderCell {
            cell.backgroundColor = color
        }
    }
    
    /// Color the question number column
    func colorQuestionColumn(with color: UIColor) {
        // Color header question cell
        if let headerCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? OMRHeaderCell {
            headerCell.questionLabel.backgroundColor = color
        }
        
        // Color all question cells
        for i in 1...questionsCount {
            if let cell = collectionView.cellForItem(at: IndexPath(item: i, section: 0)) as? OMRQuestionCell {
                cell.questionLabel.backgroundColor = color
            }
        }
    }
    
    /// Color the answer column
    func colorAnswerColumn(with color: UIColor) {
        // Color header answer cell
        if let headerCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? OMRHeaderCell {
            headerCell.answerLabel.backgroundColor = color
        }
        
        // Color all answer cells
        for i in 1...questionsCount {
            if let cell = collectionView.cellForItem(at: IndexPath(item: i, section: 0)) as? OMRQuestionCell {
                cell.answerStackView.backgroundColor = color
            }
        }
    }
    
    /// Apply zebra striping
    func applyZebraStriping() {
        for i in 1...questionsCount {
            let color = i % 2 == 0 ? UIColor(hex: "F8F8F8") : UIColor.clear
            colorRow(i - 1, with: color)
        }
    }
    
    /// Show grading results by updating the visual appearance of cells
    func showGradingResults(result: GradingResult) {
        // Store the grading result
        self.gradingResult = result
        
        // Reload all data to apply grading styling to all cells
        collectionView.reloadData()
    }
}

// MARK: - OMRHeaderCell
class OMRHeaderCell: UICollectionViewCell {
    let questionLabel = UILabel()
    let answerLabel = UILabel()
    private let separatorLine = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor(hex: "DDDDC0")
        
        // Question label
        questionLabel.text = "문번"
        questionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        questionLabel.textColor = UIColor(hex: "00557F")
        questionLabel.textAlignment = .center
        questionLabel.backgroundColor = UIColor(hex: "DDDDC0")
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(questionLabel)
        
        // Answer label
        answerLabel.text = "답란"
        answerLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        answerLabel.textColor = UIColor(hex: "00557F")
        answerLabel.textAlignment = .center
        answerLabel.backgroundColor = UIColor(hex: "DDDDC0")
        answerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(answerLabel)
        
        // Separator line
        separatorLine.backgroundColor = UIColor(hex: "00557F")
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        
        // Constraints
        NSLayoutConstraint.activate([
            questionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 1),
            questionLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            questionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            questionLabel.widthAnchor.constraint(equalToConstant: 30),
            
            answerLabel.leadingAnchor.constraint(equalTo: questionLabel.trailingAnchor),
            answerLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            answerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            answerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Separator line
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

// MARK: - OMRQuestionCell
protocol OMRQuestionCellDelegate: AnyObject {
    func questionCell(_ cell: OMRQuestionCell, didSelectAnswer answer: Int)
}

class OMRQuestionCell: UICollectionViewCell {
    weak var delegate: OMRQuestionCellDelegate?
    
    let questionLabel = UILabel()
    let answerStackView = UIStackView()
    private var answerButtons: [UIButton] = []
    private var questionNumber: Int = 0
    private let separatorLine = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Question label
        questionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        questionLabel.textColor = UIColor(hex: "00557F")
        questionLabel.textAlignment = .center
        questionLabel.backgroundColor = UIColor(hex: "DDDDC0")
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(questionLabel)
        
        // Answer stack view
        answerStackView.axis = .horizontal
        answerStackView.distribution = .fillEqually
        answerStackView.spacing = 8
        answerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(answerStackView)
        
        // Separator line
        separatorLine.backgroundColor = UIColor(hex: "00557F")
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.isHidden = true
        contentView.addSubview(separatorLine)
        
        // Create answer buttons
        for i in 1...5 {
            let button = UIButton(type: .system)
            button.setTitle("\(i)", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            button.backgroundColor = .clear
            button.setTitleColor(UIColor(hex: "DC005B"), for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(hex: "DC005B").cgColor
            button.layer.cornerRadius = 10.5
            button.tag = i
            button.addTarget(self, action: #selector(answerButtonTapped(_:)), for: .touchUpInside)
            
            // Set button size
            button.heightAnchor.constraint(equalToConstant: 36).isActive = true
            button.widthAnchor.constraint(equalToConstant: 24).isActive = true
            
            answerButtons.append(button)
            answerStackView.addArrangedSubview(button)
        }
        
        // Constraints
        NSLayoutConstraint.activate([
            questionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 1),
            questionLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            questionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            questionLabel.widthAnchor.constraint(equalToConstant: 30),
            
            answerStackView.leadingAnchor.constraint(equalTo: questionLabel.trailingAnchor, constant: 12),
            answerStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            answerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            // Separator line
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func configure(questionNumber: Int, selectedAnswer: Int?, gradingResult: GradingResult?) {
        self.questionNumber = questionNumber
        questionLabel.text = "\(questionNumber)"
        questionLabel.font = UIFont.systemFont(ofSize: 14, weight: questionNumber % 5 == 0 ? .bold : .medium)
        
        // Show separator for every 5th question (except the last one)
        separatorLine.isHidden = !(questionNumber % 5 == 0 && questionNumber < 25)
        
        // Color question label red for wrong or unanswered questions if grading has been performed
        if let result = gradingResult {
            let isWrong = result.incorrectQuestions.contains(questionNumber)
            let isUnanswered = !result.answers.keys.contains(questionNumber)
            
            if isWrong || isUnanswered {
                // Fill question label with red background
                questionLabel.backgroundColor = UIColor.red.withAlphaComponent(0.2)
                questionLabel.textColor = .red
            } else {
                // Correct answer - normal appearance
                questionLabel.backgroundColor = UIColor(hex: "DDDDC0")
                questionLabel.textColor = UIColor(hex: "00557F")
            }
        } else {
            // No grading - normal appearance
            questionLabel.backgroundColor = UIColor(hex: "DDDDC0")
            questionLabel.textColor = UIColor(hex: "00557F")
        }
        
        // Update button states based on grading result if available
        if let result = gradingResult, let correctAnswer = result.correctAnswerKey[questionNumber] {
            // Apply grading styling
            for (index, button) in answerButtons.enumerated() {
                let answerNumber = index + 1
                let isSelected = (answerNumber) == selectedAnswer
                let isCorrect = (answerNumber) == correctAnswer
                let isUnanswered = selectedAnswer == nil
                
                if isSelected {
                    // User's selected answer should always be black
                    button.backgroundColor = .black
                    button.setTitleColor(.white, for: .normal)
                } else if isCorrect && (isUnanswered || !isSelected) {
                    // Correct answer not selected or question unanswered - show in red
                    button.backgroundColor = UIColor.red.withAlphaComponent(0.2)
                    button.setTitleColor(.red, for: .normal)
                } else {
                    // Other answers - normal appearance
                    button.backgroundColor = .clear
                    button.setTitleColor(UIColor(hex: "DC005B"), for: .normal)
                }
            }
        } else {
            // No grading result - apply normal styling
            for (index, button) in answerButtons.enumerated() {
                let isSelected = (index + 1) == selectedAnswer
                button.backgroundColor = isSelected ? .black : .clear
                button.setTitleColor(isSelected ? .white : UIColor(hex: "DC005B"), for: .normal)
            }
        }
    }
    
    func showGradingResult(result: GradingResult, questionNumber: Int, selectedAnswer: Int?) {
        // This method is now handled by the configure method
        // The grading result is stored in OMRMarkingView and applied during cell configuration
        configure(questionNumber: questionNumber, selectedAnswer: selectedAnswer, gradingResult: result)
    }
    

    
    @objc private func answerButtonTapped(_ sender: UIButton) {
        delegate?.questionCell(self, didSelectAnswer: sender.tag)
    }
} 
