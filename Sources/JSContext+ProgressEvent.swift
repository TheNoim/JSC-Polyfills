//
//  JSContext+ProgressEvent.swift
//  JSContextFetch
//
//  Created by Nils Bergmann on 25.06.20.
//

import Foundation
import JavaScriptCore

@objc public protocol ProgressEventProtocol : JSExport {
    var lengthComputable: Bool { get };
    var loaded: Int { get };
    var total: Int { get };
}

public class ProgressEvent : NSObject, ProgressEventProtocol {
    public dynamic var lengthComputable: Bool
    
    public dynamic var loaded: Int
    
    public dynamic var total: Int

    init(lengthComputable: Bool, loaded: Int, total: Int) {
        self.lengthComputable = lengthComputable;
        self.loaded = loaded;
        self.total = total;
    }
}
