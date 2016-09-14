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
    
    @IBOutlet weak var loginButton: BallparkButton!
    var fetchedOrders:[DJVoiceOrder]!
    var fetchedTeams:[DJTeam]!
    var teamUploader = DJTeamUploader();
    var savedAuthToken:String!
    
    
    func setupButton(button:FUIButton)
    {
        button.buttonColor = UIColor.turquoiseColor()
        button.shadowColor = UIColor.greenSeaColor()
        button.shadowHeight = 3.0
        button.cornerRadius = 6.0
        button.titleLabel?.font = UIFont.boldFlatFontOfSize(16)
        button.setTitleColor(UIColor.cloudsColor(), forState: .Normal)
        button.setTitleColor(UIColor.cloudsColor(), forState: .Highlighted)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupButton(loginButton)
    }
    
    @IBAction func loginButtonClicked(sender: AnyObject)
    {
        DJOrderBackendService.login(userName.text!, password: passwordTextField.text!) { authToken, error in
            
            if let myError = error
            {
                dispatch_async(dispatch_get_main_queue()) {
                    let alertController = UIAlertController(title: "Error", message: myError.localizedDescription, preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    alertController.addAction(okAction)
                    self.presentViewController(alertController, animated: false, completion: nil)
                }
                return
            }
            
            if (authToken == nil)
            {
                dispatch_async(dispatch_get_main_queue()) {
                    let alertController = UIAlertController(title: "Error", message: "Invalid username or password", preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    alertController.addAction(okAction)
                    self.presentViewController(alertController, animated: false, completion: nil)
                }
                return;
            }
            
            self.savedAuthToken = authToken
            
            self.getOrdersAndTeams() { orders, teams in
                self.fetchedOrders = orders
                self.fetchedTeams = teams
                dispatch_async(dispatch_get_main_queue())
                {
                    if orders.count > 0
                    {
                        self.performSegueWithIdentifier("record", sender: self)
                    }
                    else
                    {
                        let alertController = UIAlertController(title: "Info", message: "There are no current voice orders requiring voicing.", preferredStyle: .Alert)
                        let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                        alertController.addAction(okAction)
                        self.presentViewController(alertController, animated: false, completion: nil)
                    }
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