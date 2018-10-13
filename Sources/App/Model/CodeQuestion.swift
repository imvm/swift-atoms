//
//  File.swift
//  App
//
//  Created by Ian Manor on 07/10/18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class CodeQuestion: PostgreSQLModel {
    var id: Int?
    var codeId: Int
    var obfuscated: Bool
    var correspondingId: Int
    var atom: String
    var code: String
    
    init(codeId: Int, obfuscated: Bool, correspondingId: Int, atom: String, code: String) {
        self.codeId = codeId
        self.obfuscated = obfuscated
        self.correspondingId = correspondingId
        self.atom = atom
        self.code = code
    }
}

extension CodeQuestion: Content {}
extension CodeQuestion: Migration {}
extension CodeQuestion: Parameter {}

