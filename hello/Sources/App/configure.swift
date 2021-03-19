import Vapor
import Foundation
import Fluent
import FluentMySQLDriver
import Leaf

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
     app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // MARK: - Setting MySQL
    try setUpMySQL(app)
    
    // MARK: - Setting Leaf
    app.leaf.configuration.rootDirectory = app.directory.viewsDirectory
    app.leaf.cache.isEnabled = app.environment.isRelease
    
    app.views.use(.leaf)
    
    // MARK: - Register Routes
    try routes(app)
    
}

private func setUpMySQL(_ app: Application) throws {
    app.databases.use(
        .mysql(
            hostname: "localhost",
            username: "root",
            password: "",
            database: "vapor",
            tlsConfiguration: .forClient(certificateVerification: .none)
    ), as: .mysql)

//    createPlanetSchema(app)
//    updatePlanetSchema(app.db)
//    enumPlanetSchema(app.db)
//    updateGalaxy(app.db)
    
    app.migrations.add(GalaxyMigration())
}

// MARK: - 스키마 생성

private func createPlanetSchema(_ app: Application) {
    app.db.schema("planets")
        .id()
        .field("name", .string, .required)
        .field("age", .int)
        .create()
    
    app.db.schema("galaxies")
        .ignoreExisting()
        .id()
        .field("name", .string, .required)
        .create()
}

// MARK: - 스키마 업데이트

private func updatePlanetSchema(_ db: Database) {
    db.schema("planets")
        .updateField("name", .string)
//        .field("arr", .array(of: .string))
//        .field("dic", .dictionary(of: .int))
        .field("type", .dictionary)
        .update()
}

// MARK: - 스키마 열거형

private func enumPlanetSchema(_ db: Database) {
    db.enum("planet_type")
        .case("one")
        .case("two")
        .case("three")
        .create()
    
    db.enum("planet_type").read().flatMap { type in
        db.schema("planets")
            .field("enumType", type, .required)
            .update()
    }
}

// MARK: - 스키마 마이그레이션

private func updateGalaxy(_ db: Database) {
    db.schema("galaxies")
        .field("distance", .int)
        .update()
}

struct GalaxyMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("galaxies")
            .field("age", .int)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("galaxies").delete()
    }
}
