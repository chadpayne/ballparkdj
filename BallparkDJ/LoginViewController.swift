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
        VoiceProviderLogin.login(userName.text!, password: passwordTextField.text!)
    }
}