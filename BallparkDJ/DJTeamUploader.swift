//
//  DJTeamUploader.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 4/11/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation
import UIKit

open class DJTeamUploader : NSObject
{
    var operationQueue = OperationQueue()
    var HUD:MBProgressHUD!
    var inInAppPurchaseAction:Bool = false
    
    open static var sharedInstance:DJTeamUploader = DJTeamUploader()
    
    override init()
    {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onFinishPurchase), name: NSNotification.Name(rawValue: "InAppPurchase"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onFinishRestore), name: NSNotification.Name(rawValue: "RestoreInAppPurchase"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onFinishFailPurchase), name: NSNotification.Name(rawValue: "FailedInAppPurchase"), object: nil)
        
    }
    
    static func generateBoundaryString() -> String
    {
        return UUID().uuidString
    }
    
    func fileURL(_ fileName:String) -> URL? {
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        
        // If array of path is empty the document folder not found
        guard urls.count != 0 else { return nil }
        
        let url = urls.first!.appendingPathComponent(fileName)
        return url
    }
    
    func createTeamDirectory(_ team:DJTeam)
    {
        let url = fileURL(team.teamId)
        
        if FileManager.default.fileExists(atPath: (url?.path)!) == false
        {
            try! FileManager.default.createDirectory(at: url!, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func importTeamAudioFiles(_ team:DJTeam)
    {
        for player in team.players
        {
            if let url = (player as AnyObject).audio.announcementURL?.lastPathComponent
            {
                
                let myURL = URL(string: "\(DJServerInfo.baseServerURL)/teamfiles/\(team.teamId!)/\(url)")

                let operation = DataTaskOperation.init(url: myURL!)
                                {
                                    data, response, error in
                                    
                                    guard let httpResponse = response as? HTTPURLResponse else { return }
                                    guard httpResponse.statusCode == 200 || httpResponse.statusCode == 302 else { return }
                                    
                                    
                                    (player as AnyObject).audio.announcementURL = self.fileURL("\(team.teamId!)-\(url)")
                                    
                                    try? data?.write(to: ((player as AnyObject).audio?.announcementURL!)!, options: [.atomic])
                                    
                                    (player as AnyObject).audio?.announcementClip = try! AVAudioPlayer(contentsOf:((player as AnyObject).audio?.announcementURL!)!)
                                    
                                    if (player as AnyObject).audio?.isDJClip == true
                                    {
                                        if let audioURL = Bundle.main.path(forResource: (player as AnyObject).audio?.title, ofType: "m4a")
                                        {
                                            (player as AnyObject).audio?.musicClip = try! AVAudioPlayer(contentsOf:URL(fileURLWithPath: audioURL))
                                        }

                                    }
                                }
                
                operationQueue.addOperation(operation)
            }
        }
    }
    
    open func parseTeamFromData(_ data:Data) -> DJTeam?
    {
        if let teamDict = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableLeaves) as? [String:AnyObject]
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
                        player.number = playerNumber.int32Value
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
                            player.audio.djAudioFileName = djFileName
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
                    team.players.add(player)
                }
            }
            
            return team;
        }
        
        return nil;
    }

    open func performImportTeams(_ teamIDs:[String], completion:@escaping (_ teams:[DJTeam]) -> ())
    {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async
        {
            var teams:[DJTeam] = [DJTeam]()
            
            for teamID in teamIDs
            {
                let serverURL = URL(string: "\(DJServerInfo.baseServerURL)/team/\(teamID)")
                
                let operation = DataTaskOperation.init(url: serverURL!)
                                {
                                    data, response, error in
                                    
                                    guard let httpResponse = response as? HTTPURLResponse else { return }
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
            
            completion(teams)
        }
    }

    open func importOrder(_ voiceOrder:DJVoiceOrder)
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

    open func importTeam(_ teamID:String?)
    {
        importTeam(teamID, completionBlock: nil)
    }

    
    open func importTeam(_ teamID:String?, completionBlock:((_ team:DJTeam) -> ())?)
    {
        guard let teamID = teamID else { return }
        
        HUD = MBProgressHUD.showAdded(to: DJAppDelegate.shared().window, animated: true)
        DJAppDelegate.shared().window.addSubview(HUD)
        HUD.labelText = "Importing..";
        HUD.show(true)

        
        let serverURL = URL(string: "\(DJServerInfo.baseServerURL)/team/\(teamID)")
        let request = NSMutableURLRequest(url: serverURL!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in

            if let teamDict = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as? [String:AnyObject]
            {
                let team = DJTeam()
                
                if DJServerInfo.baseServerURL == DJServerInfo.testServerURL {
                    team.teamImportedOrderedOnTestEnvironment = true
                } else {
                    team.teamImportedOrderedOnTestEnvironment = false
                }
                
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
                            player.number = playerNumber.int32Value
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
                                player.audio.djAudioFileName = djFileName
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
                        team.players.add(player)
                    }
                }
                
                // Check to see if user has purchased app - if more than 3 players
                //let appPurchased = false // ::TODO:: add code here
                let appPurchased = UserDefaults.standard.bool(forKey: "IS_ALLREADY_PURCHASED_FULL_VERSION")
                
                if team.players.count > 3 && !appPurchased
                {
                     DispatchQueue.main.async {
                        MBProgressHUD.hideAllHUDs(for: DJAppDelegate.shared().window, animated: false)

                        // display alert
                        let alertController = UIAlertController(title: "Unable to Import Team", message: "In order to import a team with more 3 players, you must purchase the fully functional version of BallparkDJ. Upgrade to the Pro version which allows full functionality with unlimited teams and unlimited players per team.", preferredStyle: .alert)

                        let purchaseAction = UIAlertAction(title: "Upgrade to Pro ($6.99)", style: .default) { _ in
                                self.performInAppPurchase();
                            }

                        let alreadyPurchasedAction = UIAlertAction(title: "I've Already Purchased", style: .default) { _ in
                                self.restoreInAppPurchase();
                        }
                        let evaluateAction = UIAlertAction(title: "Continue Evaluating", style: .cancel) { _ in }
                        
                        alertController.addAction(purchaseAction)
                        alertController.addAction(alreadyPurchasedAction)
                        alertController.addAction(evaluateAction)
                        
                        DJAppDelegate.shared().window.rootViewController?.present(alertController, animated: false, completion: nil)
                    }
                    
                    return
                }
                
                
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async
                {
                    //self.createTeamDirectory(team)
                    self.importTeamAudioFiles(team)
                    self.operationQueue.waitUntilAllOperationsAreFinished()
      
                    DispatchQueue.main.async {
                        if let appDelegate = UIApplication.shared.delegate as? DJAppDelegate
                        {
                            if let completionBlock = completionBlock
                            {
                                completionBlock(team)
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
        RageIAPHelper.sharedInstance().requestProducts() {
            success, products in
            if (success) {
             
                if (products?.count)! > 0 {
                    self.inInAppPurchaseAction = true
                    RageIAPHelper.sharedInstance().buy(products?[0] as! SKProduct)
                }
            }
            
        }
    }
    
    func restoreInAppPurchase()
    {
        inInAppPurchaseAction = true
        RageIAPHelper.sharedInstance().restoreCompletedTransactions()
    }
    
    open func reorderVoice(_ team:DJTeam, completion: @escaping (DJTeam,Bool) -> Void)
    {
        team.voiceReOrder = true
        orderVoice(team, completion: completion)
    }

    open func addOnVoiceOrder(_ team:DJTeam, completion:@escaping (DJTeam,Bool) -> Void)
    {
        team.voiceAddOn = true
        orderVoice(team, completion: completion)
    }
    
    open func orderVoice(_ team:DJTeam, completion: @escaping (DJTeam,Bool) -> Void)
    {
        shareTeam(team) { team,success in
            if team.teamId != nil
            {
                let serverURL = URL(string: "\(DJServerInfo.baseServerURL)/ordervoice")
                let request = NSMutableURLRequest(url: serverURL!)
                
                request.httpMethod = "POST"
                
                let contentType = "application/json"
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                
                var teamDict = [String:Any]()
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
                
                let httpBody = try! JSONSerialization.data(withJSONObject: teamDict, options: .prettyPrinted)
                
                let task = URLSession.shared.uploadTask(with: request as URLRequest, from: httpBody, completionHandler: {
                    data, response, error in
                    if (error != nil)
                    {
                        DJTeamUploader.showErrorMessage("An error occurred sending the order request. Please try again and if the problem still persists please provide the following error code to support \(error?._code)")
                        print(error)
                        completion(team,false)
                        return;
                    }
                    
                    if let orderData = data
                    {
                        let orderString = String(data: orderData, encoding: String.Encoding.utf8)
                        print("\(orderString)")

                        var resultsDict:[String:AnyObject]?
                        do {
                            resultsDict = try JSONSerialization.jsonObject(with: orderData, options: JSONSerialization.ReadingOptions.mutableLeaves) as? [String:AnyObject]
                        }
                        catch {
                            // Error
                            DJTeamUploader.showErrorMessage("An error occurred sending the order request.  Please try again and ensure that you have entered in a valid email address.  If the problem still persists please contact support.  Error Code B");
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
                })                

                task.resume()
            }
            else
            {
                DJTeamUploader.showErrorMessage("An error occurred in uploading the team.  Please try again if the problem still persists please provide the following information to support.  Error Code D")
                completion(team,false)
            }
        }
    }

    open func shareTeam(_ team:DJTeam, completion: @escaping (DJTeam,Bool) -> Void)
    {
        DJTeamUploader.shareTeam(team,voicerMode: false, completion: completion)
    }
    
    open static func shareTeam(_ team:DJTeam, voicerMode:Bool, completion: @escaping (DJTeam,Bool) -> Void)
    {
        let serverURL = URL(string: "\(DJServerInfo.baseServerURL)/team")
        let request = NSMutableURLRequest(url: serverURL!)

        request.httpMethod = "PUT"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var teamDict = [String:Any]()
        if let teamID = team.teamId
        {
            teamDict["id"] = teamID
        }
        teamDict["name"] = team.teamName
        teamDict["teamOwnerEmail"] = team.teamOwnerEmail
        
        var playersDict = [[String:Any]]()
        
        for playerItem in team.players
        {
            let player = playerItem as! DJPlayer
            
            var playerDict = [String:Any]()
            playerDict["name"] = player.name
            
            playerDict["number"] = NSNumber(value: player.number as Int32)
            playerDict["benched"] = NSNumber(value: player.b_isBench as Bool)
            playerDict["revoicePlayer"] = player.revoicePlayer
            playerDict["addOnVoice"] = player.addOnVoice
            playerDict["uuid"] = player.uuid
            
            var audioDict = [String:Any]()
            let audio = player.audio
          //  {
                if voicerMode
                {
                    if let announcementURL = audio.voiceProviderURL?.lastPathComponent
                    {
                        audioDict["announcementUrl"] = announcementURL
                    }
                    else
                    {
                        if let announcementURL = audio.announcementClip?.url?.lastPathComponent
                        {
                            audioDict["announcementUrl"] = announcementURL
                        }
                    }
                }
                else
                {
                    if let announcementURL = audio.announcementClip?.url?.lastPathComponent
                    {
                        audioDict["announcementUrl"] = announcementURL
                    }
                }
                audioDict["overlap"] = audio.overlap
                audioDict["musicStartTime"] = audio.musicStartTime
                audioDict["musicDuration"] = audio.musicDuration
                audioDict["shouldFade"] = audio.shouldFade
                audioDict["djFileName"] = audio.djAudioFileName
                audioDict["djClip"] = audio.isDJClip
                audioDict["announcmentVolume"] = audio.announcementVolume
                audioDict["shouldPlayAll"] = audio.shouldPlayAll
                audioDict["title"] = audio.title
                audioDict["musicVolume"] = audio.musicVolume
                audioDict["currentVolumeMode"] = NSNumber(value: audio.currentVolumeMode as Int32)
                audioDict["announcmentDuration"] = audio.announcementDuration
            //}
            playerDict["playerAudio"] = audioDict
            
            playersDict.append(playerDict)
        }

        teamDict["players"] = playersDict
        
        
        let httpBody = try! JSONSerialization.data(withJSONObject: teamDict, options: .prettyPrinted)
        
        let task = URLSession.shared.uploadTask(with: request as URLRequest, from: httpBody, completionHandler: {
           data, response, error in
           if (error != nil)
            {
                print(error)
                if (error?._code == -1009) {
                    self.showErrorMessage("An error occured in uploading your team.  Please verify that you have network connectivity.")
                } else {
                    self.showErrorMessage("An error occured in uploading your team.  Please try again.")
                }
                
                completion(team,false)
                return;
            }
            
            if let teamData = data
            {
                let resultsDict = try! JSONSerialization.jsonObject(with: teamData, options: JSONSerialization.ReadingOptions.mutableLeaves) as! [String:Any]
                
                if let teamID = resultsDict["id"] as? String
                {
                    team.teamId = teamID
                    
                    // ::TODO:: Get this value from the server
                    team.shareExpirationDate = Date().addingTimeInterval(60*60*24*14)
                    
                    print("Success!")

                    // Force saving of team so that we have the teamID saved
                    DJAppDelegate.shared().league.saveTeam(team)
                    
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

        })        

        
        task.resume()
    }

    
    open static func shareTeamFiles(_ team:DJTeam, completion: @escaping (DJTeam,Bool) -> Void)
    {
        let boundary = DJTeamUploader.generateBoundaryString()
        
        let serverURL = URL(string: "\(DJServerInfo.baseServerURL)/uploadTeamFiles")
        let request = NSMutableURLRequest(url: serverURL!)
        
        request.httpMethod = "POST"
        
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var params = [String:String]()
        var paths = [URL]()

        params["teamId"] = team.teamId
        
        for playerItem in team.players
        {
            let player = playerItem as! DJPlayer
            if let announcementURL = player.audio.announcementClip?.url
            {
                paths.append(announcementURL)
            }

        }

        let httpBody = DJTeamUploader.createBodyWithBoundary(boundary, params: params, paths: paths, fieldName: "file")
        
        let task = URLSession.shared.uploadTask(with: request as URLRequest, from: httpBody, completionHandler: {
            data, response, error in
            if ((error) != nil)
            {
                print(error)
                return;
            }
            
            let result = NSString(data: data!
                , encoding: String.Encoding.utf8.rawValue)
            print(result)
            
            completion(team,true)
        })        

        
        task.resume()
    }

    open static func uploadNextTeamFile(_ teamId:String, paths:[URL], index:Int, completion: @escaping () -> Void)
    {
        let currentURL:URL! = paths[index]
      
        uploadTeamFiles(teamId, paths: [currentURL]) {
            let newIndex = index + 1
            
            if (newIndex >= paths.count) {
                // we are done!
                completion()
            } else {
                uploadNextTeamFile(teamId, paths: paths, index: newIndex, completion: completion)
            }
        }
        
    }

    open static func uploadTeamFilesVoicer(_ teamId:String, paths:[URL], completion: @escaping () -> Void)
    {
        guard paths.count > 0 else { completion(); return; }

        uploadNextTeamFile(teamId, paths: paths, index: 0) {
            completion()
        }
    }

    
    open static func uploadTeamFiles(_ teamId:String, paths:[URL], completion: @escaping () -> Void)
    {
        let boundary = generateBoundaryString()
        
        let serverURL = URL(string: "\(DJServerInfo.baseServerURL)/uploadTeamFiles")
        let request = NSMutableURLRequest(url: serverURL!)
        
        request.httpMethod = "POST"
        
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var params = [String:String]()
        
        params["teamId"] = teamId
        
        let httpBody = createBodyWithBoundary(boundary, params: params, paths: paths, fieldName: "file")
        
        let task = URLSession.shared.uploadTask(with: request as URLRequest, from: httpBody, completionHandler: {
            data, response, error in
            if ((error) != nil)
            {
                print(error)
                return;
            }
            
            let result = NSString(data: data!
                , encoding: String.Encoding.utf8.rawValue)
            print(result)
            
            completion()
        })        

        
        task.resume()
    }

    
    static func createBodyWithBoundary(_ boundary:String, params:[String:String], paths:[URL], fieldName:String) -> Data
    {
        let httpBody = NSMutableData()
        
        for (key,value) in params
        {
            httpBody.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
            httpBody.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
        }

        for path in paths
        {
            let filename = NSString(string: path.absoluteString).lastPathComponent
            let data = try? Data(contentsOf: path)
            let mimetype = "application/octet-stream"
            
            httpBody.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: String.Encoding.utf8)!)

            httpBody.append("Content-Transfer-Encoding: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
            
            httpBody.append(data!)
            httpBody.append("\r\n".data(using: String.Encoding.utf8)!)
        }
        
        httpBody.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        return httpBody as Data
    }

    
    func onFinishPurchase()
    {
        if (inInAppPurchaseAction == false)
        {
            return
        }
        inInAppPurchaseAction = false
        
        let alertViewController = UIAlertController(title: "Success", message: "Purchase succeeded.  Please try reimporting your team", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertViewController.addAction(okAction)
        
        DJAppDelegate.shared().window.rootViewController?.present(alertViewController, animated: false, completion: nil)
    }
    
    func onFinishRestore()
    {
        if (inInAppPurchaseAction == false)
        {
            return
        }
        inInAppPurchaseAction = false
        
        let alertViewController = UIAlertController(title: "Success", message: "Sucessfully Restored. Please try reimporting your team", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertViewController.addAction(okAction)
        
        DJAppDelegate.shared().window.rootViewController?.present(alertViewController, animated: false, completion: nil)
        
    }
    
    func onFinishFailPurchase()
    {
        inInAppPurchaseAction = false
    }
    
    static func showErrorMessage(_ msg:String)
    {
        let alertViewController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertViewController.addAction(okAction)
        
        DJAppDelegate.shared().window.rootViewController?.present(alertViewController, animated: false, completion: nil)
        
    }
    
}
