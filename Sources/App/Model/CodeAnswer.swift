//
//  Answer.swift
//  App
//
//  Created by Ian Manor on 25/09/18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class CodeAnswer: PostgreSQLModel {
    var id: Int?
    var userId: Int
    var codeId: Int
    var answer: String
    var timestamp: String
    
    init(userId: Int, codeId: Int, answer: String, timestamp: String) {
        self.userId = userId
        self.codeId = codeId
        self.answer = answer
        self.timestamp = timestamp
    }
}

extension CodeAnswer: Content {}
extension CodeAnswer: Migration {}
extension CodeAnswer: Parameter {}
