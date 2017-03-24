//
//  DJPlayerRevoiceViewController.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 8/17/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol DJPlayerRevoiceViewDelegate
{
    func revoiceRequestCompleted()
    func addOnRequestCompleted()
}

public class DJPlayerRevoiceViewController : UIViewController, UITableViewDataSource, UITableViewDelegate
{
    var team:DJTeam!
    @IBOutlet weak var revoiceLabel: UILabel!
    var addOnOrder:Bool = false
    var selectedPlayers = Set<Int>()
    var delegate:DJPlayerRevoiceViewDelegate?
    var HUD:MBProgressHUD?
    
    @IBOutlet weak var playerTableView: UITableView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        playerTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "playerCell")
        playerTableView.allowsMultipleSelection = true
        
        if self.addOnOrder
        {
            revoiceLabel.text = "Select Players to Record Voice"
        }
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return team.players.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("playerCell", forIndexPath: indexPath)
        
        let player = team.players[indexPath.row] as! DJPlayer
        let cellText = "#\(player.number) \(player.name)"
        
        cell.textLabel?.text = cellText
        
        if selectedPlayers.contains(indexPath.row)
        {
            cell.accessoryType = .Checkmark
        }
        else
        {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if (!selectedPlayers.contains(indexPath.row) && selectedPlayers.count >= 30 && addOnOrder == false)
        {
            // Disallow selection
            let alertController = UIAlertController(title: "Info", message: "You can only request free revoicing for up to 30 players.   If you need to request more please contact support@ballparkdj.com", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            alertController.addAction(okAction)
            presentViewController(alertController, animated: false, completion: nil)
            return;
        }
        
        selectedPlayers.insert(indexPath.row)
        playerTableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
    }
    
    public func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        selectedPlayers.remove(indexPath.row)
        playerTableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .None
    }
    
    @IBAction func revoiceButtonClicked(sender: AnyObject) {
        
        let uploader = DJTeamUploader()
        HUD = MBProgressHUD.showHUDAddedTo(view, animated: true)

        if (self.addOnOrder)
        {
            // Set add-on voice to false for all players (i.e only send the ones
            // the user selected
            var currentPlayer:DJPlayer?
            
            for i in 0..<team.players.count
            {
                currentPlayer = team.players[i] as? DJPlayer
                currentPlayer?.addOnVoice = false
            }
            
            for selectedPlayerIndex in selectedPlayers
            {
                let player = team.players[selectedPlayerIndex] as! DJPlayer
                player.addOnVoice = true
            }
            uploader.addOnVoiceOrder(team) { team in
                dispatch_async(dispatch_get_main_queue()) {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    self.dismissViewControllerAnimated(false) {
                        self.delegate?.addOnRequestCompleted()
                    }
                }
            }
        }
        else
        {
            for selectedPlayerIndex in selectedPlayers
            {
                let player = team.players[selectedPlayerIndex] as! DJPlayer
                player.revoicePlayer = true
            }
            uploader.reorderVoice(team) { team in
                dispatch_async(dispatch_get_main_queue()) {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    self.dismissViewControllerAnimated(false) {
                        self.delegate?.revoiceRequestCompleted()
                    }
                }
            }
            
        }
    }
 
    @IBAction func cancelButtonClicked(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
