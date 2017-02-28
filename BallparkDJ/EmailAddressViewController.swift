//
//  EmailAddressViewController.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/11/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import UIKit

@objc protocol EmailAddressViewControllerDelegate
{
    func emailAddressEntered(emailAddress:String)
}

class EmailAddressViewController: UIViewController {

    @IBOutlet weak var emailAddressTextField: UITextField!
    weak var delegate:EmailAddressViewControllerDelegate?
    var emailConfirmed:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailAddressTextField.text = NSUserDefaults.standardUserDefaults().objectForKey("userEmailAddress") as? String
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func continueButtonClicked(sender: AnyObject)
    {
        if (emailConfirmed == false) {
         
            let alertController = UIAlertController(title: "Please confirm email address", message: "Is \(self.emailAddressTextField.text!) your email address?", preferredStyle: .Alert)
            
            let correctAction = UIAlertAction(title: "Email Correct", style: .Default) { _ in
                self.delegate?.emailAddressEntered(self.emailAddressTextField.text!)
            }

            let incorrectAction = UIAlertAction(title: "Email Not Correct", style: .Default) { _ in
            }
            
            alertController.addAction(correctAction)
            alertController.addAction(incorrectAction)
            
            presentViewController(alertController,animated: true) {}
            
        } else {
            dismissViewControllerAnimated(true) {
                self.delegate?.emailAddressEntered(self.emailAddressTextField.text!)
            }
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
