//
//  DemographicAnswer.swift
//  App
//
//  Created by Ian Manor on 07/10/18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class DemographicAnswer: PostgreSQLModel {
    var id: Int?
    var userId: Int
    var gender: String
    var education: String
    var firstLearned: String
    var location: String
    var method: String
    var lastUsed: String
    var swiftExperience: String
    var otherLanguages: String
    var programmingExperience: String
    
    init(userId: Int, gender: String, education: String, firstLearned: String, location: String, method: String, lastUsed: String, swiftExperience: String, otherLanguages: String, programmingExperience: String) {
        self.userId = userId
        self.gender = gender
        self.education = education
        self.firstLearned = firstLearned
        self.location = location
        self.method = method
        self.lastUsed = lastUsed
        self.swiftExperience = swiftExperience
        self.otherLanguages = otherLanguages
        self.programmingExperience = programmingExperience
    }
}

extension DemographicAnswer: Content {}
extension DemographicAnswer: Migration {}
extension DemographicAnswer: Parameter {}
