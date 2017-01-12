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
    static let baseServerURL = DJServerInfo.baseServerURL
    var operationQueue = NSOperationQueue()
    var HUD:MBProgressHUD!
    var inInAppPurchaseAction:Bool = false
    
    public static var sharedInstance:DJTeamUploader = DJTeamUploader()
    
    override init()
    {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(onFinishPurchase), name: "InAppPurchase", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(onFinishRestore), name: "RestoreInAppPurchase", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(onFinishFailPurchase), name: "FailedInAppPurchase", object: nil)
        
    }
    
    static func generateBoundaryString() -> String
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
                let myURL = NSURL(string: "\(DJServerInfo.baseServerURL)/teamfiles/\(team.teamId)/\(url)")

                let operation = DataTaskOperation.init(URL: myURL!)
                                {
                                    data, response, error in
                                    
                                    guard let httpResponse = response as? NSHTTPURLResponse else { return }
                                    guard httpResponse.statusCode == 200 || httpResponse.statusCode == 302 else { return }
                                    
                                    
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
    }
    
    public func parseTeamFromData(data:NSData) -> DJTeam?
    {
        if let teamDict = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableLeaves) as? [String:AnyObject]
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
                    
                    if let revoicePlayer = playerDict["revoicePlayer"] as? Bool
                    {
                        player.revoicePlayer = revoicePlayer
                    }

                    if let addOnVoice = playerDict["addOnVoice"] as? Bool
                    {
                        player.addOnVoice = addOnVoice
                    }
                    
                    if let uuid = playerDict["uuid"] as? String
                    {
                        player.uuid = uuid
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
                            player.audio.announcementDuration = announcementDuration
                        }
                    }
                    team.players.addObject(player)
                }
            }
            
            return team;
        }
        
        return nil;
    }

    public func performImportTeams(teamIDs:[String], completion:(teams:[DJTeam]) -> ())
    {
        dispatch_async(dispatch_get_global_queue(0, 0))
        {
            var teams:[DJTeam] = [DJTeam]()
            
            for teamID in teamIDs
            {
                let serverURL = NSURL(string: "\(DJServerInfo.baseServerURL)/team/\(teamID)")
                
                let operation = DataTaskOperation.init(URL: serverURL!)
                                {
                                    data, response, error in
                                    
                                    guard let httpResponse = response as? NSHTTPURLResponse else { return }
                                    guard httpResponse.statusCode == 200 || httpResponse.statusCode == 302 else { return }
                                    
                                    guard let data = data else { return }
                                    if let team = self.parseTeamFromData(data)
                                    {
                                        teams.append(team)
                                        self.importTeamAudioFiles(team)
                                    }
                                }
                self.operationQueue.addOperation(operation)
            }
            
            self.operationQueue.waitUntilAllOperationsAreFinished()
            
            completion(teams: teams)
        }
    }

    public func importOrder(voiceOrder:DJVoiceOrder)
    {
        importTeam(voiceOrder.teamId) {
            team in
            
            if let expirationDate = voiceOrder.revoicingExpirationDate
            {
                team.orderRevoiceExpirationDate = expirationDate
                team.orderId = voiceOrder.orderId!
            }
        }
    }

    public func importTeam(teamID:String?)
    {
        importTeam(teamID, completionBlock: nil)
    }

    
    public func importTeam(teamID:String?, completionBlock:((team:DJTeam) -> ())?)
    {
        guard let teamID = teamID else { return }
        
        HUD = MBProgressHUD.showHUDAddedTo(DJAppDelegate.sharedDelegate().window, animated: true)
        DJAppDelegate.sharedDelegate().window.addSubview(HUD)
        HUD.labelText = "Importing..";
        HUD.show(true)

        
        let serverURL = NSURL(string: "\(DJServerInfo.baseServerURL)/team/\(teamID)")
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
                                player.audio.announcementDuration = announcementDuration
                            }
                        }
                        team.players.addObject(player)
                    }
                }
                
                // Check to see if user has purchased app - if more than 3 players
                //let appPurchased = false // ::TODO:: add code here
                let appPurchased = NSUserDefaults.standardUserDefaults().boolForKey("IS_ALLREADY_PURCHASED_FULL_VERSION")
                
                if team.players.count > 3 && !appPurchased
                {
                     dispatch_async(dispatch_get_main_queue()) {
                        MBProgressHUD.hideAllHUDsForView(DJAppDelegate.sharedDelegate().window, animated: false)

                        // display alert
                        let alertController = UIAlertController(title: "Unable to Import Team", message: "In order to import a team with more 3 players, you must purchase the fully functional version of BallparkDJ. Upgrade to the Pro version which allows full functionality with unlimited teams and unlimited players per team.", preferredStyle: .Alert)

                        let purchaseAction = UIAlertAction(title: "Upgrade to Pro ($6.99)", style: .Default) { _ in
                                self.performInAppPurchase();
                            }

                        let alreadyPurchasedAction = UIAlertAction(title: "I've Already Purchased", style: .Default) { _ in
                                self.restoreInAppPurchase();
                        }
                        let evaluateAction = UIAlertAction(title: "Continue Evaluating", style: .Cancel) { _ in }
                        
                        alertController.addAction(purchaseAction)
                        alertController.addAction(alreadyPurchasedAction)
                        alertController.addAction(evaluateAction)
                        
                        DJAppDelegate.sharedDelegate().window.rootViewController?.presentViewController(alertController, animated: false, completion: nil)
                    }
                    
                    return
                }
                
                
                dispatch_async(dispatch_get_global_queue(0, 0))
                {
                    //self.createTeamDirectory(team)
                    self.importTeamAudioFiles(team)
                    self.operationQueue.waitUntilAllOperationsAreFinished()
      
                    dispatch_async(dispatch_get_main_queue()) {
                        if let appDelegate = UIApplication.sharedApplication().delegate as? DJAppDelegate
                        {
                            if let completionBlock = completionBlock
                            {
                                completionBlock(team:team)
                            }
                            appDelegate.league.importTeam(team)
                            
                        }
                        self.HUD.hide(true)
                    }
                }
            }
        }
        
        task.resume()
    }

    func performInAppPurchase()
    {
        RageIAPHelper.sharedInstance().requestProductsWithCompletionHandler() {
            success, products in
            if (success) {
             
                if products.count > 0 {
                    self.inInAppPurchaseAction = true
                    RageIAPHelper.sharedInstance().buyProduct(products[0] as! SKProduct)
                }
            }
            
        }
    }
    
    func restoreInAppPurchase()
    {
        inInAppPurchaseAction = true
        RageIAPHelper.sharedInstance().restoreCompletedTransactions()
    }
    
    public func reorderVoice(team:DJTeam, completion: (DJTeam,Bool) -> Void)
    {
        team.voiceReOrder = true
        orderVoice(team, completion: completion)
    }

    public func addOnVoiceOrder(team:DJTeam, completion:(DJTeam,Bool) -> Void)
    {
        team.voiceAddOn = true
        orderVoice(team, completion: completion)
    }
    
    public func orderVoice(team:DJTeam, completion: (DJTeam,Bool) -> Void)
    {
        shareTeam(team) { team,success in
            if team.teamId != nil
            {
                let serverURL = NSURL(string: "\(DJTeamUploader.baseServerURL)/ordervoice")
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
                
                if (team.voiceReOrder)
                {
                    teamDict["status"] = DJVoiceOrderStatus.REVOICING.rawValue
                }
                if (team.voiceAddOn)
                {
                    teamDict["status"] = DJVoiceOrderStatus.ADDON.rawValue
                }
                
                if let orderId = team.orderId
                {
                    teamDict["id"] = orderId
                }
                
                let httpBody = try! NSJSONSerialization.dataWithJSONObject(teamDict, options: .PrettyPrinted)
                
                let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: httpBody)
                {
                    data, response, error in
                    if (error != nil)
                    {
                        DJTeamUploader.showErrorMessage("An error occurred sending the order request. Please try again and if the problem still persists please provide the following error code to support \(error?.code)")
                        print(error)
                        completion(team,false)
                        return;
                    }
                    
                    if let orderData = data
                    {
                        let orderString = String(data: orderData, encoding: NSUTF8StringEncoding)
                        print("\(orderString)")

                        var resultsDict:[String:AnyObject]?
                        do {
                            resultsDict = try NSJSONSerialization.JSONObjectWithData(orderData, options: NSJSONReadingOptions.MutableLeaves) as? [String:AnyObject]
                        }
                        catch {
                            // Error
                            DJTeamUploader.showErrorMessage("An error occurred sending the order request.  Pleast try again and if the problem still persists please contact support.  Error Code B");
                            completion(team,false)
                            return
                        }
                        
                        guard let finalResultsDict = resultsDict else {
                            DJTeamUploader.showErrorMessage("An error occurred sending the order request.  Pleast try again and if the problem still persists please contact support.  Error Code C");
                            completion(team,false)
                            return
                        }
                        
                        if let orderId = finalResultsDict["id"] as? String
                        {
                            print("Success! - OrderID \(orderId)")
                            completion(team, true)
                            return
                        }
                        else
                        {
                            DJTeamUploader.showErrorMessage("An error occured sending the order request.  Please try again and if the problem still persists please provide the following information to support \(resultsDict)")
                        }
                    }
                    else
                    {
                        DJTeamUploader.showErrorMessage("An error occurred sending the order request.  Please try again if the problem still persists please provide the following information to support.  Error Code A")
                    }
                    
                    completion(team,false)
                }
                task.resume()
            }
            else
            {
                DJTeamUploader.showErrorMessage("An error occurred in uploading the team.  Please try again if the problem still persists please provide the following information to support.  Error Code D")
                completion(team,false)
            }
        }
    }

    public func shareTeam(team:DJTeam, completion: (DJTeam,Bool) -> Void)
    {
        DJTeamUploader.shareTeam(team,voicerMode: false, completion: completion)
    }
    
    public static func shareTeam(team:DJTeam, voicerMode:Bool, completion: (DJTeam,Bool) -> Void)
    {
        let serverURL = NSURL(string: "\(DJServerInfo.baseServerURL)/team")
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
            playerDict["revoicePlayer"] = player.revoicePlayer
            playerDict["addOnVoice"] = player.addOnVoice
            playerDict["uuid"] = player.uuid
            
            var audioDict = [String:AnyObject]()
            if let audio = player.audio
            {
                if voicerMode
                {
                    if let announcementURL = audio?.voiceProviderURL?.lastPathComponent
                    {
                        audioDict["announcementUrl"] = announcementURL
                    }
                    else
                    {
                        if let announcementURL = audio?.announcementClip?.url?.lastPathComponent
                        {
                            audioDict["announcementUrl"] = announcementURL
                        }
                    }
                }
                else
                {
                    if let announcementURL = audio?.announcementClip?.url?.lastPathComponent
                    {
                        audioDict["announcementUrl"] = announcementURL
                    }
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
                print(error)
                if (error?.code == -1009) {
                    self.showErrorMessage("An error occured in uploading your team.  Please verify that you have network connectivity.")
                } else {
                    self.showErrorMessage("An error occured in uploading your team.  Please try again.")
                }
                
                completion(team,false)
                return;
            }
            
            if let teamData = data
            {
                let resultsDict = try! NSJSONSerialization.JSONObjectWithData(teamData, options: NSJSONReadingOptions.MutableLeaves)
                
                if let teamID = resultsDict["id"] as? String
                {
                    team.teamId = teamID
                    print("Success!")

                    // Force saving of team so that we have the teamID saved
                    DJAppDelegate.sharedDelegate().league.saveTeam(team)
                    
                    if voicerMode == false
                    {
                        DJTeamUploader.shareTeamFiles(team, completion: completion)
                    }
                    else
                    {
                        completion(team,true)
                    }
                }
                else
                {
                    print("Error: \(resultsDict)")
                    self.showErrorMessage("An error occured in uploading your team.  Please try again.")
                    completion(team,false)
                }
                
            }
            else
            {
                self.showErrorMessage("An error occured in uploading your team.  Please try again.")
                completion(team,false)
            }

        }
        
        task.resume()
    }

    
    public static func shareTeamFiles(team:DJTeam, completion: (DJTeam,Bool) -> Void)
    {
        let boundary = DJTeamUploader.generateBoundaryString()
        
        let serverURL = NSURL(string: "\(DJServerInfo.baseServerURL)/uploadTeamFiles")
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

        let httpBody = DJTeamUploader.createBodyWithBoundary(boundary, params: params, paths: paths, fieldName: "file")
        
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
            
            completion(team,true)
        }
        
        task.resume()
    }
  
    public static func uploadTeamFiles(teamId:String, paths:[NSURL], completion: () -> Void)
    {
        let boundary = generateBoundaryString()
        
        let serverURL = NSURL(string: "\(baseServerURL)/uploadTeamFiles")
        let request = NSMutableURLRequest(URL: serverURL!)
        
        request.HTTPMethod = "POST"
        
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var params = [String:String]()
        
        params["teamId"] = teamId
        
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
            
            completion()
        }
        
        task.resume()
    }

    
    static func createBodyWithBoundary(boundary:String, params:[String:String], paths:[NSURL], fieldName:String) -> NSData
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
            let filename = NSString(string: path.absoluteString!).lastPathComponent
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

    
    func onFinishPurchase()
    {
        if (inInAppPurchaseAction == false)
        {
            return
        }
        inInAppPurchaseAction = false
        
        let alertViewController = UIAlertController(title: "Success", message: "Purchase succeeded.  Please try reimporting your team", preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertViewController.addAction(okAction)
        
        DJAppDelegate.sharedDelegate().window.rootViewController?.presentViewController(alertViewController, animated: false, completion: nil)
    }
    
    func onFinishRestore()
    {
        if (inInAppPurchaseAction == false)
        {
            return
        }
        inInAppPurchaseAction = false
        
        let alertViewController = UIAlertController(title: "Success", message: "Sucessfully Restored. Plrease try reimporting your team", preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertViewController.addAction(okAction)
        
        DJAppDelegate.sharedDelegate().window.rootViewController?.presentViewController(alertViewController, animated: false, completion: nil)
        
    }
    
    func onFinishFailPurchase()
    {
        inInAppPurchaseAction = false
    }
    
    static func showErrorMessage(msg:String)
    {
        let alertViewController = UIAlertController(title: "Error", message: msg, preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertViewController.addAction(okAction)
        
        DJAppDelegate.sharedDelegate().window.rootViewController?.presentViewController(alertViewController, animated: false, completion: nil)
        
    }
    
}
