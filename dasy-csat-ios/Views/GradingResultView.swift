//
//  GradingResultView.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import UIKit

protocol GradingResultViewDelegate: AnyObject {
    func gradingResultViewDidTapClose(_ resultView: GradingResultView)
}

class GradingResultView: UIView {
    weak var delegate: GradingResultViewDelegate?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let scoreLabel = UILabel()
    private let gridView = UIView()
    private let closeButton = UIButton(type: .system)
    
    private var result: GradingResult?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.systemBackground
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        addSubview(scrollView)
        
        // Setup content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Setup title label
        titleLabel.text = "채점 결과"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(hex: "00557F")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Setup score label
        scoreLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        scoreLabel.textAlignment = .center
        scoreLabel.textColor = UIColor(hex: "DC005B")
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scoreLabel)
        
        // Setup grid view
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.backgroundColor = .white
        gridView.layer.borderWidth = 2
        gridView.layer.borderColor = UIColor.black.cgColor
        contentView.addSubview(gridView)
        
        // Setup close button
        closeButton.setTitle("닫기", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        closeButton.backgroundColor = UIColor(hex: "00557F")
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.layer.cornerRadius = 8
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(closeButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            scoreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            scoreLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            gridView.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 20),
            gridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            gridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            gridView.heightAnchor.constraint(equalToConstant: 220), // 5 rows * 44 height
            
            closeButton.topAnchor.constraint(equalTo: gridView.bottomAnchor, constant: 20),
            closeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 100),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    func configure(with result: GradingResult) {
        self.result = result
        
        // Update score label
        let scoreText = String(format: "점수: %.1f점 (%d/%d)", result.score, result.correctAnswers, result.totalQuestions)
        scoreLabel.text = scoreText
        
        // Create grid
        createGrid(with: result)
    }
    
    private func createGrid(with result: GradingResult) {
        // Remove existing grid cells
        gridView.subviews.forEach { $0.removeFromSuperview() }
        
        // Use layout constraints instead of frames for better responsiveness
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        gridView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: gridView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: gridView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: gridView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: gridView.bottomAnchor)
        ])
        
        // Create 5 rows
        for row in 0..<5 {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.distribution = .fillEqually
            rowStackView.spacing = 0
            
            // Create 10 columns for each row
            for col in 0..<10 {
                let cell = createGridCell(row: row, col: col, result: result)
                rowStackView.addArrangedSubview(cell)
            }
            
            stackView.addArrangedSubview(rowStackView)
        }
    }
    
    private func createGridCell(row: Int, col: Int, result: GradingResult) -> UIView {
        let cell = UIView()
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.black.cgColor
        
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        
        // Determine cell content and styling
        let questionNumber = row * 10 + col + 1
        
        if col % 2 == 0 {
            // Grey cell with question number
            cell.backgroundColor = UIColor(hex: "DDDDDD")
            label.text = "\(questionNumber)"
            label.textColor = UIColor(hex: "00557F")
            
            // Add red diagonal line overlay for wrong questions
            if result.incorrectQuestions.contains(questionNumber) {
                addDiagonalLineOverlay(to: cell)
            }
        } else {
            // White cell with answer
            cell.backgroundColor = .white
            if let selectedAnswer = result.answers[questionNumber] {
                label.text = "\(selectedAnswer)"
                
                // Check if answer is correct
                if let correctAnswer = result.correctAnswerKey[questionNumber] {
                    if selectedAnswer == correctAnswer {
                        label.textColor = .black
                    } else {
                        // Wrong answer - highlight in red
                        label.textColor = .red
                        cell.backgroundColor = UIColor.red.withAlphaComponent(0.1)
                        
                        // Show correct answer in red
                        if let correctAnswer = result.correctAnswerKey[questionNumber] {
                            label.text = "\(correctAnswer)"
                            label.textColor = .red
                            cell.backgroundColor = UIColor.red.withAlphaComponent(0.2)
                        }
                    }
                } else {
                    label.textColor = .black
                }
            } else {
                // No answer selected - show correct answer in red
                if let correctAnswer = result.correctAnswerKey[questionNumber] {
                    label.text = "\(correctAnswer)"
                    label.textColor = .red
                    cell.backgroundColor = UIColor.red.withAlphaComponent(0.2)
                } else {
                    label.text = "-"
                    label.textColor = .gray
                }
            }
        }
        
        return cell
    }
    
    private func addDiagonalLineOverlay(to cell: UIView) {
        let diagonalLine = UIView()
        diagonalLine.backgroundColor = .red
        diagonalLine.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(diagonalLine)
        
        // Position the line from left bottom to right top
        NSLayoutConstraint.activate([
            diagonalLine.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            diagonalLine.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            diagonalLine.widthAnchor.constraint(equalTo: cell.widthAnchor, multiplier: 1.4), // Slightly longer than cell width
            diagonalLine.heightAnchor.constraint(equalToConstant: 2)
        ])
        
        // Rotate the line 45 degrees to create diagonal effect
        diagonalLine.transform = CGAffineTransform(rotationAngle: .pi / 4)
    }
    
    @objc private func closeButtonTapped() {
        delegate?.gradingResultViewDidTapClose(self)
    }
} 