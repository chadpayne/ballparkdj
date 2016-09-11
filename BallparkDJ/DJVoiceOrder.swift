//
//  DJVoiceOrder.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/22/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation

enum DJVoiceOrderStatus : String
{
    case NEW = "NEW"
    case VOICING = "VOICING"
    case PAID = "PAID"
    case REVOICING = "REVOICING"
    case SHARED = "SHARED"
    case VOICED = "VOICED"
}

enum PlayerVoiceFormat : String
{
    case NOW_BATTING_PLAYERNUMBER_PLAYERNAME = "NOW_BATTING_PLAYERNUMBER_PLAYERNAME"
    case NOW_BATTING_FORTEAM_PLAYERNUMBER_PLAYERNAME = "NOW_BATTING_FORTEAM_PLAYERNUMBER_PLAYERNAME"
    case PLAYERNUMBER_PLAYERNAME = "PLAYERNUMBER_PLAYERNAME"
}

public class DJVoiceOrder : NSObject
{
    var voiceProviderId:String?
    var orderId:String?
    var teamId:String?
    var teamName:String?
    var teamOwnerEmail:String?
    var orderStatus:DJVoiceOrderStatus
    var playerVoiceFormat:PlayerVoiceFormat
    var orderCompletionDate:NSDate?
    var revoicingAvailable:Bool?
    var revoicingExpirationDate:NSDate?
    
    
    init(orderId:String, voiceProviderId:String, teamName:String, teamOwnerEmail:String, orderStatus:DJVoiceOrderStatus, teamId:String, revoicingAvailable:Bool, playerVoiceFormat:PlayerVoiceFormat)
    {
        self.orderId = orderId
        self.voiceProviderId = voiceProviderId
        self.teamId = teamId
        self.teamName = teamName
        self.teamOwnerEmail = teamOwnerEmail
        self.revoicingAvailable = revoicingAvailable
        self.orderStatus = orderStatus
        self.playerVoiceFormat = playerVoiceFormat
    }

    init (dictionary:[String:AnyObject])
    {
        orderId = dictionary["id"] as? String
        voiceProviderId = dictionary["voiceProviderId"] as? String
        teamName = dictionary["teamName"] as? String
        teamOwnerEmail = dictionary["teamOwnerEmail"] as? String
        teamId = dictionary["teamId"] as? String
        
        orderStatus = .NEW
        if let orderStatusString = dictionary["status"] as? String
        {
            if let tmpOrderStatus =  DJVoiceOrderStatus(rawValue: orderStatusString)
            {
                orderStatus = tmpOrderStatus
            }
        }
        
        playerVoiceFormat = .NOW_BATTING_PLAYERNUMBER_PLAYERNAME
        if let voiceFormatString = dictionary["voiceFormat"] as? String
        {
            if let tmpVoiceFormat =  PlayerVoiceFormat(rawValue: voiceFormatString)
            {
                playerVoiceFormat = tmpVoiceFormat
            }
        }
        
        
        revoicingAvailable = dictionary["revoicingAvailable"] as? Bool
        
        if let revoiceMilliSeconds = dictionary["revoicingExpirationDate"] as? NSTimeInterval
        {
            let revoiceSeconds = revoiceMilliSeconds / 1000.0
            revoicingExpirationDate = NSDate(timeIntervalSince1970: revoiceSeconds)
        }
 
        if let orderCompleteMilliSeconds = dictionary["orderCompletionDate"] as? NSTimeInterval
        {
            let orderCompleteSeconds = orderCompleteMilliSeconds / 1000.0
            orderCompletionDate = NSDate(timeIntervalSince1970: orderCompleteSeconds)
        }
    }
    
    func toDictionary() -> [String:AnyObject]
    {
        var dict = [String:AnyObject]()
       
        dict["id"] = orderId
        dict["teamName"] = teamName
        dict["voiceProvierId"] = voiceProviderId
        dict["teamOwnerEmail"] = teamOwnerEmail
        dict["status"] = orderStatus.rawValue
        dict["teamId"] = teamId
        
        return dict
        
    }

    func toJSON() -> NSData?
    {
        do
        {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(toDictionary(), options: .PrettyPrinted)
            return jsonData
        }
        catch _ as NSError
        {
            
        }
        
        return nil
    }
    
}