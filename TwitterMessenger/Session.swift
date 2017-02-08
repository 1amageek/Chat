//
//  Session.swift
//  Chat
//
//  Created by 1amageek on 2017/02/01.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Social
import Accounts

class Session {
    
    static let baseURLString: String = "https://api.twitter.com"
    
    static let shared: Session = Session()

    private var oauthToken: String = ""
    private var oauthTokenSecret: String = ""
    private var oauthVerifier: String = ""
    private var userID: String?
    private var screenName: String?
    
    var secret: String {
        return "\(Credentials.consumerSecret)&\(self.oauthTokenSecret)"
    }
    
    func signature(method: String ,url: URL, params: [String: String]) -> String {
        let signingKey: String = self.secret
        
        // パラメータ取得してソート
        var parameterComponents: [String] = params.urlEncoded.components(separatedBy: "&") as [String]
        parameterComponents.sort { $0 < $1 }
        
        // query string作成
        let parameterString: String = parameterComponents.joined(separator: "&")
        let encodedParameterString: String = parameterString.urlEncoded
        let encodedURL: String = url.absoluteString.urlEncoded
        
        // signature用ベース文字列作成
        let signatureBaseString: String = "\(method)&\(encodedURL)&\(encodedParameterString)"
        return signatureBaseString.SHA1(key: signingKey).base64EncodedString()
    }
    
    struct Credentials {
        
        // Consumer
        static let consumerKey: String = ""
        static let consumerSecret: String = ""
        
        static let callback: String = "mssgr://"
        static let signatureMethod: String = "HMAC-SHA1"
        static let version: String = "1.0"
        
        static var base64TokenCredentials: String {
            let keyAndSecret: String = (
                Credentials.consumerKey.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                + ":"
                + Credentials.consumerSecret.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            )
            let data: Data = keyAndSecret.data(using: .ascii)!
            return data.base64EncodedString()
        }
    
    }
    
    enum SessionError: Error {
        case session(Error)
        case twitter([TwitterError])
    }
    
    private static let accessTokenKey: String = "MSSGR.access_token"
    
    static var accessToken: String? {
        guard let accessToken: String = UserDefaults.standard.value(forKey: Session.accessTokenKey) as? String else {
            return nil
        }
        guard !accessToken.isEmpty else {
            return nil
        }
        return accessToken
    }
    
    static var isAuthorized: Bool {
        guard let _ = authorizedSession() else {
            return false
        }
        return true
    }
    
