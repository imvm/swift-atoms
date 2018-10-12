//
//  StringTag.swift
//  App
//
//  Created by Ian Manor on 02/10/18.
//

import Foundation
import Leaf

final class StringTag: TagRenderer {
    init() { }
    
    func render(tag: TagContext) throws -> EventLoopFuture<TemplateData> {
        
        let string = tag.parameters.compactMap { parameter in
            let lines = parameter.string?.components(separatedBy: CharacterSet.newlines)
            return lines?.joined(separator: "<br/>")
        }.joined()
        
        return tag.container.future(.string(string))
    }
}
