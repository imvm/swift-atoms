//
//  WebsiteController.swift
//  App
//
//  Created by Ian Manor on 25/09/18.
//

import Vapor
import Authentication
import Crypto

struct FormController: RouteCollection {
    
    func boot(router: Router) throws {
        // create a grouped router at /sessions w/ sessions enabled
        let session = User.authSessionsMiddleware()
        let formRouter = router.grouped("form").grouped(session)
        let protectedRouter = formRouter.grouped(RedirectMiddleware<User>(path: "/form"))
        
        //index
        formRouter.get(use: indexHandler)
        
        //instructions
        protectedRouter.get("instructions_base", use: instructionBaseHandler)
        protectedRouter.get("instructions", use: instructionsHandler)
        
        //code questions
        protectedRouter.get("code_question_base", Int.parameter, use: codeQuestionBaseHandler)
        protectedRouter.post("code_question_response", Int.parameter, use: codeQuestionPostHandler)
        protectedRouter.get("code_question", Int.parameter, use: codeQuestionHandler)
        
        //demographic survey
        protectedRouter.get("demographic_survey_base", use: demographicSurveyBaseHandler)
        protectedRouter.post("demographic_survey_response", use: demographicSurveyPostHandler)
        protectedRouter.get("demographic_survey", use: demographicSurveyHandler)
        
        //final screen
        protectedRouter.get("final_screen", use: finalScreenHandler)
        
        formRouter.get("login", use: loginHandler)
        formRouter.get("logout", use: logoutHandler)
        formRouter.get("get", use: sessionGetHandler)
        formRouter.get("user", use: sessionGetUserHandler)
        formRouter.get("set", String.parameter, use: sessionSetHandler)
        formRouter.get("destroy", use: sessionDestroyHandler)
    }
    
    //MARK: administrative functions
    
    func loginHandler(_ req: Request) throws -> Future<String> {
        let user = User(questions: QuestionData(codeQuestions: []))
        return user.save(on: req).map(to: String.self) { user in
            try req.authenticate(user)
            return "Logged in"
        }
    }
    
    func logoutHandler(_ req: Request) throws -> Response {
        try req.unauthenticate(User.self)
        return req.redirect(to: "/")
    }
    
    func sessionGetUserHandler(_ req: Request) throws -> String {
        let user = try req.requireAuthenticated(User.self)
        return "Hello, \(user)! \(user.completedSurvey)"
    }
    
    func sessionGetHandler(_ req: Request) throws -> String {
        return try req.session().id ?? "n/a"
    }
    
    func sessionSetHandler(_ req: Request) throws -> String {
        // get router param
        let name = try req.parameters.next(String.self)
        
        // set name to session at key "name"
        try req.session()["name"] = name
        
        // return the newly set name
        return name
    }
    
    func sessionDestroyHandler(_ req: Request) throws -> String {
        // destroy the session
        try req.destroySession()
        
        // signal success
        return "done"
    }
    
    //MARK: page functions
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        //check if logged in
        guard let user = try? req.requireAuthenticated(User.self) else {
            //get code questions
            return CodeQuestion.query(on: req)
                .all()
                .flatMap(to: View.self) { codeQuestions in
                    let user = User(questions: QuestionData(codeQuestions: codeQuestions))
                    return user.save(on: req).flatMap { user in
                        try req.authenticate(user)
                        return try req.view().render("form_index")
                    }
            }
            
        }
        
