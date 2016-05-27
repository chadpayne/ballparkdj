//
//  VoiceProviderLogin.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/22/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation

public class VoiceProviderLogin : NSObject
{
    public static func login()
    {
        guard let djAppDelegate = UIApplication.sharedApplication().delegate as? DJAppDelegate else { return }
        
        let voiceProviderStoryBoard = UIStoryboard(name: "VoiceProvider", bundle: nil)
        
        djAppDelegate.window.rootViewController = voiceProviderStoryBoard.instantiateInitialViewController()
    }

    
    public static func login(url:NSURL)
    {
        let urlComponents = NSURLComponents(string: url.absoluteString)
        let queryItems = urlComponents?.queryItems

        let paramUser = queryItems?.filter({$0.name == "user"}).first
        let paramPassword = queryItems?.filter({$0.name == "password"}).first

        guard let user = paramUser?.value else { return }
        guard let password = paramPassword?.value else { return }
        
        DJOrderBackendService.login(user, password: password) { authToken, error in
            DJOrderBackendService.getRecordingOrders(authToken)
            {
                orders, error in
                    processOrders(orders)
            }
        }
    }
    
    public static func login(user:String,password:String)
    {
        DJOrderBackendService.login(user, password: password) { authToken, error in
            DJOrderBackendService.getRecordingOrders(authToken)
            {
                orders, error in
                processOrders(orders)
            }
        }
    }
    
    
    public static func processOrders(orders:[DJVoiceOrder]!)
    {
        guard let orders = orders else { return; }

        let teamUploader = DJTeamUploader()
        
        for order in orders
        {
            // Download - Import each team
            teamUploader.performImportTeam(order.teamId!)
            {
                team in
                    print(team);
            }
            
        }
        
    }
}

