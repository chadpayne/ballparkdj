//
//  DJVoiceProviderViewController.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/28/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import UIKit

class DJVoiceProviderViewController: UIViewController {

    var orders:[DJVoiceOrder]!
    var teams:[DJTeam]!
    
    var currentTeamIndex = 0;
    var currentPlayerIndex = 0;
    var currentPlayer:DJPlayer!
    var currentTeam:DJTeam!
    
    
    @IBOutlet weak var currentVoiceIndexLabel: UILabel!
    
    @IBOutlet weak var numVoicesToRecordLabel: UILabel!

    @IBOutlet weak var currentTeamIndexLabel: UILabel!
    
    @IBOutlet weak var totalTeamIndexLabel: UILabel!
    
    @IBOutlet weak var currentTeamNameLabel: UILabel!
    
    
    @IBOutlet weak var currentPlayerVoiceIndexLabel: UILabel!
    
    
    @IBOutlet weak var totalTeamPlayersLabel: UILabel!
    
    
    @IBOutlet weak var currentPlayerNameLabel: UILabel!
    
    func resetUI()
    {
        currentTeamIndex = 0;
        currentPlayerIndex = 0;

        currentTeamIndexLabel.text = "\(1)"
        totalTeamIndexLabel.text = "\(orders.count)"
        
        var totalNumVoices = 0
        teams.forEach() { totalNumVoices += $0.players.count }
        numVoicesToRecordLabel.text = "\(totalNumVoices)"
        
        currentVoiceIndexLabel.text = "\(1)"
        
        if teams.count > 0
        {
            setupUIForTeam(teams[0])
        }
        
        // ::TODO:: Handle case where there is No work - UI should be all zero's
        
        
    }
    
    func setupUIForTeam(team:DJTeam)
    {
        currentPlayerIndex = 0
        currentTeam = team
        
        currentTeamNameLabel.text = team.teamName
        currentPlayerVoiceIndexLabel.text = "\(1)"
        totalTeamPlayersLabel.text = "\(team.players.count)"

        if (team.players.count > 0)
        {
            currentPlayerNameLabel.text = team.players[0].name
            currentPlayer = team.players[0] as! DJPlayer
        }
    }
    
    func moveToNextPlayer()
    {
        currentPlayerIndex += 1
        
        if currentPlayerIndex >= teams[currentTeamIndex].players.count
        {
            if currentTeamIndex+1 < teams.count
            {
                // Advance to next team
                // ::TODO:: Consider uploading in background
                currentTeamIndex += 1
                setupUIForTeam(teams[currentTeamIndex])
            }
            else
            {
                // We are done!
                let alertController = UIAlertController(title: "Info", message: "No more voices left to record!", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alertController.addAction(okAction)
                presentViewController(alertController, animated: true, completion: nil)
            }
        }
        else
        {
            currentPlayer = currentTeam.players[currentPlayerIndex] as! DJPlayer
            currentPlayerNameLabel.text = currentPlayer.name
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        resetUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func playProvidedAudioButtonClicked(sender: AnyObject) {
    }
    
    @IBAction func recordStopAudioButtonClicked(sender: AnyObject) {
    }
    
    @IBAction func playRecordedAudioButtonClicked(sender: AnyObject) {
    }
    
    @IBAction func nextButtonClicked(sender: AnyObject) {
        moveToNextPlayer()
    }
    
    @IBAction func sendRecordingsToServerButtonClicked(sender: AnyObject) {
    }
    
    @IBAction func refreshButtonClicked(sender: AnyObject) {
    }
    
    
    @IBAction func resetButtonClicked(sender: AnyObject) {
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
