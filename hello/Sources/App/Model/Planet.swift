//
//  File.swift
//  
//
//  Created by 남수김 on 2021/02/09.
//

import Foundation
import Fluent
import Vapor

final class Planet: Model, Content {
    // Name of the table or collection.
    static let schema: String = "planets"
    
    // Unique identifier for this Planet.
    @ID(key: .id)
    var id: UUID?
    
    // The Planet's name.
    @Field(key: "name")
    var name: String
    
    @Field(key: "type")
    var type: SchemaType
    
    // Creates a new, empty Planet.
    init() { }
    
    // Creates a new Planet with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}


struct SchemaType: Codable {
    var name: String
}
