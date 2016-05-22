//
//  DJVoiceOrder.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/22/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation

@objc public enum DJVoiceOrderStatus : Int
{
    case NEW
    case VOICING
    case PAID
    case REVOICING
    case SHARED
    case VOICED
}

public class DJVoiceOrder : NSObject
{
    var voiceProviderId:String!
    var orderId:String!
    var teamId:String!
    var teamName:String!
    var teamOwnerEmail:String!
    var orderStatus:DJVoiceOrderStatus!
    
    init(orderId:String, voiceProviderId:String, teamName:String, teamOwnerEmail:String, orderStatus:DJVoiceOrderStatus, teamId:String)
    {
        self.orderId = orderId
        self.voiceProviderId = voiceProviderId
        self.teamId = teamId
        self.teamName = teamName
        self.teamOwnerEmail = teamOwnerEmail
        self.orderStatus = orderStatus
    }

    init (dictionary:[String:AnyObject])
    {
        orderId = dictionary["id"] as? String
        voiceProviderId = dictionary["voiceProviderId"] as? String
        teamName = dictionary["teamName"] as? String
        teamOwnerEmail = dictionary["teamOwnerEmail"] as? String
        teamId = dictionary["teamId"] as? String
        orderStatus = dictionary["orderStatus"] as? DJVoiceOrderStatus
    }
    
    
}