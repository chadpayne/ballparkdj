//
//  DJTeamUploader.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 4/11/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation
import UIKit

public class DJTeamUploader : NSObject
{
    let baseServerURL = DJServerInfo.baseServerURL
    var operationQueue = NSOperationQueue()
    var HUD:MBProgressHUD!
    
    override init()
    {
    
    }
    
    func generateBoundaryString() -> String
    {
        return NSUUID().UUIDString
    }
    
    func fileURL(fileName:String) -> NSURL? {
        
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        // If array of path is empty the document folder not found
        guard urls.count != 0 else { return nil }
        
        let url = urls.first!.URLByAppendingPathComponent(fileName)
        return url
    }
    
    func createTeamDirectory(team:DJTeam)
    {
        let url = fileURL(team.teamId)
        
        if NSFileManager.defaultManager().fileExistsAtPath((url?.path)!) == false
        {
            try! NSFileManager.defaultManager().createDirectoryAtURL(url!, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func importTeamAudioFiles(team:DJTeam)
    {
        for player in team.players
        {
            if let url = player.audio?.announcementURL?.lastPathComponent
            {
                let myURL = NSURL(string: "\(baseServerURL)/teamfiles/\(team.teamId)/\(url)")

                let operation = DataTaskOperation.init(URL: myURL!)
                                {
                                    data, response, error in
                                    
                                    guard let httpResponse = response as? NSHTTPURLResponse else { return }
                                    guard httpResponse.statusCode == 200 else { return }
                                    
                                    
                                    player.audio?.announcementURL = self.fileURL("\(team.teamId)-\(url)")
                                    
                                    data?.writeToURL((player.audio?.announcementURL!)!, atomically: true)
                                    
                                    player.audio?.announcementClip = try! AVAudioPlayer(contentsOfURL:(player.audio?.announcementURL!)!)
                                    
                                    if player.audio?.isDJClip == true
                                    {
                                        if let audioURL = NSBundle.mainBundle().pathForResource(player.audio?.title, ofType: "m4a")
                                        {
                                            player.audio?.musicClip = try! AVAudioPlayer(contentsOfURL:NSURL(fileURLWithPath: audioURL))
                                        }

                                    }
                                }
                
                operationQueue.addOperation(operation)
            }
        }

        
        operationQueue.waitUntilAllOperationsAreFinished()
    }

    public func performImportTeam(teamID:String, completion:(team:DJTeam) -> ())
    {
        let serverURL = NSURL(string: "\(baseServerURL)/team/\(teamID)")
        let request = NSMutableURLRequest(URL: serverURL!)
        request.HTTPMethod = "GET"
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {data, response, error in
            
            if let teamDict = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableLeaves) as? [String:AnyObject]
            {
                let team = DJTeam()
                
                team.teamId = teamDict["id"] as? String
                team.teamName = teamDict["name"] as? String
                team.players = NSMutableArray()
                
                if let playersDict = teamDict["players"] as? [[String:AnyObject]]
                {
                    for playerDict in playersDict
                    {
                        let player = DJPlayer()
                        player.name = playerDict["name"] as? String
                        
                        if let playerNumber = playerDict["number"] as? NSNumber
                        {
                            player.number = playerNumber.intValue
                        }
                        
                        if let playerBenched = playerDict["benched"] as? NSNumber
                        {
                            player.b_isBench = playerBenched.boolValue
                        }
                        
                        if let audioDict = playerDict["playerAudio"] as? [String:AnyObject]
                        {
                            if let announcmentURL = audioDict["announcementUrl"] as? String
                            {
                                player.audio.announcementURL = self.fileURL("\(announcmentURL)")
                            }
                            
                            if let overlap = audioDict["overlap"] as? Double
                            {
                                player.audio.overlap = overlap
                            }
                            
                            if let musicStartTime = audioDict["musicStartTime"] as? Double
                            {
                                player.audio.musicStartTime = musicStartTime
                            }
                            
                            if let shouldFade = audioDict["shouldFade"] as? Bool
                            {
                                player.audio.shouldFade = shouldFade
                            }
                            
                            if let djFileName = audioDict["djFileName"] as? String
                            {
                                player.audio.DJAudioFileName = djFileName
                            }
                            
                            if let djClip = audioDict["djClip"] as? Bool
                            {
                                player.audio.isDJClip = djClip
                            }
                            
                            if let announcmentVolume = audioDict["announcmentVolume"] as? CGFloat
                            {
                                player.audio.announcementVolume = announcmentVolume
                            }
                            
                            if let shouldPlayAll = audioDict["shouldPlayAll"] as? Bool
                            {
                                player.audio.shouldPlayAll = shouldPlayAll
                            }
                            
                            if let title = audioDict["title"] as? String
                            {
                                player.audio.title = title
                            }
                            
                            if let musicVolume = audioDict["musicVolume"] as? CGFloat
                            {
                                player.audio.musicVolume = musicVolume
                            }
                            
                            if let currentVolumeMode = audioDict["currentVolumeMode"] as? Int32
                            {
                                player.audio.currentVolumeMode = currentVolumeMode
                            }
                            
                            if let announcementDuration = audioDict["announcmentDuration"] as? Double
                            {
                                if player.audio.isDJClip == false
                                {
                                    player.audio.announcementDuration = announcementDuration
                                }
                            }
                        }
                        team.players.addObject(player)
                    }
                }
                
                dispatch_async(dispatch_get_global_queue(0, 0))
                {
                    self.importTeamAudioFiles(team)
                    completion(team: team)
                }
            }
        }
        
        task.resume()
    }
    
    public func importTeam(teamID:String)
    {
        HUD = MBProgressHUD.showHUDAddedTo(DJAppDelegate.sharedDelegate().window, animated: true)
        DJAppDelegate.sharedDelegate().window.addSubview(HUD)
        HUD.labelText = "Importing..";
        HUD.show(true)

        
        let serverURL = NSURL(string: "\(baseServerURL)/team/\(teamID)")
        let request = NSMutableURLRequest(URL: serverURL!)
        request.HTTPMethod = "GET"
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {data, response, error in

            if let teamDict = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableLeaves) as? [String:AnyObject]
            {
                let team = DJTeam()
                
                team.teamId = teamDict["id"] as? String
                team.teamName = teamDict["name"] as? String
                team.players = NSMutableArray()
                
                if let playersDict = teamDict["players"] as? [[String:AnyObject]]
                {
                    for playerDict in playersDict
                    {
                        let player = DJPlayer()
                        player.name = playerDict["name"] as? String
                        
                        if let playerNumber = playerDict["number"] as? NSNumber
                        {
                            player.number = playerNumber.intValue
                        }
                        
                        if let playerBenched = playerDict["benched"] as? NSNumber
                        {
                            player.b_isBench = playerBenched.boolValue
                        }
                        
                        if let audioDict = playerDict["playerAudio"] as? [String:AnyObject]
                        {
                            if let announcmentURL = audioDict["announcementUrl"] as? String
                            {
                                player.audio.announcementURL = self.fileURL("\(announcmentURL)")
                            }
                            
                            if let overlap = audioDict["overlap"] as? Double
                            {
                                player.audio.overlap = overlap
                            }
                            
                            if let musicStartTime = audioDict["musicStartTime"] as? Double
                            {
                                player.audio.musicStartTime = musicStartTime
                            }
                            
                            if let shouldFade = audioDict["shouldFade"] as? Bool
                            {
                                player.audio.shouldFade = shouldFade
                            }
                            
                            if let djFileName = audioDict["djFileName"] as? String
                            {
                                player.audio.DJAudioFileName = djFileName
                            }

                            if let djClip = audioDict["djClip"] as? Bool
                            {
                                player.audio.isDJClip = djClip
                            }

                            if let announcmentVolume = audioDict["announcmentVolume"] as? CGFloat
                            {
                                player.audio.announcementVolume = announcmentVolume
                            }

                            if let shouldPlayAll = audioDict["shouldPlayAll"] as? Bool
                            {
                                player.audio.shouldPlayAll = shouldPlayAll
                            }
                            
                            if let title = audioDict["title"] as? String
                            {
                                player.audio.title = title
                            }

                            if let musicVolume = audioDict["musicVolume"] as? CGFloat
                            {
                                player.audio.musicVolume = musicVolume
                            }

                            if let currentVolumeMode = audioDict["currentVolumeMode"] as? Int32
                            {
                                player.audio.currentVolumeMode = currentVolumeMode
                            }
                            
                            if let announcementDuration = audioDict["announcmentDuration"] as? Double
                            {
                                if player.audio.isDJClip == false
                                {
                                    player.audio.announcementDuration = announcementDuration
                                }
                            }
                        }
                        team.players.addObject(player)
                    }
                }
                
                dispatch_async(dispatch_get_global_queue(0, 0))
                {
                    //self.createTeamDirectory(team)
                    self.importTeamAudioFiles(team)
      
                    dispatch_async(dispatch_get_main_queue()) {
                        if let appDelegate = UIApplication.sharedApplication().delegate as? DJAppDelegate
                        {
                            appDelegate.league.importTeam(team)
                        }
                        self.HUD.hide(true)
                    }
                }
            }
        }
        
        task.resume()
    }

    public func orderVoice(team:DJTeam, completion: (DJTeam) -> Void)
    {
        shareTeam(team) { team in
            if team.teamId != nil
            {
                let serverURL = NSURL(string: "\(self.baseServerURL)/ordervoice")
                let request = NSMutableURLRequest(URL: serverURL!)
                
                request.HTTPMethod = "POST"
                
                let contentType = "application/json"
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                
                var teamDict = [String:AnyObject]()
                if let teamID = team.teamId
                {
                    teamDict["teamId"] = teamID
                }
                teamDict["teamName"] = team.teamName
                teamDict["teamOwnerEmail"] = team.teamOwnerEmail
                
                let httpBody = try! NSJSONSerialization.dataWithJSONObject(teamDict, options: .PrettyPrinted)
                
                let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: httpBody)
                {
                    data, response, error in
                    if (error != nil)
                    {
                        // ::TODO:: Display error
                        print(error)
                        return;
                    }
                    
                    if let orderData = data
                    {
                        let orderString = String(data: orderData, encoding: NSUTF8StringEncoding)
                        print("\(orderString)")
                        
                        let resultsDict = try! NSJSONSerialization.JSONObjectWithData(orderData, options: NSJSONReadingOptions.MutableLeaves)
                        
                        if let orderId = resultsDict["id"] as? String
                        {
                            print("Success! - OrderID \(orderId)")
                        }
                        else
                        {
                            print("Error: \(resultsDict)")
                        }
                    }
                    else
                    {
                        // ::TODO:: Display error
                    }
                    
                    completion(team)
                }
                task.resume()
            }
            else
            {
                completion(team)
            }
        }
    }

    
    public func shareTeam(team:DJTeam, completion: (DJTeam) -> Void)
    {
        let serverURL = NSURL(string: "\(baseServerURL)/team")
        let request = NSMutableURLRequest(URL: serverURL!)

        request.HTTPMethod = "PUT"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var teamDict = [String:AnyObject]()
        if let teamID = team.teamId
        {
            teamDict["id"] = teamID
        }
        teamDict["name"] = team.teamName
        teamDict["teamOwnerEmail"] = team.teamOwnerEmail
        
        var playersDict = [[String:AnyObject]]()
        
        for player in team.players
        {
            var playerDict = [String:AnyObject]()
            playerDict["name"] = player.name
            
            playerDict["number"] = player.number!
            playerDict["benched"] = NSNumber(bool: player.b_isBench)
            
            var audioDict = [String:AnyObject]()
            if let audio = player.audio
            {
                if let announcementURL = audio?.announcementClip?.url?.lastPathComponent
                {
                    audioDict["announcementUrl"] = announcementURL
                }
                audioDict["overlap"] = audio.overlap
                audioDict["musicStartTime"] = audio.musicStartTime
                audioDict["musicDuration"] = audio.musicDuration
                audioDict["shouldFade"] = audio.shouldFade
                audioDict["djFileName"] = audio.DJAudioFileName
                audioDict["djClip"] = audio.isDJClip
                audioDict["announcmentVolume"] = audio.announcementVolume
                audioDict["shouldPlayAll"] = audio.shouldPlayAll
                audioDict["title"] = audio.title
                audioDict["musicVolume"] = audio.musicVolume
                audioDict["currentVolumeMode"] = NSNumber(int:audio.currentVolumeMode)
                audioDict["announcmentDuration"] = audio.announcementDuration
            }
            playerDict["playerAudio"] = audioDict
            
            playersDict.append(playerDict)
        }

        teamDict["players"] = playersDict
        
        
        let httpBody = try! NSJSONSerialization.dataWithJSONObject(teamDict, options: .PrettyPrinted)
        
        let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: httpBody)
        {
           data, response, error in
           if (error != nil)
            {
                // ::TODO:: Display error
                print(error)
                return;
            }
            
            if let teamData = data
            {
                let resultsDict = try! NSJSONSerialization.JSONObjectWithData(teamData, options: NSJSONReadingOptions.MutableLeaves)
                
                if let teamID = resultsDict["id"] as? String
                {
                    team.teamId = teamID
                    print("Success!")
                    self.shareTeamFiles(team,completion: completion)
                }
                else
                {
                    print("Error: \(resultsDict)")
                }
                
            }
            else
            {
                // ::TODO:: Display error
            }

        }
        
