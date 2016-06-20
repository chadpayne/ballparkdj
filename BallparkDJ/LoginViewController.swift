//
//  LoginViewController.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/24/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation

public class LoginViewController : UIViewController,DJVoiceProviderViewControllerDelegate
{
    @IBOutlet weak var userName: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    var fetchedOrders:[DJVoiceOrder]!
    var fetchedTeams:[DJTeam]!
    var teamUploader = DJTeamUploader();
    var savedAuthToken:String!
    
    @IBAction func loginButtonClicked(sender: AnyObject)
    {
        DJOrderBackendService.login(userName.text!, password: passwordTextField.text!) { authToken, error in
            
            self.savedAuthToken = authToken
            
            self.getOrdersAndTeams() { orders, teams in
                self.fetchedOrders = orders
                self.fetchedTeams = teams
                dispatch_async(dispatch_get_main_queue())
                {
                    self.performSegueWithIdentifier("record", sender: self)
                }
            }
        }
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "record"
        {
            if let voiceProviderViewController = segue.destinationViewController as? DJVoiceProviderViewController
            {
                voiceProviderViewController.orders = fetchedOrders
                voiceProviderViewController.teams = fetchedTeams
                voiceProviderViewController.authToken = savedAuthToken
                voiceProviderViewController.delegate = self
            }
        }
    }
    
    public func getOrdersAndTeams(completion:(orders:[DJVoiceOrder], teams:[DJTeam]) -> ())
    {
        DJOrderBackendService.getRecordingOrders(savedAuthToken)
        {
            orders, error in
            
            var teamIds:[String] = [String]()
            orders.forEach() { order in teamIds.append(order.teamId!) }
            
            self.teamUploader.performImportTeams(teamIds) {
                teams in

                completion(orders: orders,teams: teams)
            }
        }
        
    }
}