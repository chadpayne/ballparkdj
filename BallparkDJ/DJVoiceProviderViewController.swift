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

    @IBOutlet weak var playAudioButton: FUIButton!
    var orders:[DJVoiceOrder]!
    var teams:[DJTeam]!
    
    var currentTeamIndex = 0;
    var currentPlayerIndex = 0;
    var currentTotalRecordingIndex = 0;
    var currentPlayer:DJPlayer!
    var currentTeam:DJTeam!
    var authToken:String!
    
    var delegate:DJVoiceProviderViewControllerDelegate?
    
    var audioTimer:NSTimer?
    
    @IBOutlet weak var playerTextView: UITextView!

    @IBOutlet weak var currentTeamIndexLabel: UILabel!
    @IBOutlet weak var recordButton: FUIButton!
    
    @IBOutlet weak var totalTeamIndexLabel: UILabel!
    
    
    
    @IBOutlet weak var currentPlayerVoiceIndexLabel: UILabel!
    
    
    @IBOutlet weak var totalTeamPlayersLabel: UILabel!
    
    
    @IBOutlet weak var audioTimeLabel: UILabel!
    
    @IBOutlet weak var playButton: FUIButton!
    
    @IBOutlet weak var nextButton: FUIButton!
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    
    @IBOutlet weak var doneUploadButton: FUIButton!
    var currentSoundFileURL:NSURL?

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButton(playButton)
        setupButton(nextButton)
        setupButton(recordButton)
        setupButton(doneUploadButton)
        setupButton(playAudioButton)
    }
    
    
    func resetUI()
    {
        currentTeamIndex = 0;
        currentPlayerIndex = 0;
        audioTimeLabel.text = "\(0.00)"

        currentTeamIndexLabel.text = "\(1)"
        totalTeamIndexLabel.text = "\(orders.count)"
        
        var totalNumVoices = 0
        teams.forEach() { totalNumVoices += $0.players.count }
        
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

            
            doneUploadButton.hidden = false
            //dismissViewControllerAnimated(true, completion: nil)
        }
        
        playButton.enabled = false
        nextButton.enabled = false
        
        doneUploadButton.hidden = true
    }
    
    func setupUIForTeam(team:DJTeam)
    {
        doneUploadButton.hidden = true
        currentPlayerIndex = 0
        currentTeam = team
        audioTimeLabel.text = "\(0.00)"
        
        currentPlayerVoiceIndexLabel.text = "\(1)"
        totalTeamPlayersLabel.text = "\(team.players.count)"

        if (team.players.count > 0)
        {
            currentPlayer = team.players[0] as! DJPlayer
            formatAtBatPlayer()
        }
        
        let order = getOrderForTeam(currentTeam)
        if order!.orderStatus == .REVOICING && currentPlayer?.revoicePlayer == false
        {
            if (currentPlayer.audio.announcementClip != nil)
            {
                currentPlayer.audio.voiceProviderURL = currentPlayer.audio.announcementClip.url
            }
            moveToNextPlayer();
            return;
        }
        
        if (currentPlayer.audio.announcementClip != nil)
        {
            audioTimeLabel.text = "\(Double(round(10*currentPlayer.audio.announcementClip.duration)/10))"
            playAudioButton.enabled = true
            playProvidedAudioButtonClicked(self)
        }
        else
        {
            playAudioButton.enabled = false
        }
    }
    
    func formatAtBatPlayer()
    {
        let order = getOrderForTeam(currentTeam)
        switch (order!.playerVoiceFormat)
        {
        case .NOW_BATTING_PLAYERNUMBER_PLAYERNAME:
            playerTextView.text = "Now Batting\nNumber \(currentPlayer.number)\n\(currentPlayer.name)"
            break
        case .NOW_BATTING_FORTEAM_PLAYERNUMBER_PLAYERNAME:
            playerTextView.text = "Now Batting for the \(currentTeam.teamName)\nNumber \(currentPlayer.number)\n\(currentPlayer.name)"
            break
        case .PLAYERNUMBER_PLAYERNAME:
            playerTextView.text = "Number \(currentPlayer.number)\n\(currentPlayer.name)"
            break
        }
        
        playerTextView.font = UIFont.boldSystemFontOfSize(30)
        playerTextView.textColor = UIColor.blueColor()
        playerTextView.textAlignment = NSTextAlignment.Center
    }
    
    func moveToNextPlayer()
    {
        playButton.enabled = false
        nextButton.enabled = false
        
        currentPlayerIndex += 1
        
        currentTotalRecordingIndex = currentTotalRecordingIndex + 1

        
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
                
                doneUploadButton.hidden = false
                return
            }
        }
        else
        {
            currentPlayer = currentTeam.players[currentPlayerIndex] as! DJPlayer
            formatAtBatPlayer()
            currentPlayerVoiceIndexLabel.text = "\(currentPlayerIndex+1)"
        }
        
        let order = getOrderForTeam(currentTeam)
        if order!.orderStatus == .REVOICING && currentPlayer?.revoicePlayer == false
        {
            if (currentPlayer.audio.announcementClip != nil)
            {
                currentPlayer.audio.voiceProviderURL = currentPlayer.audio.announcementClip.url
            }

            moveToNextPlayer();
            return;
        }
       
        if (currentPlayer.audio.announcementClip != nil)
        {
            audioTimeLabel.text = "\(Double(round(10*currentPlayer.audio.announcementClip.duration)/10))"
            playAudioButton.enabled = true
            playProvidedAudioButtonClicked(self)
        }
        else
        {
            audioTimeLabel.text = "0.0"
            playAudioButton.enabled = false
        }
        
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
        if (currentPlayer.audio.announcementClip == nil)
        {
            let alertController = UIAlertController(title: "Info", message: "No supplied audio for player!", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            alertController.addAction(okAction)
            presentViewController(alertController, animated: false, completion: nil)
            
            return
        }
        
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
           print("Error creating recorder!!!")
        }

        audioRecorder?.prepareToRecord()
        
        if currentPlayer != nil
        {
            currentPlayer.audio.voiceProviderURL = soundFileURL
        }
        
        currentSoundFileURL = soundFileURL
    }

    @IBAction func recordAudioButtonClicked(sender: AnyObject)
    {
        if audioPlayer?.playing == true {
            // Stop playback of current audio
            stopAudioButtonClicked(sender)
            return
        }
        
        if audioRecorder?.recording == false {
            playButton.enabled = false
            recordButton.titleLabel?.text = "Stop"
            recordButton.setTitle("Stop", forState: .Normal)
            recordButton.setTitle("Stop", forState: .Highlighted)

            try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord, withOptions: AVAudioSessionCategoryOptions.AllowBluetooth)

            audioTimeLabel.text = "0.0"
            audioTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(DJVoiceProviderViewController.updateAudioTimeLabel), userInfo: nil, repeats: true)
            
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        }
        else
        {
            // As Record/Stop used to be separate buttons - call code for stopAudio callback
            stopAudioButtonClicked(sender)
        }
        
    }
    
    func updateAudioTimeLabel()
    {
        guard let audioRecorder = audioRecorder else { return }
        guard audioRecorder.recording else { return }
        
        let currentTime = audioRecorder.currentTime
        audioTimeLabel.text = "\(Double(round(10*currentTime)/10))"
    }

    
    @IBAction func stopAudioButtonClicked(sender: AnyObject)
    {
        playButton.enabled = true
        recordButton.titleLabel?.text = "Record"
        recordButton.setTitle("Record", forState: .Normal)
        recordButton.setTitle("Record", forState: .Highlighted)
        nextButton.enabled = true
        
        if audioRecorder?.recording == true {

            audioTimer?.invalidate()
            audioTimer = nil
            audioRecorder?.stop()
            
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error1 as NSError {
                print("Error \(error1.localizedDescription)")
            } catch {
                print("Sucks to be me")
            }
            
            // If on last player - enable Done/Upload button
            if (currentPlayerIndex+1) >= teams[currentTeamIndex].players.count
            {
                doneUploadButton.hidden = false
            }
        } else {
            audioPlayer?.stop()
        }
    }

    
    @IBAction func playRecordedAudioButtonClicked(sender: AnyObject)
    {
        if audioRecorder?.recording == false {

            recordButton.titleLabel?.text = "Stop"
            recordButton.setTitle("Stop", forState: .Normal)
            recordButton.setTitle("Stop", forState: .Highlighted)
            
            var error: NSError?
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOfURL:currentSoundFileURL!)
            } catch let error1 as NSError {
                error = error1
                audioPlayer = nil
            }
            catch {
                print("Some other exception!!!");
            }
            
            audioPlayer?.delegate = self
            
            if let err = error {
                print("audioPlayer error: \(err.localizedDescription)")
            } else {
                audioPlayer?.prepareToPlay()
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
            let order = getOrderForTeam(team)
            
            var allAudioRecordedForTeam = true
            var filePaths = [NSURL]()
            for player in team.players
            {
                if player.audio!.voiceProviderURL == nil
                {
                    if (order!.orderStatus != .REVOICING)
                    {
                        allAudioRecordedForTeam = false
                        break
                    }
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
        
        let alertController = UIAlertController(title: "Info", message: "Orders uploaded to server", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertController.addAction(okAction)
        presentViewController(alertController, animated: true, completion: nil)
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
  
    func audioRecorderBeginInterruption(recorder: AVAudioRecorder) {
        print("Here1!!!")
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.titleLabel?.text = "Record"
        recordButton.setTitle("Record", forState: .Normal)
        recordButton.setTitle("Record", forState: .Highlighted)
    }

    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        print("Error decoding!")
        recordButton.titleLabel?.text = "Record"
        recordButton.setTitle("Record", forState: .Normal)
        recordButton.setTitle("Record", forState: .Highlighted)
    }

}