        task.resume()
    }

    
    public func shareTeamFiles(team:DJTeam, completion: (DJTeam) -> Void)
    {
        let boundary = generateBoundaryString()
        
        let serverURL = NSURL(string: "\(baseServerURL)/uploadTeamFiles")
        let request = NSMutableURLRequest(URL: serverURL!)
        
        request.HTTPMethod = "POST"
        
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var params = [String:String]()
        var paths = [NSURL]()

        params["teamId"] = team.teamId
        
        for player in team.players
        {
            if let announcementURL = player.audio?.announcementClip?.url
            {
                paths.append(announcementURL)
            }

        }

        let httpBody = createBodyWithBoundary(boundary, params: params, paths: paths, fieldName: "file")
        
        let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: httpBody)
        {
            data, response, error in
            if ((error) != nil)
            {
                print(error)
                return;
            }
            
            let result = NSString(data: data!
                , encoding: NSUTF8StringEncoding)
            print(result)
            
            completion(team)
        }
        
        task.resume()
    }
    
    func createBodyWithBoundary(boundary:String, params:[String:String], paths:[NSURL], fieldName:String) -> NSData
    {
        let httpBody = NSMutableData()
        
        for (key,value) in params
        {
            httpBody.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            httpBody.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            httpBody.appendData("\(value)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }

        for path in paths
        {
            let filename = NSString(string: path.absoluteString).lastPathComponent
            let data = NSData(contentsOfURL:  path)
            let mimetype = "application/octet-stream"
            
            httpBody.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            httpBody.appendData("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)

            httpBody.appendData("Content-Transfer-Encoding: \(mimetype)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            
            httpBody.appendData(data!)
            httpBody.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        
        httpBody.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        return httpBody
    }
    
}