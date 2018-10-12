//
//  AdminController.swift
//  App
//
//  Created by Ian Manor on 02/10/18.
//

import Vapor

struct AdminController: RouteCollection {
    
    func boot(router: Router) throws {
        router.get("admin", use: adminHandler)
        router.get("api", "wipe", use: wipeHandler)
        //router.get("download", "code", use: downloadCodeQuestionsHandler)
        router.post("api", "code", use: codeHandler)
    }
    
    func wipeHandler(_ req: Request) throws -> String {
        User.query(on: req).delete()
        CodeAnswer.query(on: req).delete()
        DemographicAnswer.query(on: req).delete()
        CodeQuestion.query(on: req).delete()
        
        return "wiping questions table"
    }
    /*
    func downloadCodeQuestionsHandler(_ req: Request) throws -> Future<Data> {
        return CodeQuestion.query(on: req)
            .all()
            .map(to: Data.self) { questions in
                let encoder = JSONEncoder()
                let json = try encoder.encode(questions)
                return json
        }
    }
    */
    func adminHandler(_ req: Request) throws -> Future<View> {
        return CodeQuestion.query(on: req)
        .all()
        .flatMap(to: View.self) { questions in
            let questionsData = questions.isEmpty ? nil : questions
            
            return CodeAnswer.query(on: req)
            .all()
            .flatMap(to: View.self) { codeAnswers in
                let codeAnswersData = codeAnswers.isEmpty ? nil : codeAnswers
                
                return DemographicAnswer.query(on: req)
                .all()
                .flatMap(to: View.self) { surveyAnswers in
                    let surveyAnswersData = surveyAnswers.isEmpty ? nil : surveyAnswers
                    let context = AdminContext(
                        codeQuestions: questionsData, codeAnswers: codeAnswersData, surveyAnswers: surveyAnswersData)
                    
                    return try req.view().render("admin", context)
                }
            }
        }
    }
    
    func codeHandler(_ req: Request) throws -> Future<CodeQuestion> {
        return try req.content.decode(CodeQuestion.self)
            .flatMap(to: CodeQuestion.self) { question in
                return question.save(on: req)
        }
    }

}

struct AdminContext: Encodable {
    let codeQuestions: [CodeQuestion]?
    let codeAnswers: [CodeAnswer]?
    let surveyAnswers: [DemographicAnswer]?
}
