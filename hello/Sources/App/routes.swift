import Vapor
import Fluent
import Leaf

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    // http://127.0.0.1:8080/hello
    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    // http://127.0.0.1:8080/hello/vapor
    app.get("hello", "vapor") { req in
        return "Hello, vapor!"
    }
    
    // http://127.0.0.1:8080/hello/vapor
    app.on(.GET, "hello", "vapor") { req in
        return "on hello vapor"
    }
    // path parameter
    // http://127.0.0.1:8080/hello/ns
    app.get("hello", ":name") { req -> String in
        let name = req.parameters.get("name")!
        return "Hello, \(name)!"
    }
    app.get("hello", "**") { req -> String in
        let name = req.parameters.getCatchall().joined(separator: " ")
        return "Hello, \(name)!"
    }
    
    // url query sring
    // http://127.0.0.1:8080/hello?name="hi"
    app.get("hello") { req -> String in
        let hello = try req.query.decode(Hello.self)
        return "url query: Hello \(hello.name ?? "Anonymous")"
        // url query: Hello "hi"
    }
    app.get("hello") { req -> String in
        let name: String? = req.query["name"]
        return "url query: Hello \(name ?? "Anonymous")"
        // url query: Hello "hi"
    }
    
    // client test
    app.get("testClient") { req -> String in
        app.client.get("https://www.naver.com") { res in
            print(res.body)
        }
        return "Client API Call"
    }
    
    // logger test
    app.get("validation") { req -> String in
        try Hello.validate(query: req)
        let name = try req.query.decode(Hello.self).name!
        req.logger.info("validation test")
        return name
    }
    
    // model save to mysql
    app.get("galaxies") { req -> EventLoopFuture<Galaxy> in
        let galaxy = try req.query.decode(Galaxy.self)
        return galaxy.create(on: req.db)
            .map { galaxy }
    }
    
    // query all
    app.get("galaxies", "all") { req in
        Galaxy.query(on: req.db).all()
    }
    
    // query single field all
    app.get("galaxies", "name", "all") { req in
        Galaxy.query(on: req.db).all(\.$name)
    }
    
    // query first
    app.get("galaxies", "first") { req -> EventLoopFuture<Galaxy> in
        let earth = Galaxy.query(on: req.db)
            .filter(\.$name == req.query["name"]!)
            .first()
            .unwrap(or: Abort(.noContent))
        
        return earth
    }
    
    // query group
    app.get("galaxies", "group") { req -> EventLoopFuture<[Galaxy]> in
        let a: String = req.query["a"]!
        let b: String = req.query["b"]!
        
        let galaxy = Galaxy.query(on: req.db).group(.or) { group in
            group.filter(\.$name == b).filter(\.$name == a)
        }.all()
        
        return galaxy
    }
    
    // query filter
    app.get("galaxies", "filter") { req -> EventLoopFuture<[Galaxy]> in
        let a: String = req.query["a"]!
        let b: String = req.query["b"]!
        
        let earth = Galaxy.query(on: req.db)
            .filter(\.$name == a)
            .filter(\.$name == b)
            .all()
        
        return earth
    }
    
    // query galaxy count
    app.get("galaxies", "count") { req in
        Galaxy.query(on: req.db).count()
    }
    
    // chunk
    app.get("galaxies", "chunk") { req -> [Galaxy] in
        var galaxies: [Galaxy] = []
        Galaxy.query(on: req.db).chunk(max: 4) { results in
            for result in results {
                switch result {
                case .success(let galaxy):
                    print(galaxy)
                    galaxies.append(galaxy)
                case .failure(let error):
                    print(error)
                }
            }
        }
        
        return galaxies
    }
    
    // field
    app.get("galaxies", "field") { req in
        return Galaxy.query(on: req.db)
            .field(\.$name)
            .all()
    }
    
    // unique
    app.get("galaxies", "unique") { req in
        return Galaxy.query(on: req.db)
            .field(\.$name)
            .unique()
            .all()
    }
    
    // range
    app.get("galaxies", "range") { req in
        Galaxy.query(on: req.db)
            .range(..<3)
            .all()
    }
    
    // update
    app.get("galaxies", "update") { req in
        Galaxy.query(on: req.db)
            .filter(\.$name == req.query["name"]!)
            .set(\.$name, to: req.query["newName"]!)
            .update()
            .map { SimpleResponse(code: 200, msg: "수정성공") }
    }
    
    // delete
    app.get("galaxies", "delete") { req in
        Galaxy.query(on: req.db)
            .filter(\.$name == req.query["name"]!)
            .delete()
            .map { SimpleResponse(code: 200, msg: "삭제성공")}
    }
    
    // paginate
    app.get("galaxies") { req in
        Galaxy.query(on: req.db)
            .sort(\.$name)
            .paginate(for: req)
    }
    
    // transaction
    app.get("galaxies", "transaction") { req -> EventLoopFuture<String> in
        let name: String = req.query["name"]!
        return req.db.transaction { db in
            let star = Galaxy(name: name)
            let enStar = Galaxy(name: "\(name) star")
            return star.save(on: db).flatMap { _ in
                if !star.name.contains("별") {
                    return req.eventLoop.makeFailedFuture((Abort(.badRequest)))
                }
                return enStar.save(on: db).map { "성공" }
            }
        }
    }
    
    // MARK: - Leaf
    
    app.get("helloLeaf") { req -> EventLoopFuture<View> in
        
        return req.view.render("hello", ["name": "Leaf"])
    }
    
   
}

struct Hello: Content {
    var name: String?
}

struct SimpleResponse: Content {
    var code: Int
    var msg: String
}

extension Hello: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .count(3...))
    }
}
