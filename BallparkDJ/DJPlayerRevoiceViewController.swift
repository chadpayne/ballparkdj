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

open class DJPlayerRevoiceViewController : UIViewController, UITableViewDataSource, UITableViewDelegate
{
    var team:DJTeam!
    @IBOutlet weak var revoiceLabel: UILabel!
    var addOnOrder:Bool = false
    var selectedPlayers = Set<Int>()
    var delegate:DJPlayerRevoiceViewDelegate?
    var HUD:MBProgressHUD?
    
    @IBOutlet weak var playerTableView: UITableView!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        playerTableView.register(UITableViewCell.self, forCellReuseIdentifier: "playerCell")
        playerTableView.allowsMultipleSelection = true
        
        if self.addOnOrder
        {
            revoiceLabel.text = "Select Players to Record Voice"
        }
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return team.players.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath)
        
        let player = team.players[indexPath.row] as! DJPlayer
        
        let playerName = player.name ?? ""
        let cellText = "#\(player.number) \(playerName)"
        
        cell.textLabel?.text = cellText
        
        if selectedPlayers.contains(indexPath.row)
        {
            cell.accessoryType = .checkmark
        }
        else
        {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (!selectedPlayers.contains(indexPath.row) && selectedPlayers.count >= 30 && addOnOrder == false)
        {
            // Disallow selection
            let alertController = UIAlertController(title: "Info", message: "You can only request free revoicing for up to 30 players.   If you need to request more please contact support@ballparkdj.com", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: false, completion: nil)
            return;
        }
        
        selectedPlayers.insert(indexPath.row)
        playerTableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selectedPlayers.remove(indexPath.row)
        playerTableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
    
    @IBAction func revoiceButtonClicked(_ sender: AnyObject) {
        
        let uploader = DJTeamUploader()
        HUD = MBProgressHUD.showAdded(to: view, animated: true)

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
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.dismiss(animated: false) {
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
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.dismiss(animated: false) {
                        self.delegate?.revoiceRequestCompleted()
                    }
                }
            }
            
        }
    }
 
    @IBAction func cancelButtonClicked(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}
