//
//  DJTeamUploader.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 4/11/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation

public class DJTeamUploader : NSObject
{
    let baseServerURL = "http://104.196.10.190"
    
    override init()
    {
    
    }
    
    func generateBoundaryString() -> String
    {
        return NSUUID().UUIDString
    }

    public func shareTeam(team:DJTeam)
    {
        let serverURL = NSURL(string: "\(baseServerURL)/team")
        let request = NSMutableURLRequest(URL: serverURL!)
        
        request.HTTPMethod = "PUT"
        
        let contentType = "application/json"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var teamDict = [String:String]()
        if let teamID = team.teamId
        {
            teamDict["id"] = teamID
        }
        teamDict["name"] = team.teamName
        
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
                }
                
                self.shareTeamFiles(team)
            }
            else
            {
                // ::TODO:: Display error
            }

        }
        
        task.resume()
    }

    
    public func shareTeamFiles(team:DJTeam)
    {
        let boundary = generateBoundaryString()
        
        let serverURL = NSURL(string: "\(baseServerURL)/uploadTeamFiles")
        let request = NSMutableURLRequest(URL: serverURL!)
        
        request.HTTPMethod = "POST"
        
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var params = [String:String]()
        var paths = [String]()

        params["teamId"] = team.teamId
        
        let path = NSBundle.mainBundle().pathForResource("playButton", ofType: "png")
        paths.append(path!)

        let path2 = NSBundle.mainBundle().pathForResource("stopButton", ofType: "png")
        paths.append(path2!)

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
        }
        
        task.resume()
    }
    
    func createBodyWithBoundary(boundary:String, params:[String:String], paths:[String], fieldName:String) -> NSData
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
            let filename = NSString(string: path).lastPathComponent
            let data = NSData(contentsOfFile: path)
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