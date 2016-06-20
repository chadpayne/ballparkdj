//
//  DJVoiceProviderViewController.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/28/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import UIKit

protocol DJVoiceProviderViewControllerDelegate {
    func getOrdersAndTeams(completion:(orders:[DJVoiceOrder], teams:[DJTeam]) -> ())
}

class DJVoiceProviderViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    var orders:[DJVoiceOrder]!
    var teams:[DJTeam]!
    
    var currentTeamIndex = 0;
    var currentPlayerIndex = 0;
    var currentTotalRecordingIndex = 0;
    var currentPlayer:DJPlayer!
    var currentTeam:DJTeam!
    var authToken:String!
    
    var delegate:DJVoiceProviderViewControllerDelegate?
    
    @IBOutlet weak var currentVoiceIndexLabel: UILabel!
    
    @IBOutlet weak var numVoicesToRecordLabel: UILabel!

    @IBOutlet weak var currentTeamIndexLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var totalTeamIndexLabel: UILabel!
    
    @IBOutlet weak var currentTeamNameLabel: UILabel!
    
    
    @IBOutlet weak var currentPlayerVoiceIndexLabel: UILabel!
    
    
    @IBOutlet weak var totalTeamPlayersLabel: UILabel!
    
    
    @IBOutlet weak var currentPlayerNameLabel: UILabel!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?

    
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
        currentTotalRecordingIndex = 1;

        
        if teams.count > 0
        {
            setupUIForTeam(teams[0])
        }
        
        // ::TODO:: Handle case where there is No work - UI should be all zero's
        if teams.count == 0
        {
            let alertController = UIAlertController(title: "Info", message: "No voices to record", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            alertController.addAction(okAction)
            presentViewController(alertController, animated: false, completion: nil)

            
            //dismissViewControllerAnimated(true, completion: nil)
        }
        
        
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
        
        currentTotalRecordingIndex = currentTotalRecordingIndex + 1
        currentVoiceIndexLabel.text = "\(currentTotalRecordingIndex)"

        
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
            currentPlayerVoiceIndexLabel.text = "\(currentPlayerIndex+1)"
        }

        playButton.enabled = true
        stopButton.enabled = true
        
        prepareRecorder()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        resetUI()
        prepareRecorder()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func playProvidedAudioButtonClicked(sender: AnyObject)
    {
        currentPlayer.audio.announcementClip.play()
    }
    
    func prepareRecorder()
    {
        var error:NSError?
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "ddMMyyyyHHmmSS";
        let dateString = formatter.stringFromDate(NSDate())
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir = dirPaths[0]
        let soundFilePath = (docsDir as NSString).stringByAppendingPathComponent(dateString)
        let soundFileURL = NSURL(fileURLWithPath: soundFilePath)
        let recordSettings = [AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue,
                              AVEncoderBitRateKey: 96, AVNumberOfChannelsKey: 2, AVSampleRateKey: 44100.0, AVLinearPCMBitDepthKey: 32, AVLinearPCMIsBigEndianKey: 0, AVLinearPCMIsFloatKey: 0, AVEncoderBitDepthHintKey: 16, AVFormatIDKey: Int(kAudioFormatAppleIMA4)]
        
        do {
            audioRecorder = try AVAudioRecorder(URL: soundFileURL, settings: recordSettings as! [String:AnyObject])
        } catch let error1 as NSError {
            error = error1
            audioRecorder = nil
        }
        catch {
            
        }

        audioRecorder?.prepareToRecord()
        
        if currentPlayer != nil
        {
            currentPlayer.audio.voiceProviderURL = soundFileURL
        }
    }

    @IBAction func recordAudioButtonClicked(sender: AnyObject)
    {
        if audioRecorder?.recording == false {
            playButton.enabled = false
            stopButton.enabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        }
    }

    
    @IBAction func stopAudioButtonClicked(sender: AnyObject)
    {
        stopButton.enabled = false
        playButton.enabled = true
        recordButton.enabled = true
        
        if audioRecorder?.recording == true {
            audioRecorder?.stop()
        } else {
            audioPlayer?.stop()
        }
    }

    
    @IBAction func playRecordedAudioButtonClicked(sender: AnyObject)
    {
        if audioRecorder?.recording == false {
            stopButton.enabled = true
            recordButton.enabled = false
            
            var error: NSError?
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOfURL: (audioRecorder?.url)!)
            } catch let error1 as NSError {
                error = error1
                audioPlayer = nil
            }
            catch {
                
            }
            
            audioPlayer?.delegate = self
            
            if let err = error {
                print("audioPlayer error: \(err.localizedDescription)")
            } else {
                audioPlayer?.play()
            }
            
        }
    }
    
    @IBAction func nextButtonClicked(sender: AnyObject) {
        moveToNextPlayer()
    }
    
    @IBAction func sendRecordingsToServerButtonClicked(sender: AnyObject)
    {
        for team in teams
        {
            var allAudioRecordedForTeam = true
            var filePaths = [NSURL]()
            for player in team.players
            {
                if player.audio!.voiceProviderURL == nil
                {
                    allAudioRecordedForTeam = false
                    break
                }
                else
                {
                    filePaths.append(player.audio!.voiceProviderURL)
                }
            }
            
            if allAudioRecordedForTeam
            {
                let sem = dispatch_semaphore_create(0)
                
                DJTeamUploader.shareTeam(team, voicerMode: true)
                { team in
                    DJTeamUploader.uploadTeamFiles(team.teamId, paths: filePaths) {
                        
                        guard let order = self.getOrderForTeam(team) else { dispatch_semaphore_signal(sem); return }
                        
                        DJOrderBackendService.markOrderComplete(self.authToken, order: order)
                        {_,_ in
                            dispatch_semaphore_signal(sem)
                            
                        }
                    }
                }

                dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
            }
            
        }
    }
    
    func getOrderForTeam(team:DJTeam) -> DJVoiceOrder?
    {
        for order in orders {
            if order.teamId == team.teamId
            {
                return order
            }
        }
        
        return nil
    }
    
    @IBAction func refreshButtonClicked(sender: AnyObject) {
        let alertController = UIAlertController(title: "Info", message: "Not implemented yet", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertController.addAction(okAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func resetButtonClicked(sender: AnyObject)
    {
        delegate?.getOrdersAndTeams() {
            orders, teams in
                self.teams = teams
                self.orders = orders
                self.resetUI()
        }

    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.enabled = true
        stopButton.enabled = false
    }

}
