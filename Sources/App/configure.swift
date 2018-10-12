import Leaf
import Vapor
import FluentPostgreSQL
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    
    //let serverConfigure = NIOServerConfig.default(hostname: "0.0.0.0", port: 8080)
    //services.register(serverConfigure)
    
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(LeafProvider())
    try services.register(AuthenticationProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    /// Use Leaf for rendering views
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self)
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
    services.register(middlewares)
    
    // Configure a database
    var databases = DatabasesConfig()
    
    let databaseConfig: PostgreSQLDatabaseConfig
    if let url = Environment.get("DATABASE_URL") {
        databaseConfig = PostgreSQLDatabaseConfig(url: url)!
    } else {
        let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
        let username = Environment.get("DATABASE_USER") ?? "vapor"
        
        let databaseName: String
        let databasePort: Int
        if (env == .testing) {
            databaseName = "vapor-test"
            if let testPort = Environment.get("DATABASE_PORT") {
                databasePort = Int(testPort) ?? 5433
            } else {
                databasePort = 5433
            }
        }
        else {
            databaseName = Environment.get("DATABASE_DB") ?? "vapor"
            databasePort = 5432
        }
        let password = Environment.get("DATABASE_PASSWORD") ?? "password"
        databaseConfig = PostgreSQLDatabaseConfig(
            hostname: hostname,
            port: databasePort,
            username: username,
            database: databaseName,
            password: password)
    }
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)
    
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: CodeQuestion.self, database: .psql)
    migrations.add(model: CodeAnswer.self, database: .psql)
    migrations.add(model: DemographicAnswer.self, database: .psql)
    services.register(migrations)
    
    services.register { container -> LeafTagConfig in
        var config = LeafTagConfig.default()
        config.use(StringTag(), as: "string")
        return config
    }
}
