//
//  File.swift
//  EasyAPNS
//
//  Created by Damian Malarczyk on 04.07.2016.
//
//
#if os(Linux)
    @_exported import Glibc
#else
    @_exported import Darwin.C
#endif
import CCurl
import Foundation

/**
 */
open class cURLConnection {
    
    /**
     connection's curl reference
     */
    public let curl: cURL
    
    /**
     absolute path to certificate which is to be used during connection
     */
    public var certificatePath: String? = nil {
        didSet {
            certificatePath = didSet(certificatePath: certificatePath)
            
        }
    }
    
    public func didSet(certificatePath: String?) -> String? {
        let real = certificatePath?.realPath()

        curl.set(.sslCert, value: real)
        if real != nil {
            useSSL = true
        }
        
        return real
    }
    
    public var keyPath: String? = nil {
        didSet {
            keyPath = didSet(keyPath: keyPath)
        }
    }
    
    public func didSet(keyPath: String?) -> String? {
        let real = keyPath?.realPath()
        curl.set(.sslKey, value: real)
        return real
            
    }
    
    /**
     custom user-agent
     */
    public var userAgent: String? = nil {
        didSet {
            didSet(userAgent: userAgent)
        }
    }
    
    public func didSet(userAgent: String?) {
        curl.set(.userAgent, value: userAgent)
    }
    
    /**
     optional certificate's passphrase
     */
    public var certificatePassphrase: String? = nil {
        didSet {
            didSet(certificatePassphrase: certificatePassphrase)
        }
    }
    
    public func didSet(certificatePassphrase: String?) {
        curl.set(.passPhrase, value: certificatePassphrase)
    }

    
    /**
     path to certificate authority file
     */
    public var caCertificatePath: String? = nil {
        didSet {
            caCertificatePath = didSet(caCertificatePath: caCertificatePath)
        }
    }
    
    public func didSet(caCertificatePath: String?) -> String? {
        let real = caCertificatePath?.realPath()
        curl.set(.sslVerifyPeer, value: real != nil)
        curl.set(.caPath, value: real)
        return real
        
    }
    
    /**
     request url
     */
    public var url: String {
        didSet {
            didSet(url: url)
        }
    }
    
    public func didSet(url: String) {
            curl.set(.url, value: url)
    }
    
    /**
     request port
     */
    public var port: Int? = nil {
        didSet {
            didSet(port: port)
        }
    }
    
    public func didSet(port: Int?) {
        if let p = port {
            curl.set(.port, value: p)
        } else {
            curl.set(.port, value: nil)
        }

    }
    
    /**
     request's maximum timeout
     */
    public var timeout: Int {
        didSet {
            didSet(timeout: timeout)
        }
    }
    
    public func didSet(timeout: Int) {
        curl.set(.timeout, value: timeout)
    }
    
    public var useSSL: Bool
    
    public func didSet(useSSL: Bool) {
        curl.set(.sslVerifyHost, value: useSSL ? 2 : 0)
        curl.set(.useSsl, value: useSSL)
        curl.set(.sslEngineDefault, value: useSSL)

    }
    
    /**
     - parameter certificatePath:String absolute path to certificate used to instantiate secure connection
     */
    public init(url: String, useSSL: Bool, certificatePath: String? = nil, keyPath: String? = nil, certificatePassphrase: String? = nil, caPath: String? = nil, timeout: Int = 20) {
        self.curl = cURL()
        self.timeout = timeout
        self.url = url
        self.useSSL = useSSL
        self.certificatePassphrase = certificatePassphrase
        self.caCertificatePath = didSet(caCertificatePath: caPath)
        self.certificatePath = didSet(certificatePath: certificatePath)
        self.keyPath = didSet(keyPath: keyPath)

        
        didSet(useSSL: useSSL)
        didSet(url: url)
        didSet(certificatePassphrase: certificatePassphrase)
        didSet(timeout: timeout)
        
    }
    
    public enum Error: Swift.Error {
        case incorrectURL
    }
    
    
    func setURLFrom(request: cURLRequest) throws {
        var urlString: String?

        var port: String?
        let cmp = URLComponents(url: request.url, resolvingAgainstBaseURL: true)
        
        if let urlStr: String = cmp?.string, let portRange = cmp?.rangeOfPort {
            
            let colonRange = Range<String.Index>(uncheckedBounds: (urlStr.index(before: portRange.lowerBound),portRange.upperBound))
            port = cmp?.string?.substring(with: portRange)
            urlString = cmp?.string
            urlString?.replaceSubrange(colonRange, with: "")
        } else {
            urlString = cmp?.string
        }
        
        guard let urlStr = urlString else {
            throw Error.incorrectURL
        }
        
        self.url = urlStr
        if let prt = port, let portValue = Int(prt) {
            self.port = portValue
        }
    }
    
    open func request(_ req: cURLRequest) throws -> cURLResponse? {
        
        try setURLFrom(request: req)
        let httpHeaders = req.headers.map {
            return "\($0.key): \($0.value)"
        }
        let curlSlist = cURLSlist(fromArray: httpHeaders)
        curl.setSlist(.httpHeader, value: curlSlist.rawSlist)
        curl.set(.get, value: false)
        curl.set(.post, value: false)
        curl.set(.delete, value: nil)

        if let body = req.body {
            body.withUnsafeBytes {
                curl.set(.postFields, value: $0)
            }
        }
        
        switch req.method {
        case .get:
            curl.set(.get, value: true)
        case .post:
            curl.set(.post, value: true)
        case .delete:
            curl.set(.delete, value: "DELETE")
        }
        
        
        let result = try curl.execute() // persist reference to header's slist 
        return result 
    }
}

