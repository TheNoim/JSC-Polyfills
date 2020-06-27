//
//  JSContext+AddClass.swift
//  JSContextFetch
//
//  Created by Nils Bergmann on 25.06.20.
//

import Foundation
import JavaScriptCore

internal protocol JSContextSetter {
    var context: JSContext { get set };
    init(context: JSContext);
}

internal extension JSContext {
    func add(class cls: AnyClass, name: String) {
        let currentContext = self;
        
        let constructor: @convention(block)() -> NSObject = {
            let cls = cls as! JSContextSetter.Type
            return cls.init(context: currentContext) as! NSObject;
        }
        
        self.setObject(unsafeBitCast(constructor, to: AnyObject.self),
                       forKeyedSubscript: name as NSCopying & NSObjectProtocol);
    }
}

extension String : Error {}
