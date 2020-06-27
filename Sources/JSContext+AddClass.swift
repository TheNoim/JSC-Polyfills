//
//  JSContext+AddClass.swift
//  JSContextFetch
//
//  Created by Nils Bergmann on 25.06.20.
//

import Foundation
import JavaScriptCore

internal extension JSContext {
    func add(class cls: AnyClass, name: String) {
        let constructorName = "__constructor__\(name)"
        
        let constructor: @convention(block)() -> NSObject = {
            let cls = cls as! NSObject.Type
            return cls.init()
        }
        
        self.setObject(unsafeBitCast(constructor, to: AnyObject.self),
            forKeyedSubscript: constructorName as NSCopying & NSObjectProtocol)
        
        let script = "function \(name)() " +
            "{ " +
            "   var obj = \(constructorName)(); " +
            "   obj.setThisValue(obj); " +
            "   return obj; " +
            "} "
        
        self.evaluateScript(script);
    }
}

internal extension String : Error {}
