//
//  LoginViewController.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/24/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation

public class LoginViewController : UIViewController
{
    @IBOutlet weak var userName: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func loginButtonClicked(sender: AnyObject)
    {
        DJOrderBackendService.login(userName.text!, password: passwordTextField.text!) { authToken, error in
            DJOrderBackendService.getRecordingOrders(authToken)
            {
                orders, error in
                VoiceProviderLogin.processOrders(orders)
                
                dispatch_async(dispatch_get_main_queue())
                {
                    self.performSegueWithIdentifier("record", sender: self)
                }
                
            }
        }
        
        
    }
}