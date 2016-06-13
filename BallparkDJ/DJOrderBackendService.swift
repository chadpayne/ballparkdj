//
//  DJOrderBackendService.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/21/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation

@objc public class DJOrderBackendService : NSObject
{
    public static func login(user:String, password:String, completion: (String!, NSError?) -> Void)
    {
        let serverURL = NSURL(string: "\(DJServerInfo.baseServerURL)/restuser/login")
        let request = NSMutableURLRequest(URL: serverURL!)
        
        request.HTTPMethod = "POST"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var loginDict = [String:AnyObject]()
        loginDict["name"] = user
        loginDict["password"] = password
        
        let httpBody = try! NSJSONSerialization.dataWithJSONObject(loginDict, options: .PrettyPrinted)
        
        let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: httpBody)
        {
            data, response, error in
            if (error != nil)
            {
                completion(nil,error!)
                return;
            }
            
            if let tokenData = data
            {
                let tokenString = String(data: tokenData, encoding: NSUTF8StringEncoding)
                print("\(tokenString)")
                
                let resultsDict = try! NSJSONSerialization.JSONObjectWithData(tokenData, options: NSJSONReadingOptions.MutableLeaves)
                
                completion(resultsDict["token"] as? String, nil)
            }
            else
            {
                completion(nil,nil)
            }
        }
        task.resume()
    }
    
    public static func getRecordingOrders(authToken:String, completion: ([DJVoiceOrder]!, NSError?) -> Void)
    {
        let serverURL = NSURL(string: "\(DJServerInfo.baseServerURL)/admin-api/recordingOrder")
        let request = NSMutableURLRequest(URL: serverURL!)
        
        request.HTTPMethod = "GET"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request)
        {
            data, response, error in
            if (error != nil)
            {
                completion(nil,error!)
                return;
            }
            
            if let orderData = data
            {
                let orderDataString = String(data: orderData, encoding: NSUTF8StringEncoding)
                print("\(orderDataString)")
                
                let resultsDict = try! NSJSONSerialization.JSONObjectWithData(orderData, options: NSJSONReadingOptions.MutableLeaves)
                
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

    
    public static func markOrderComplete(authToken:String, order:DJVoiceOrder, completion: (DJVoiceOrder!, NSError?) -> Void)
    {
        let serverURL = NSURL(string: "\(DJServerInfo.baseServerURL)/admin-api/recordingOrder")
        let request = NSMutableURLRequest(URL: serverURL!)
        
        request.HTTPMethod = "PUT"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        order.orderStatus = DJVoiceOrderStatus.VOICED
        
        guard let orderData = order.toJSON() else { completion(nil,nil); return; }
        let orderDataString = String(data: orderData, encoding: NSUTF8StringEncoding)
        print("\(orderDataString)")
        
        let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: orderData)
        {
            data, response, error in
            if (error != nil)
            {
                completion(nil,error!)
                return;
            }
            
            if let orderData = data
            {
                let orderDataString = String(data: orderData, encoding: NSUTF8StringEncoding)
                print("\(orderDataString)")
                
                if let resultsDict = try! NSJSONSerialization.JSONObjectWithData(orderData, options: NSJSONReadingOptions.MutableLeaves) as? [String:AnyObject]
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
        }
        task.resume()
    }
    
    public static func getPurchasedVoiceOrder(orderId:String, completion: (DJVoiceOrder!, NSError?) -> Void)
    {
        let serverURL = NSURL(string: "\(DJServerInfo.baseServerURL)/ordervoice/\(orderId)")
        let request = NSMutableURLRequest(URL: serverURL!)
        
        request.HTTPMethod = "GET"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request)
        {
            data, response, error in
            if (error != nil)
            {
                completion(nil,error!)
                return;
            }
            
            if let orderData = data
            {
                let orderDataString = String(data: orderData, encoding: NSUTF8StringEncoding)
                print("\(orderDataString)")
                
                let resultsDict = try! NSJSONSerialization.JSONObjectWithData(orderData, options: NSJSONReadingOptions.MutableLeaves)
                
                if let dict = resultsDict as?  [String:AnyObject]
                {
                    let voiceOrder = DJVoiceOrder(dictionary: dict)
                    completion(voiceOrder,nil)
                    return
                }
                
                completion(nil, nil)
            }
            else
            {
                completion(nil,nil)
            }
        }
        task.resume()
    }

    
}