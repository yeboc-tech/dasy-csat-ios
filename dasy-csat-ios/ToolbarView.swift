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
}

class ToolbarView: UIView {
    weak var delegate: ToolbarViewDelegate?
    
    private let leftStackView = UIStackView()
    private let rightStackView = UIStackView()
    private let toolGroupStackView = UIStackView() // New stack view for tool grouping
    private let autoGradingLabel = UILabel()
    private let pencilButton = UIButton(type: .system)
    private let eraserButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    
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
        
        // Setup left stack view (auto grading)
        leftStackView.axis = .horizontal
        leftStackView.distribution = .fill
        leftStackView.spacing = 8
        leftStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftStackView)
        
        // Setup tool group stack view (pencil and eraser)
        toolGroupStackView.axis = .horizontal
        toolGroupStackView.distribution = .fill
        toolGroupStackView.spacing = 24 // Closer spacing between pencil and eraser
        toolGroupStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolGroupStackView)
        
        // Setup right stack view (tools) - increased spacing for gap between tool group and text
        rightStackView.axis = .horizontal
        rightStackView.distribution = .fill
        rightStackView.spacing = 48 // Larger gap between tool group and clear button
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightStackView)
        
        // Setup auto grading label
        autoGradingLabel.text = "자동 채점"
        autoGradingLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        autoGradingLabel.textColor = .label
        leftStackView.addArrangedSubview(autoGradingLabel)
        
        // Setup buttons (minimal styling)
        setupButton(pencilButton, title: "", tool: PKInkingTool(.pen, color: .black, width: 1.0))
        setupButton(eraserButton, title: "", tool: PKEraserTool(.bitmap, width: 50.0))
        setupButton(clearButton, title: "모두 지우기", tool: nil)
        
        // Add pencil and eraser to tool group
        toolGroupStackView.addArrangedSubview(pencilButton)
        toolGroupStackView.addArrangedSubview(eraserButton)
        
        // Add tool group and clear button to right stack view
        rightStackView.addArrangedSubview(toolGroupStackView)
        rightStackView.addArrangedSubview(clearButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            leftStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            leftStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            rightStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rightStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Select pencil by default
        selectTool(pencilButton)
        // Set the default tool
        let defaultTool = PKInkingTool(.pen, color: .black, width: 1.0)
        selectedTool = defaultTool
        delegate?.toolbarView(self, didSelectTool: defaultTool)
    }
    
    private func setupButton(_ button: UIButton, title: String, tool: PKTool?) {
        if let tool = tool {
            // Setup SF Symbol for tool buttons - smaller size
            let symbolName = tool is PKInkingTool ? "pencil" : "eraser"
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfig)
            button.setImage(symbolImage, for: .normal)
            button.tintColor = .label
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.addTarget(self, action: #selector(toolButtonTapped(_:)), for: .touchUpInside)
            button.accessibilityIdentifier = tool is PKInkingTool ? "pencil" : "eraser"
        } else {
            // Setup text for clear button - match auto grading label font
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            button.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
            button.accessibilityIdentifier = "clear"
        }
        
        // Minimal styling - no background, no corner radius
        button.backgroundColor = .clear
        button.tag = tool != nil ? 1 : 0
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
        // Clear the current tool and notify delegate
        selectedTool = nil
        delegate?.toolbarView(self, didSelectTool: nil)
    }
    
    private func selectTool(_ selectedButton: UIButton) {
        [pencilButton, eraserButton, clearButton].forEach { button in
            if button == selectedButton {
                if button == clearButton {
                    button.setTitleColor(.systemBlue, for: .normal)
                } else {
                    button.tintColor = .systemBlue
                }
            } else {
                if button == clearButton {
                    button.setTitleColor(.label, for: .normal)
                } else {
                    button.tintColor = .label
                }
            }
        }
    }
    
    func getCurrentTool() -> PKTool? {
        return selectedTool
    }
} 