    class func authorizedSession() -> URLSession? {
        guard let accessToken: String = Session.accessToken else {
            return nil
        }
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Authorization": "Bearer " + accessToken
        ]
        return URLSession(configuration: configuration)
    }

    class func oauth(block: @escaping () -> Void) -> URLSessionDataTask? {
        
        if isAuthorized {
            block()
            return nil
        }
        
        let authToken: String = Credentials.base64TokenCredentials
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Authorization": "Basic " + authToken,
            "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"
        ]
        let session: URLSession = URLSession(configuration: configuration)
        
        let url: URL = URL(string: baseURLString + "/oauth2/token")!
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        let body: String = "grant_type=client_credentials"
        request.httpBody = body.data(using: .utf8)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            defer {
                session.invalidateAndCancel()
            }
            if let error: Error = error {
                print(error)
                return
            }
            guard let data: Data = data else {
                return
            }
            do {
                let json: [AnyHashable: Any] = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
                let accessToken: String = json["access_token"] as! String
                DispatchQueue.main.async {
                    UserDefaults.standard.set(accessToken, forKey: self.accessTokenKey)
                    UserDefaults.standard.synchronize()
                    block()
                }
                
            } catch let jsonError {
                print(jsonError)
            }
            
        }
        task.resume()
        return task
    }
    
    class func authorizeHeader(method: String, url: URL, params: [String: String]) -> String {
        var authorizationParameters: [String: String] = params
        authorizationParameters["oauth_version"] = Credentials.version
        authorizationParameters["oauth_signature_method"] = Credentials.signatureMethod
        authorizationParameters["oauth_consumer_key"] = Credentials.consumerKey
        authorizationParameters["oauth_timestamp"] = String(Int64(NSDate().timeIntervalSince1970))
        let uuid: String = UUID().uuidString
        authorizationParameters["oauth_nonce"] = uuid.substring(to: uuid.index(uuid.startIndex, offsetBy: 8))
        
        for (key, value) in authorizationParameters where key.hasPrefix("oauth_") {
            authorizationParameters.updateValue(value, forKey: key)
        }
        
        // 証明書
        authorizationParameters["oauth_signature"] = Session.shared.signature(method: method, url: url, params: authorizationParameters)
        
        // アルファベット順に並べ替える
        var authorizationParameterComponents: [String] = authorizationParameters.urlEncoded.components(separatedBy: "&") as [String]
        authorizationParameterComponents.sort { $0 < $1 }
        
        // リクエスト文字列作成
        var headerComponents: [String] = []
        for component in authorizationParameterComponents {
            let subcomponent: [String] = component.components(separatedBy: "=") as [String]
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }
        
        let oauth: String = "OAuth " + headerComponents.joined(separator: ", ")
        return oauth
    }
    
    class func oauthRequestToken(block: @escaping (SessionError?) -> Void) -> URLSessionDataTask? {
        
        // リクエストURL設定
        let url: URL = URL(string: "https://api.twitter.com/oauth/request_token")!
        
        // request
        var request : URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let params: [String: String] = ["oauth_callback": "mssgr://"]
        let oauth: String = authorizeHeader(method: request.httpMethod!, url: url, params: params)
        request.setValue(oauth, forHTTPHeaderField: "Authorization")
        
        let session: URLSession = URLSession.shared
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            defer {
                session.invalidateAndCancel()
            }
            if let error: Error = error {
                print(error)
                return
            }
            guard let data: Data = data else {
                return
            }
            let responseString: String = String(data: data, encoding: .utf8)!
            let responseObjects: [String: String] = responseString.parameters
            let oauthToken: String = responseObjects["oauth_token"]!
            oauthAuthorize(oauthToken: oauthToken, block: { (error) in
                block(error)
            })
        }
        task.resume()
        return task
    }
    
    class func oauthAuthorize(oauthToken: String, block: @escaping (SessionError?) -> Void) {
        
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "mssgr.oauth.notification"), object: nil, queue: .main) { (notification) in
            NotificationCenter.default.removeObserver(self)
            let url: URL = notification.userInfo!["mssgr.callback.key"] as! URL
            let parames: [String: String] = url.query!.parameters
            Session.shared.oauthVerifier = parames["oauth_verifier"]!
            _ = oauthAccessToken(params: parames, block: { (error) in
                block(error)
            })
        }
        
        let url: URL = URL(string: "https://api.twitter.com/oauth/authorize?oauth_token=\(oauthToken)")!
        UIApplication.shared.openURL(url)
    }

    class func oauthAccessToken(params: [String: String], block: @escaping (SessionError?) -> Void) -> URLSessionDataTask? {
        
        // リクエストURL設定
        let url: URL = URL(string: "https://api.twitter.com/oauth/access_token")!
        
        // request
        var request : URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let oauth: String = authorizeHeader(method: request.httpMethod!, url: url, params: params)
        request.setValue(oauth, forHTTPHeaderField: "Authorization")
        
        let session: URLSession = URLSession.shared
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            defer {
                session.invalidateAndCancel()
            }
            if let error: Error = error {
                block(.session(error))
                return
            }
            guard let data: Data = data else {
                return
            }
            let responseString: String = String(data: data, encoding: .utf8)!
            let parames: [String: String] = responseString.parameters
            Session.shared.oauthToken = parames["oauth_token"]!
            Session.shared.oauthTokenSecret = parames["oauth_token_secret"]!
            Session.shared.userID = parames["user_id"]!
            Session.shared.screenName = parames["screen_name"]!
            block(nil)
        }
        task.resume()
        return task
        
    }
    
    /**
     get followers
     - parmater count: followers list limit count
     - parmeter block: callback
     */
    class func homeTimeline(count: Int = 100, block: @escaping (([User], SessionError?) -> Void)) -> URLSessionDataTask? {
        
        guard let screenName: String = Session.shared.screenName else {
            return nil
        }
        
        let url: URL = URL(string: baseURLString + "/1.1/statuses/home_timeline.json")!
        var request: URLRequest = URLRequest(url: URL(string: url.absoluteString + "?count=\(count)")!)
        request.httpMethod = "GET"

        let params: [String: String] = [
            "count": String(count),
            "oauth_token": Session.shared.oauthToken,
            "oauth_verifier": Session.shared.oauthVerifier
        ]
        let oauth: String = authorizeHeader(method: request.httpMethod!, url: url, params: params)
        request.setValue(oauth, forHTTPHeaderField: "Authorization")
        
        let session: URLSession = URLSession.shared
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            defer {
                session.invalidateAndCancel()
            }
            if let error: Error = error {
                DispatchQueue.main.async {
                    block([], .session(error))
                }
                return
            }
            guard let data: Data = data else {
                return
            }
        
            do {
                let json: Any = try JSONSerialization.jsonObject(with: data, options: [])
                if let data: [AnyHashable: Any] = json as? [AnyHashable: Any] {
                    if let errors: [[AnyHashable: Any]] = data["errors"] as? [[AnyHashable: Any]] {
                        print(errors)
                        let twitterErrors: [TwitterError] = errors.map({ return TwitterError($0) })
                        DispatchQueue.main.async {
                            block([], .twitter(twitterErrors))
                        }
                        return
                    }
                } else if let data: [[AnyHashable: Any]] = json as? [[AnyHashable: Any]] {
                    print(data)
                }
            } catch let jsonError {
                print(jsonError)
            }
            
        }
        task.resume()
        return task
    }
    

    /**
     get followers
     - parmater cursor: followers list cursor
     - parmater count: followers list limit count
     - parmeter block: callback
    */
    class func followers(cursor: String = "-1", count: Int = 100, block: @escaping (([User], String, SessionError?) -> Void)) -> URLSessionDataTask? {
        
        guard let screenName: String = Session.shared.screenName else {
            return nil
        }
        
        let url: URL = URL(string: baseURLString + "/1.1/followers/list.json")!
        var request: URLRequest = URLRequest(url: URL(string: url.absoluteString + "?screen_name=\(screenName)")!)
        request.httpMethod = "GET"
        
        let params: [String: String] = [
            "screen_name": screenName,
            "oauth_token": Session.shared.oauthToken,
            "oauth_verifier": Session.shared.oauthVerifier
        ]
        let oauth: String = authorizeHeader(method: request.httpMethod!, url: url, params: params)
        request.setValue(oauth, forHTTPHeaderField: "Authorization")
        
        let session: URLSession = URLSession.shared
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            defer {
                session.invalidateAndCancel()
            }
            if let error: Error = error {
                DispatchQueue.main.async {
                    block([], cursor, .session(error))
                }
                return
            }
            guard let data: Data = data else {
                return
            }
            do {
                let json: [AnyHashable: Any] = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
                
                if let errors: [[AnyHashable: Any]] = json["errors"] as? [[AnyHashable: Any]] {
                    print(errors)
                    let twitterErrors: [TwitterError] = errors.map({ return TwitterError($0) })
                    DispatchQueue.main.async {
                        block([], cursor, .twitter(twitterErrors))
                    }
                    return
                }
                
                let cursor: String = json["next_cursor_str"] as! String
                let usersObjects: [[AnyHashable: Any]] = json["users"] as! [[AnyHashable: Any]]
                let users: [User] = usersObjects.map({ return User($0) })
                DispatchQueue.main.async {
                    block(users, cursor, nil)
                }
                
            } catch let jsonError {
                print(jsonError)
            }
            
        }
        task.resume()
        return task
    }
    
    /**
     get messages
     - parmater sinceID: message since_id
     - parmater count: followers list limit count
     - parmeter block: callback
     */
    class func messages(sinceID: String = "0", count: Int = 1, block: @escaping (([Message], SessionError?) -> Void)) -> URLSessionDataTask? {

        let url: URL = URL(string: baseURLString + "/1.1/direct_messages.json")!
        var request: URLRequest = URLRequest(url: URL(string: url.absoluteString/* + "?count=\(count)"*/)!)
        request.httpMethod = "GET"
        
        let params: [String: String] = [
            //            "count": String(count),
            //            "curosr": cursor,
            "oauth_token": Session.shared.oauthToken,
            "oauth_verifier": Session.shared.oauthVerifier
        ]
        let oauth: String = authorizeHeader(method: request.httpMethod!, url: url, params: params)
        request.setValue(oauth, forHTTPHeaderField: "Authorization")
        
        let session: URLSession = URLSession.shared
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            defer {
                session.invalidateAndCancel()
            }
            if let error: Error = error {
                DispatchQueue.main.async {
                    block([], .session(error))
                }
                return
            }
            guard let data: Data = data else {
                return
            }
            do {
                if let json: [AnyHashable: Any] = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any] {
                    if let errors: [[AnyHashable: Any]] = json["errors"] as? [[AnyHashable: Any]] {
                        print(errors)
                        let twitterErrors: [TwitterError] = errors.map({ return TwitterError($0) })
                        DispatchQueue.main.async {
                            block([], .twitter(twitterErrors))
                        }
                    }
                    return
                }
                
                let json: [[AnyHashable: Any]] = try JSONSerialization.jsonObject(with: data, options: []) as! [[AnyHashable: Any]]
                let messages: [Message] = json.map({ return Message($0) })
                DispatchQueue.main.async {
                    block(messages, nil)
                }
                
            } catch let jsonError {
                print(jsonError)
            }
            
        }
        task.resume()
        return task
    }
    
}

extension Dictionary {
    
    var urlEncoded: String {
        var parts: [String] = []
        for (key, value) in self {
            let keyString: String = "\(key)".urlEncoded
            let valueString: String = "\(value)".urlEncoded
            let query = "\(keyString)=\(valueString)" as String
            parts.append(query)
        }
        return parts.joined(separator: "&")
    }
    
}

extension String {
    var urlEncoded: String {
        let customAllowedSet =  CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        let escapedString = self.addingPercentEncoding(withAllowedCharacters: customAllowedSet)
        return escapedString!
    }
    
    var parameters: [String: String] {
        var response: [String: String] = [:]
        let objects: [String] = self.components(separatedBy: "&")
        objects.forEach { (string) in
            let object: [String] = string.components(separatedBy: "=")
            if object.count == 2 {
                response[object[0]] = object[1]
            }
        }
        return response
    }
    
}
