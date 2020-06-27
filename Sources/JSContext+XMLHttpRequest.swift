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

@objc public protocol XMLHttpRequestProtocol : JSExport {
    var withCredentials: Bool { get set }
    var readyState: Int { get }
    var responseText: String? { get }
    var response: String? { get }
    var responseType: String? { get }
    var responseURL: String? { get }
    var status: Int { get }
    var statusText: String? { get }
    var timeout: Int { get set }
    
    // States
    
    var UNSENT: Int { get };
    var OPENED: Int { get };
    var HEADERS_RECEIVED: Int { get };
    var LOADING: Int { get };
    var DONE: Int { get };
    
    static var UNSENT: Int { get };
    static var OPENED: Int { get };
    static var HEADERS_RECEIVED: Int { get };
    static var LOADING: Int { get };
    static var DONE: Int { get };
    
    var open: (@convention(block)(String, String, Bool, JSValue, JSValue) -> Void)? { get };
        
    var setRequestHeader: (@convention(block)(String, String?) -> Void)? { get };
    
    var send: (@convention(block)(JSValue) -> Void)? { get };
    
    var abort: (@convention(block)() -> Void)? { get };
    
    var getAllResponseHeaders: (@convention(block)() -> String)? { get };
}

public class XMLHttpRequest : NSObject, XMLHttpRequestProtocol, URLSessionDelegate, URLSessionDataDelegate, JSContextSetter {
    public static func polyfill(context: JSContext) {
        addSetTimeoutPolyfill(context: context);
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
    
    public dynamic var response: String?
    
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
    public dynamic var HEADERS_RECEIVED: Int = 2;
    public dynamic var LOADING: Int = 3;
    public dynamic var DONE: Int = 4;
    
    public static dynamic var UNSENT: Int = 0;
    public static dynamic var OPENED: Int = 1;
    public static dynamic var HEADERS_RECEIVED: Int = 2;
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
    
    private dynamic var _noLengthComputable: Bool = false
    
    private var _task: URLSessionTask?;
    
    public var context: JSContext;
    
    required init(context: JSContext) {
        self.context = context;
    }
    
    /*
      Download progress code
     */
    
    private var expectedContentLength = 0
    private var buffer = NSMutableData();
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        
        expectedContentLength = Int(response.expectedContentLength)
        if expectedContentLength < 0 {
            self._noLengthComputable = true
        }
        
        if self.readyState < self.HEADERS_RECEIVED {
            self.readyState = self.HEADERS_RECEIVED;
        }
        
        let progressEvent = ProgressEvent(lengthComputable: !self._noLengthComputable, loaded: 0, total: expectedContentLength);
        self._call(event: "onprogress", withArguments: [progressEvent]);
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.buffer.append(data)
        if self.responseText == nil {
            self.responseText = "";
        }
        
        self.responseText! += String(data: self.buffer as Data, encoding: .utf8) ?? "";
        
        if self.readyState < self.LOADING {
            self.readyState = self.LOADING
        }
        
        let progressEvent = ProgressEvent(lengthComputable: !self._noLengthComputable, loaded: buffer.length, total: self.expectedContentLength);
        self._call(event: "onprogress", withArguments: [progressEvent]);
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self._finished = true
        let progressEvent = ProgressEvent(lengthComputable: !self._noLengthComputable, loaded: buffer.length, total: self.expectedContentLength);
        self._call(event: "onprogress", withArguments: [progressEvent]);
        let response = task.response;
        if let error = error {
            if self._cancelled { return };
            print("HTTP Error: \(error)")
            self._call(event: "onerror");
            return;
        }
        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
            if self._cancelled { return };
            self._call(event: "onerror");
            return
        }
        if self._cancelled { return }
        self.responseURL = response?.url?.absoluteString;
        self.responseText = String(data: self.buffer as Data, encoding: .utf8);
        self.response = self.responseText
        self.status = httpResponse.statusCode;
        self.readyState = self.DONE;
        self._call(event: "onload")
    }
    
    /*
     Public XMLHttpRequest methods
     */
    
    public var open: (@convention(block)(String, String, Bool, JSValue, JSValue) -> Void)? {
        return { [unowned self] (_ method: String, _ url: String, _ async: Bool, _ user: JSValue, _ password: JSValue) in
            self._method = method;
            self._url = url;
            self._async = async;
            if user.isString {
                self._user = user.toString();
            }
            if password.isString {
                self._password = password.toString();
            }
            self.readyState = self.OPENED;
        }
    };
    
    public var setRequestHeader: (@convention(block)(String, String?) -> Void)? {
        return { [unowned self] (_ header: String, _ value: String?) in
            if value != nil {
                self._headers[header] = value!;
            } else {
                self._headers.removeValue(forKey: header);
            }
        }
    };
    
    public var send: (@convention(block) (JSValue) -> Void)? {
        return { [unowned self] (_ body: JSValue) in
            let config = URLSessionConfiguration.default;
            self._session = URLSession(configuration: config, delegate: self, delegateQueue: .main);
            let url = URL(string: self._url);
            var request = URLRequest(url: url!);
            request.httpMethod = self._method;
            request.allHTTPHeaderFields = self._headers;
            if !body.isNull && !body.isUndefined {
                if body.isString {
                    request.httpBody = body.toString()?.data(using: .utf8)
                }
            }
            self._task = self._session?.dataTask(with: request);
            if let task = self._task {
                if self.timeout > 0 {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(self.timeout)) {
                        if !self._finished {
                            self._cancelled = true;
                            task.cancel();
                            self._call(event: "ontimeout");
                        }
                    }
                }
                task.resume();
            }
        }
    }
    
    public var abort: (@convention(block) () -> Void)? {
        return { [unowned self] () in
            if let task = self._task {
                self._cancelled = true;
                task.cancel();
                self._call(event: "onabort");
            }
        }
    }
    
    public var getAllResponseHeaders: (@convention(block) () -> String)? {
        return { [unowned self] () in
            var allHeadersString = "";
            if let task = self._task {
                if let response = task.response as? HTTPURLResponse {
                    for (n, value) in response.allHeaderFields {
                        allHeadersString += "\(n): \(value)\r\n";
                    }
                }
            }
            return allHeadersString;
        }
    }
    
    private func _call(event: String, withArguments: [Any]) {
        if let selfValue = JSValue(object: self, in: self.context) {
            if let method = selfValue.objectForKeyedSubscript(event) {
                if !method.isNull && !method.isUndefined {
                    selfValue.invokeMethod(event, withArguments: withArguments);
                }
            }
        }
    }
    
    private func _call(event: String) {
        self._call(event: event, withArguments: []);
    }

}
