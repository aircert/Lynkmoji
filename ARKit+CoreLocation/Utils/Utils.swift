//
//  Utils.swift
//
//  Copyright © 2016-2017 Twilio, Inc. All rights reserved.
//

import Foundation
import UIKit

// Helper to determine if we're running on simulator or device
struct PlatformUtils {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}

struct TokenUtils {
    static func fetchToken(url : String) throws -> String {
        var token: String = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTS2YwZDA3ZThlZjdlMGVhN2Q4ZTMzNjUzMDlmYzU4NTU3LTE1NjUxNDgxMTAiLCJpc3MiOiJTS2YwZDA3ZThlZjdlMGVhN2Q4ZTMzNjUzMDlmYzU4NTU3Iiwic3ViIjoiQUM5ZDkyMmExMWRlNTFkYWE1NzJlMDNhODk4MzMwOTUwYSIsImV4cCI6MTU2NTE1MTcxMCwiZ3JhbnRzIjp7ImlkZW50aXR5IjoiTHluayIsInZpZGVvIjp7fX19.Y4h4HX3CE6s7YDYeC6sqc0_Jc9IpMfK_D4xeUoKJ9sM"
        let requestURL: URL = URL(string: url)!
        do {
            let data = try Data(contentsOf: requestURL)
            if let tokenReponse = String.init(data: data, encoding: String.Encoding.utf8) {
                token = tokenReponse
            }
        } catch let error as NSError {
            print ("Invalid token url, error = \(error)")
            throw error
        }
        return token
    }
}

class Utils {
    fileprivate init () { }
    
    class func getStoryboard(_ storyboard: String = "Main") -> UIStoryboard {
        return UIStoryboard(name: storyboard, bundle: Bundle.main)
    }
    
    class func createViewController<T: UIViewController>(_ identifier: String, storyboard: String = "Main") -> T {
        return Utils.getStoryboard(storyboard)
            .instantiateViewController(withIdentifier: identifier) as! T // swiftlint:disable:this force_cast
    }
}

