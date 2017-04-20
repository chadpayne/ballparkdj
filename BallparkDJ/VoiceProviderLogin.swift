//
//  VoiceProviderLogin.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/22/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation

open class VoiceProviderLogin : NSObject
{
    open static func login()
    {
        guard let djAppDelegate = UIApplication.shared.delegate as? DJAppDelegate else { return }
        
        let voiceProviderStoryBoard = UIStoryboard(name: "VoiceProvider", bundle: nil)
        
        djAppDelegate.window.rootViewController = voiceProviderStoryBoard.instantiateInitialViewController()
    }
}

