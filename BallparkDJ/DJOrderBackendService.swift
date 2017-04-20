//
//  DJOrderBackendService.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/21/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation

@objc open class DJOrderBackendService : NSObject
{
    open static func login(_ user:String, password:String, completion: @escaping (String?, Error?) -> Void)
    {
        let serverURL = URL(string: "\(DJServerInfo.baseServerURL)/restuser/login")
        let request = NSMutableURLRequest(url: serverURL!)
        
        request.httpMethod = "POST"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var loginDict = [String:Any]()
        loginDict["name"] = user
        loginDict["password"] = password
        
        let httpBody = try! JSONSerialization.data(withJSONObject: loginDict, options: .prettyPrinted)
        
        let task = URLSession.shared.uploadTask(with: request as URLRequest, from: httpBody, completionHandler: {
            data, response, error in
            if (error != nil)
            {
                completion(nil,error)
                return;
            }
            
            if let tokenData = data
            {
                let tokenString = String(data: tokenData, encoding: String.Encoding.utf8)
                print("\(String(describing: tokenString))")
                
                let resultsDict = try! JSONSerialization.jsonObject(with: tokenData, options: JSONSerialization.ReadingOptions.mutableLeaves) as? [String:Any]
                
                completion(resultsDict?["token"] as? String, nil)
            }
            else
            {
                completion(nil,nil)
            }
        })        

        task.resume()
    }
    
    open static func getRecordingOrders(_ authToken:String, completion: @escaping ([DJVoiceOrder]?, Error?) -> Void)
    {
        let serverURL = URL(string: "\(DJServerInfo.baseServerURL)/admin-api/recordingOrder")
        let request = NSMutableURLRequest(url: serverURL!)
        
        request.httpMethod = "GET"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            if (error != nil)
            {
                completion(nil,error)
                return;
            }
            
            if let orderData = data
            {
                let orderDataString = String(data: orderData, encoding: String.Encoding.utf8)
                print("\(orderDataString)")
                
                let resultsDict = try! JSONSerialization.jsonObject(with: orderData, options: JSONSerialization.ReadingOptions.mutableLeaves)
                
                var voiceOrders = [DJVoiceOrder]()
                
                if let resultsArrayOfDict = resultsDict as? [ [String:AnyObject] ]
                {
                    for dict in resultsArrayOfDict
                    {
                        let voiceOrder = DJVoiceOrder(dictionary: dict)
                        voiceOrders.append(voiceOrder)
                    }
                }
                
                completion(voiceOrders, nil)
            }
            else
            {
                completion(nil,nil)
            }
        }

        task.resume()
    }

    
    open static func markOrderComplete(_ authToken:String, order:DJVoiceOrder, completion: @escaping (DJVoiceOrder?, Error?) -> Void)
    {
        let serverURL = URL(string: "\(DJServerInfo.baseServerURL)/admin-api/recordingOrder")
        let request = NSMutableURLRequest(url: serverURL!)
        
        request.httpMethod = "PUT"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        order.orderStatus = DJVoiceOrderStatus.VOICED
        
        guard let orderData = order.toJSON() else { completion(nil,nil); return; }
        let orderDataString = String(data: orderData, encoding: String.Encoding.utf8)
        print("\(String(describing: orderDataString))")
        
        let task = URLSession.shared.uploadTask(with: request as URLRequest, from: orderData, completionHandler: {
            data, response, error in
            if (error != nil)
            {
                completion(nil,error)
                return;
            }
            
            if let orderData = data
            {
                let orderDataString = String(data: orderData, encoding: String.Encoding.utf8)
                print("\(String(describing: orderDataString))")
                
                if let resultsDict = try! JSONSerialization.jsonObject(with: orderData, options: JSONSerialization.ReadingOptions.mutableLeaves) as? [String:AnyObject]
                {
                    let voiceOrder = DJVoiceOrder(dictionary: resultsDict)
                    completion(voiceOrder, nil)
                    return
                }
                completion(nil, nil)
            }
            else
            {
                completion(nil,nil)
            }
        })        

        task.resume()
    }
    
    open static func getPurchasedVoiceOrder(_ orderId:String, completion: @escaping (DJVoiceOrder?, Error?) -> Void)
    {
        let serverURL = URL(string: "\(DJServerInfo.baseServerURL)/ordervoice/\(orderId)")
        let request = NSMutableURLRequest(url: serverURL!)
        
        request.httpMethod = "GET"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            if (error != nil)
            {
                completion(nil,error)
                return;
            }
            
            if let orderData = data
            {
                let orderDataString = String(data: orderData, encoding: String.Encoding.utf8)
                print("\(orderDataString)")
                
                do {
                    let resultsDict = try JSONSerialization.jsonObject(with: orderData, options: JSONSerialization.ReadingOptions.mutableLeaves)
                
                    if let dict = resultsDict as?  [String:AnyObject]
                    {
                        let voiceOrder = DJVoiceOrder(dictionary: dict)
                        completion(voiceOrder,nil)
                        return
                    }
                    
                    completion(nil, nil)
                } catch {
                    // ::TODO:: Return more descriptive error
                    completion(nil, nil)
                }
            }
            else
            {
                completion(nil,nil)
            }
        }

        task.resume()
    }

    
}
