//
//  User.swift
//  App
//
//  Created by Ian Manor on 25/09/18.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class User: PostgreSQLModel {
    var id: Int?
    var completedSurvey: Bool = false
    var questions: QuestionData
    
    init(questions: QuestionData) {
        self.questions = questions
    }
}

final class QuestionData: Codable {
    let codeQuestions: [CodeQuestion]
    
    init(codeQuestions: [CodeQuestion]) {
        self.codeQuestions = codeQuestions
    }
}

extension User: SessionAuthenticatable {}

extension User: Content {}
extension User: Migration {}
extension User: Parameter {}