        if user.completedSurvey {
            return try req.view().render("final_screen")
        } else {
            return try req.view().render("form_index")
        }
    }
    
    func instructionBaseHandler(_ req: Request) throws -> Response {
        guard let user = try? req.requireAuthenticated(User.self) else {
            return req.redirect(to: "/form")
        }
        
        if user.completedSurvey {
            return req.redirect(to: "/form/final_screen")
        } else {
            return req.redirect(to: "/form/instructions")
        }
    }
    
    func instructionsHandler(_ req: Request) throws -> Future<View> {
        return try req.view().render("instructions")
    }
    
    func codeQuestionBaseHandler(_ req: Request) throws -> Response {
        guard let user = try? req.requireAuthenticated(User.self) else {
            return req.redirect(to: "/form")
        }
        
        if user.completedSurvey {
            return req.redirect(to: "/form/final_screen")
        } else {
            let number = try req.parameters.next(Int.self)
            return req.redirect(to: "/form/code_question/\(number)")
        }
    }
    
    func codeQuestionPostHandler(_ req: Request) throws -> Future<Response> {
        guard let user = try? req.requireAuthenticated(User.self) else {
            throw Abort(.badRequest)
        }
        
        if user.completedSurvey {
            throw Abort(.badRequest)
        } else {
            let number = try req.parameters.next(Int.self)
            let questions = user.questions.codeQuestions
            
            guard number > 0 && number <= questions.count else {
                throw Abort(.badRequest)
            }
            
            let isLast = number == questions.count
            let index = number - 1
            let question = questions[index]
            
            let answer = try req.content.decode(CodeQuestionResponse.self).map(to: CodeAnswer.self) { response in
                
                let time = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                
                guard let userId = user.id else {
                    throw Abort(.badRequest)
                }
                
                return CodeAnswer(userId: userId, codeId: question.codeId, answer: response.output, timestamp: formatter.string(from: time))
            }
            
            return answer.save(on: req).map(to: Response.self) { _ in
                if isLast {
                    return req.redirect(to: "/form/demographic_survey_base")
                } else {
                    return req.redirect(to: "/form/code_question/\(number + 1)")
                }
            }
        }
    }
    
    func codeQuestionHandler(_ req: Request) throws -> Future<View> {
        guard let user = try? req.requireAuthenticated(User.self) else {
            return try req.view().render("form_index")
        }
        
        if user.completedSurvey {
            return try req.view().render("final_screen")
        } else {
            let number = try req.parameters.next(Int.self)
            let questions = user.questions.codeQuestions
            guard number > 0 && number <= questions.count else {
                throw Abort(.badRequest)
            }
            let index = number - 1
            let isFirst = number == 1
            let isLast = number == questions.count
            let question = questions[index]
            let context = CodeQuestionContext(numberOfQuestions: Array(1...questions.count), isFirstQuestion: isFirst, isLastQuestion: isLast, number: number, question: question)
            return try req.view().render("code_question", context)
        }
    }
    
    func demographicSurveyBaseHandler(_ req: Request) throws -> Response {
        guard let user = try? req.requireAuthenticated(User.self) else {
            return req.redirect(to: "/form")
        }
        
        if user.completedSurvey {
            return req.redirect(to: "/form/final_screen")
        } else {
            return req.redirect(to: "/form/demographic_survey")
        }
    }
    
    func demographicSurveyPostHandler(_ req: Request) throws -> Future<Response> {
        guard let user = try? req.requireAuthenticated(User.self) else {
            throw Abort(.badRequest)
        }
        
        guard let userId = user.id else {
            throw Abort(.badRequest)
        }
        
        return try req.content.decode(DemographicSurveyResponse.self).map(to: DemographicAnswer.self) { response in
            
            let answer = DemographicAnswer(userId: userId,
                                           gender: response.gender,
                                           education: response.education,
                                           firstLearned: response.firstLearned,
                                           location: response.location,
                                           method: response.method,
                                           lastUsed: response.lastUsed,
                                           swiftExperience: response.swiftExperience,
                                           otherLanguages: response.otherLanguages,
                                           programmingExperience: response.programmingExperience)
            
            return answer
        }.save(on: req).map(to: Response.self) { _ in
            return req.redirect(to: "/form/final_screen")
        }
    }
    
    func demographicSurveyHandler(_ req: Request) throws -> Future<View> {
        guard let user = try? req.requireAuthenticated(User.self) else {
            return try req.view().render("form_index")
        }
        
        if user.completedSurvey {
            return try req.view().render("final_screen")
        } else {
            return try req.view().render("demographic_survey")
        }
    }
    
    func finalScreenHandler(_ req: Request) throws -> Future<View> {
        guard let user = try? req.requireAuthenticated(User.self) else {
            return try req.view().render("form_index")
        }
        
        user.completedSurvey = true
        return user.save(on: req).flatMap(to: View.self) { user in
            return try req.view().render("final_screen")
        }
    }
    
}

struct CodeQuestionsContext: Encodable {
    let questions: [CodeQuestion]?
}

struct CodeQuestionContext: Encodable {
    let numberOfQuestions: [Int]
    let isFirstQuestion: Bool
    let isLastQuestion: Bool
    let number: Int
    let question: CodeQuestion
}

struct CodeQuestionResponse: Content {
    let output: String
}

struct DemographicSurveyResponse: Content {
    let gender: String
    let education: String
    let firstLearned: String
    let location: String
    let method: String
    let lastUsed: String
    let swiftExperience: String
    let otherLanguages: String
    let programmingExperience: String
}
