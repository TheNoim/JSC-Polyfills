//
//  JSContext+XMLHttpRequest.swift
//  JSContextFetch
//
//  Created by Nils Bergmann on 25.06.20.
//

import Foundation
import JavaScriptCore

// http://rbereski.info/2015/05/15/java-script-core/

// https://xhr.spec.whatwg.org/

@objc public protocol XMLHttpRequestProtocol : JSExport, JSObjectProtocol {
    var withCredentials: Bool { get set }
    var readyState: Int { get }
    var responseText: String? { get }
    var responseType: String? { get }
    var responseURL: String? { get }
    var status: Int { get }
    var statusText: String? { get }
    var timeout: Int { get set }
    
    // States
    
    var UNSENT: Int { get };
    var OPENED: Int { get };
    var EADERS_RECEIVED: Int { get };
    var LOADING: Int { get };
    var DONE: Int { get };
    
    static var UNSENT: Int { get };
    static var OPENED: Int { get };
    static var EADERS_RECEIVED: Int { get };
    static var LOADING: Int { get };
    static var DONE: Int { get };
    
    var open: (@convention(block)(String, String, Bool, String?, String?) -> Void)? { get };
    
    var setRequestHeader: (@convention(block)(String, String?) -> Void)? { get };
    
    var send: (@convention(block)(Any?) -> Void)? { get };
    
    var abort: (@convention(block)() -> Void)? { get };
}

@objc public class XMLHttpRequest : JSObject, XMLHttpRequestProtocol {
    public static func polyfill(context: JSContext) {
        context.add(class: XMLHttpRequest.self, name: "XMLHttpRequest");
    }
        
    public dynamic var withCredentials: Bool = false;
    
    public dynamic var readyState: Int {
        get {
            return self._readyState;
        }
        set(newReadyState) {
            self._readyState = newReadyState;
            self._call(event: "onreadystatechange", withArguments: [newReadyState]);
        }
    }
    
    public dynamic var responseText: String?
    
    public dynamic var responseType: String?
    
    public dynamic var responseURL: String?
    
    public dynamic var status: Int = 100;
    
    public dynamic var statusText: String?
    
    public dynamic var timeout: Int = 0;
    
    /*
     States
     */
    
    public dynamic var UNSENT: Int = 0;
    public dynamic var OPENED: Int = 1;
    public dynamic var EADERS_RECEIVED: Int = 2;
    public dynamic var LOADING: Int = 3;
    public dynamic var DONE: Int = 4;
    
    public static dynamic var UNSENT: Int = 0;
    public static dynamic var OPENED: Int = 1;
    public static dynamic var EADERS_RECEIVED: Int = 2;
    public static dynamic var LOADING: Int = 3;
    public static dynamic var DONE: Int = 4;
    
    /*
     Private vars
     */
        
    private dynamic var _headers: Dictionary<String, String> = Dictionary();
    
    private dynamic var _readyState: Int = 0
    
    private dynamic var _async: Bool = false;
    
    private dynamic var _method: String = "GET";
    
    private dynamic var _url: String = "";
    
    private dynamic var _password: String?;
    
    private dynamic var _user: String?;
    
    private dynamic var _session: URLSession?
    
    private dynamic var _cancelled: Bool = false
    
    private dynamic var _finished: Bool = false
    
    /*
     Public XMLHttpRequest methods
     */
    
    public var open: (@convention(block)(String, String, Bool, String?, String?) -> Void)? {
        return { [unowned self] (method: String, url: String, async: Bool, user: String?, password: String?) in
            self._method = method;
            self._url = url;
            self._async = async;
            self._user = user;
            self._password = password;
            self.readyState = self.OPENED;
        }
    };
    
    public var setRequestHeader: (@convention(block)(String, String?) -> Void)? {
        return { [unowned self] (header: String, value: String?) in
            if value != nil {
                self._headers[header] = value!;
            } else {
                self._headers.removeValue(forKey: header);
            }
        }
    };
    
    public var send: (@convention(block) (Any?) -> Void)? {
        return { [unowned self] (body: Any?) in
            let config = URLSessionConfiguration.default;
            self._session = URLSession(configuration: config);
            let url = URL(string: self._url);
            var request = URLRequest(url: url!);
            request.httpMethod = self._method;
            request.allHTTPHeaderFields = self._headers;
            if (body != nil) {
                request.httpBody = body as? Data;
            }
            self._session?.downloadTask(with: request, completionHandler: { (url, response, error) in
                if self._cancelled { return }
                self._finished = true
            })
            if self.timeout > 0 {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(self.timeout)) {
                    if !self._finished {
                        self._cancelled = true;
                        self._session?.invalidateAndCancel();
                        self._call(event: "ontimeout");
                    }
                }
            }
        }
    }
    
    public var abort: (@convention(block) () -> Void)? {
        return { [unowned self] () in
            if self._session != nil {
                self._cancelled = true;
                self._session?.invalidateAndCancel();
                self._call(event: "onabort");
            }
        }
    }
    
    private func _call(event: String, withArguments: [Any]) {
        if let event = self.this?.value.forProperty("event") {
            event.call(withArguments: withArguments);
        }
    }
    
    private func _call(event: String) {
        self._call(event: event, withArguments: []);
    }

}

private extension JSContext {
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

extension String : Error {}
