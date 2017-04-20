//
//  LoginViewController.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/24/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation

open class LoginViewController : UIViewController,DJVoiceProviderViewControllerDelegate
{

    @IBOutlet weak var userName: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: BallparkButton!
    var fetchedOrders:[DJVoiceOrder]!
    var fetchedTeams:[DJTeam]!
    var teamUploader = DJTeamUploader();
    var savedAuthToken:String!
    
    @IBOutlet weak var productionEnvSwitch: UISwitch!
    
    func setupButton(_ button:FUIButton)
    {
        button.buttonColor = UIColor.turquoise()
        button.shadowColor = UIColor.greenSea()
        button.shadowHeight = 3.0
        button.cornerRadius = 6.0
        button.titleLabel?.font = UIFont.boldFlatFont(ofSize: 16)
        button.setTitleColor(UIColor.clouds(), for: UIControlState())
        button.setTitleColor(UIColor.clouds(), for: .highlighted)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupButton(loginButton)
    }
    
    @IBAction func loginButtonClicked(_ sender: AnyObject)
    {
        if productionEnvSwitch.isOn {
            DJServerInfo.baseServerURL = DJServerInfo.productionServerURL
        } else {
            DJServerInfo.baseServerURL = DJServerInfo.testServerURL
        }
        
        DJOrderBackendService.login(userName.text!, password: passwordTextField.text!) { authToken, error in
            
            if let myError = error
            {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: myError.localizedDescription, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: false, completion: nil)
                }
                return
            }
            
            if (authToken == nil)
            {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "Invalid username or password", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: false, completion: nil)
                }
                return;
            }
            
            self.savedAuthToken = authToken
            
            self.getOrdersAndTeams() { orders, teams in
                self.fetchedOrders = orders
                self.fetchedTeams = teams
                DispatchQueue.main.async
                {
                    if orders.count > 0
                    {
                        self.performSegue(withIdentifier: "record", sender: self)
                    }
                    else
                    {
                        let alertController = UIAlertController(title: "Info", message: "There are no current voice orders requiring voicing.", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: false, completion: nil)
                    }
                }
            }
        }
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "record"
        {
            if let voiceProviderViewController = segue.destination as? DJVoiceProviderViewController
            {
                voiceProviderViewController.orders = fetchedOrders
                voiceProviderViewController.teams = fetchedTeams
                voiceProviderViewController.authToken = savedAuthToken
                voiceProviderViewController.delegate = self
            }
        }
    }

    func getOrdersAndTeams(_ completion:@escaping (_ orders:[DJVoiceOrder], _ teams:[DJTeam]) -> ())
    {
        DJOrderBackendService.getRecordingOrders(savedAuthToken)
        {
            orders, error in
            
            var teamIds:[String] = [String]()
            orders?.forEach() { order in teamIds.append(order.teamId!) }
            
            self.teamUploader.performImportTeams(teamIds) {
                teams in

                completion(orders!,teams)
            }
        }
        
    }
}
