//
//  GradingService.swift
//  dasy-csat-ios
//
//  Created by Joon Nam on 7/28/25.
//

import Foundation
import UIKit

struct GradingResult {
    let totalQuestions: Int
    let answeredQuestions: Int
    let correctAnswers: Int
    let score: Double
    let answers: [Int: Int] // question number -> selected answer
    let correctAnswerKey: [Int: Int] // question number -> correct answer
    let incorrectQuestions: [Int] // question numbers that are wrong
}

class GradingService {
    static let shared = GradingService()
    
    // Answer key based on the image provided
    // The image shows a 5x10 grid where grey cells have sequential numbers 1-25
    // and white cells have circled numbers 1-5 which represent the correct answers
    private let answerKey: [Int: Int] = [
        1: 5, 2: 3, 3: 2, 4: 3, 5: 3,
        6: 4, 7: 2, 8: 5, 9: 4, 10: 5,
        11: 3, 12: 3, 13: 5, 14: 2, 15: 5,
        16: 3, 17: 4, 18: 1, 19: 1, 20: 1,
        21: 4, 22: 4, 23: 1, 24: 2, 25: 5
    ]
    
    private init() {}
    
    func gradeAnswers(_ answers: [Int: Int]) -> GradingResult {
        let totalQuestions = 25
        let answeredQuestions = answers.count
        
        var correctAnswers = 0
        var incorrectQuestions: [Int] = []
        
        for (questionNumber, selectedAnswer) in answers {
            if let correctAnswer = answerKey[questionNumber] {
                if selectedAnswer == correctAnswer {
                    correctAnswers += 1
                } else {
                    incorrectQuestions.append(questionNumber)
                }
            }
        }
        
        let score = totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) * 100.0 : 0.0
        
        return GradingResult(
            totalQuestions: totalQuestions,
            answeredQuestions: answeredQuestions,
            correctAnswers: correctAnswers,
            score: score,
            answers: answers,
            correctAnswerKey: answerKey,
            incorrectQuestions: incorrectQuestions
        )
    }
    
    func isAllQuestionsAnswered(_ answers: [Int: Int]) -> Bool {
        return answers.count == 25
    }
    
    func getAnswerKey() -> [Int: Int] {
        return answerKey
    }
} 