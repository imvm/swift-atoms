import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let formController = FormController()
    try router.register(collection: formController)
    
    let adminController = AdminController()
    try router.register(collection: adminController)
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return try req.view().render("index")
    }
    
    func surveyHandler(_ req: Request) throws -> Future<View> {
        return try req.view().render("survey")
    }
    
    router.get(use: indexHandler)
    router.get("survey", use: surveyHandler)
}
