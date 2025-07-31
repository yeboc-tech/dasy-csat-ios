//
//  ToolbarView.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import UIKit
import PencilKit

protocol ToolbarViewDelegate: AnyObject {
    func toolbarView(_ toolbarView: ToolbarView, didSelectTool tool: PKTool?)
    func toolbarViewDidTapBack(_ toolbarView: ToolbarView)
    func toolbarViewDidTapAutoGrading(_ toolbarView: ToolbarView)
    func toolbarViewDidTapSave(_ toolbarView: ToolbarView)
}

class ToolbarView: UIView {
    weak var delegate: ToolbarViewDelegate?
    
    private let leftStackView = UIStackView()
    private let centerStackView = UIStackView()
    private let rightStackView = UIStackView()
    private let toolGroupStackView = UIStackView()
    private let backButton = UIButton(type: .system)
    private let autoGradingButton = UIButton(type: .system)
    private let pencilButton = UIButton(type: .system)
    private let eraserButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    
    private var selectedTool: PKTool?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        
        // Simple shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        
        // Setup left stack view (chevron + 자동 채점하기)
        leftStackView.axis = .horizontal
        leftStackView.distribution = .fill
        leftStackView.spacing = 36
        leftStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftStackView)
        
        // Setup center stack view (empty but pushes views to edges)
        centerStackView.axis = .horizontal
        centerStackView.distribution = .fill
        centerStackView.spacing = 0
        centerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerStackView)
        
        // Setup right stack view (tool group + 모두 지우기 + 저장하기)
        rightStackView.axis = .horizontal
        rightStackView.distribution = .fill
        rightStackView.spacing = 36
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightStackView)
        
        // Setup tool group stack view (pen + eraser)
        toolGroupStackView.axis = .horizontal
        toolGroupStackView.distribution = .fill
        toolGroupStackView.spacing = 24
        toolGroupStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup back button (chevron)
        let backImage = UIImage(systemName: "chevron.left")
        let backConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let backImageWithConfig = backImage?.withConfiguration(backConfig)
        backButton.setImage(backImageWithConfig, for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        leftStackView.addArrangedSubview(backButton)
        
        // Setup auto grading button
        autoGradingButton.setTitle("자동 채점하기", for: .normal)
        autoGradingButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        autoGradingButton.setTitleColor(.label, for: .normal)
        autoGradingButton.addTarget(self, action: #selector(autoGradingButtonTapped), for: .touchUpInside)
        leftStackView.addArrangedSubview(autoGradingButton)
        
        // Setup tool buttons
        setupButton(pencilButton, title: "", tool: PKInkingTool(.pen, color: .black, width: 1.0))
        setupButton(eraserButton, title: "", tool: PKEraserTool(.bitmap, width: 50.0))
        setupButton(clearButton, title: "모두 지우기", tool: nil)
        
        // Setup save button
        saveButton.setTitle("저장하기", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveButton.setTitleColor(.systemBlue, for: .normal)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Add pencil and eraser to tool group
        toolGroupStackView.addArrangedSubview(pencilButton)
        toolGroupStackView.addArrangedSubview(eraserButton)
        
        // Add tool group, clear button, and save button to right stack view
        rightStackView.addArrangedSubview(toolGroupStackView)
        rightStackView.addArrangedSubview(clearButton)
        rightStackView.addArrangedSubview(saveButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Left stack view (chevron + 자동 채점하기)
            leftStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            leftStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Center stack view (empty, pushes views to edges)
            centerStackView.leadingAnchor.constraint(equalTo: leftStackView.trailingAnchor, constant: 16),
            centerStackView.trailingAnchor.constraint(equalTo: rightStackView.leadingAnchor, constant: -16),
            centerStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Right stack view (tool group + 모두 지우기)
            rightStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rightStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Overall height constraint
        heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        // Select pencil by default
        selectTool(pencilButton)
        // Set the default tool
        let defaultTool = PKInkingTool(.pen, color: .black, width: 1.0)
        selectedTool = defaultTool
        delegate?.toolbarView(self, didSelectTool: defaultTool)
    }
    
    private func setupButton(_ button: UIButton, title: String, tool: PKTool?) {
        if let tool = tool {
            // Setup SF Symbol for tool buttons
            let symbolName = tool is PKInkingTool ? "pencil" : "eraser"
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfig)
            button.setImage(symbolImage, for: .normal)
            button.tintColor = .label
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.addTarget(self, action: #selector(toolButtonTapped(_:)), for: .touchUpInside)
            button.accessibilityIdentifier = tool is PKInkingTool ? "pencil" : "eraser"
        } else {
            // Setup text for clear button
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            button.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
            button.accessibilityIdentifier = "clear"
        }
        
        // Minimal styling
        button.backgroundColor = .clear
        button.tag = tool != nil ? 1 : 0
    }
    
    @objc private func backButtonTapped() {
        delegate?.toolbarViewDidTapBack(self)
    }
    
    @objc private func autoGradingButtonTapped() {
        delegate?.toolbarViewDidTapAutoGrading(self)
    }
    
    @objc private func toolButtonTapped(_ sender: UIButton) {
        selectTool(sender)
        
        if sender == pencilButton {
            let tool = PKInkingTool(.pen, color: .black, width: 1.0)
            selectedTool = tool
            delegate?.toolbarView(self, didSelectTool: tool)
        } else if sender == eraserButton {
            let tool = PKEraserTool(.bitmap, width: 50.0)
            selectedTool = tool
            delegate?.toolbarView(self, didSelectTool: tool)
        }
    }
    
    @objc private func clearButtonTapped() {
        // Clear all drawings and notify delegate
        print("Clear button tapped")
        delegate?.toolbarView(self, didSelectTool: nil)
        
        // Don't change the selected tool - keep the current tool selected
        // The clear action should not affect tool selection
    }
    
    @objc private func saveButtonTapped() {
        delegate?.toolbarViewDidTapSave(self)
    }
    
    private func selectTool(_ selectedButton: UIButton) {
        // Only handle tool buttons (pencil and eraser), not the clear button
        [pencilButton, eraserButton].forEach { button in
            if button == selectedButton {
                button.tintColor = .systemBlue
            } else {
                button.tintColor = .label
            }
        }
        
        // Clear button should always maintain its normal appearance
        clearButton.setTitleColor(.label, for: .normal)
    }
    
    func getCurrentTool() -> PKTool? {
        return selectedTool
    }
} 