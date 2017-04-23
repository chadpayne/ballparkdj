//
//  DJVoiceProviderViewController.swift
//  BallparkDJ
//
//  Created by Kurt Niemi on 5/28/16.
//  Copyright © 2016 Payne Software. All rights reserved.
//

import UIKit

protocol DJVoiceProviderViewControllerDelegate {
    func getOrdersAndTeams(_ completion:@escaping (_ orders:[DJVoiceOrder], _ teams:[DJTeam]) -> ())
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
    
    var audioTimer:Timer?
    
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
    var currentSoundFileURL:URL?

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
            let alertController = UIAlertController(title: "Info", message: "No voices to record", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: false, completion: nil)

            
            doneUploadButton.isHidden = false
            //dismissViewControllerAnimated(true, completion: nil)
        }
        
        playButton.isEnabled = false
        nextButton.isEnabled = false
        
        doneUploadButton.isHidden = true
    }
    
    func setupUIForTeam(_ team:DJTeam)
    {
        doneUploadButton.isHidden = true
        currentPlayerIndex = 0
        currentTeam = team
        audioTimeLabel.text = "\(0.00)"
        
        currentTeamIndexLabel.text = "\(currentTeamIndex+1)"
        let totalPlayerVoices = teams.reduce(0) { $0 + $1.players.count }
        
        currentPlayerVoiceIndexLabel.text = "\(1)"
        totalTeamPlayersLabel.text = "\(team.players.count) of \(totalPlayerVoices)"

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

        // Add-on order
        if order!.orderStatus == .ADDONPAID && currentPlayer?.addOnVoice == false
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
            playAudioButton.isEnabled = true
            playProvidedAudioButtonClicked(self)
        }
        else
        {
            playAudioButton.isEnabled = false
        }
    }
    
    func formatAtBatPlayer()
    {
        let order = getOrderForTeam(currentTeam)
        switch (order!.playerVoiceFormat)
        {
        case .NOW_BATTING_PLAYERNUMBER_PLAYERNAME:
            playerTextView.text = "Now Batting\nNumber \(currentPlayer.number)\n\(currentPlayer.name!)"
            break
        case .NOW_BATTING_FORTEAM_PLAYERNUMBER_PLAYERNAME:
            playerTextView.text = "Now Batting for the \(currentTeam.teamName)\nNumber \(currentPlayer.number)\n\(currentPlayer.name!)"
            break
        case .PLAYERNUMBER_PLAYERNAME:
            playerTextView.text = "Number \(currentPlayer.number)\n\(currentPlayer.name!)"
            break
        }
        
        playerTextView.font = UIFont.boldSystemFont(ofSize: 30)
        playerTextView.textColor = UIColor.blue
        playerTextView.textAlignment = NSTextAlignment.center
    }
    
    func moveToNextPlayer()
    {
        playButton.isEnabled = false
        nextButton.isEnabled = false
        
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
                let alertController = UIAlertController(title: "Info", message: "No more voices left to record!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                
                doneUploadButton.isHidden = false
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
        
        // Add-on order
        if order!.orderStatus == .ADDONPAID && currentPlayer?.addOnVoice == false
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
            playAudioButton.isEnabled = true
            playProvidedAudioButtonClicked(self)
        }
        else
        {
            audioTimeLabel.text = "0.0"
            playAudioButton.isEnabled = false
        }
        
        prepareRecorder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetUI()
        prepareRecorder()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func playProvidedAudioButtonClicked(_ sender: AnyObject)
    {
        if (currentPlayer.audio.announcementClip == nil)
        {
            let alertController = UIAlertController(title: "Info", message: "No supplied audio for player!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: false, completion: nil)
            
            return
        }
        
        if (currentPlayer.audio.announcementClip.isPlaying)
        {
            currentPlayer.audio.announcementClip.pause()
        }
        currentPlayer.audio.announcementClip.currentTime = 0
        
        currentPlayer.audio.announcementClip.play()
    }
    
    func prepareRecorder()
    {
        var error:NSError?
        
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyyHHmmSS";
        let dateString = formatter.string(from: Date())
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docsDir = dirPaths[0]
        let soundFilePath = (docsDir as NSString).appendingPathComponent(dateString)
        let soundFileURL = URL(fileURLWithPath: soundFilePath)
        let recordSettings = [AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                              AVEncoderBitRateKey: 96, AVNumberOfChannelsKey: 2, AVSampleRateKey: 44100.0, AVLinearPCMBitDepthKey: 32, AVLinearPCMIsBigEndianKey: 0, AVLinearPCMIsFloatKey: 0, AVEncoderBitDepthHintKey: 16, AVFormatIDKey: Int(kAudioFormatAppleIMA4)] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: soundFileURL, settings: recordSettings)
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

    @IBAction func recordAudioButtonClicked(_ sender: AnyObject)
    {
        if audioPlayer?.isPlaying == true {
            // Stop playback of current audio
            stopAudioButtonClicked(sender)
            return
        }
        
        if audioRecorder?.isRecording == false {
            playButton.isEnabled = false
            recordButton.titleLabel?.text = "Stop"
            recordButton.setTitle("Stop", for: UIControlState())
            recordButton.setTitle("Stop", for: .highlighted)

            try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord, with: AVAudioSessionCategoryOptions.allowBluetooth)

            audioTimeLabel.text = "0.0"
            audioTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(DJVoiceProviderViewController.updateAudioTimeLabel), userInfo: nil, repeats: true)
            
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
        guard audioRecorder.isRecording else { return }
        
        let currentTime = audioRecorder.currentTime
        audioTimeLabel.text = "\(Double(round(10*currentTime)/10))"
    }

    
    @IBAction func stopAudioButtonClicked(_ sender: AnyObject)
    {
        playButton.isEnabled = true
        recordButton.titleLabel?.text = "Record"
        recordButton.setTitle("Record", for: UIControlState())
        recordButton.setTitle("Record", for: .highlighted)
        nextButton.isEnabled = true
        
        if audioRecorder?.isRecording == true {

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
                doneUploadButton.isHidden = false
            }
        } else {
            audioPlayer?.stop()
        }
    }

    
    @IBAction func playRecordedAudioButtonClicked(_ sender: AnyObject)
    {
        if audioRecorder?.isRecording == false {

            recordButton.titleLabel?.text = "Stop"
            recordButton.setTitle("Stop", for: UIControlState())
            recordButton.setTitle("Stop", for: .highlighted)
            
            var error: NSError?
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf:currentSoundFileURL!)
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
    
    @IBAction func nextButtonClicked(_ sender: AnyObject) {
        moveToNextPlayer()
    }
    
    @IBAction func sendRecordingsToServerButtonClicked(_ sender: AnyObject)
    {
        for team in teams
        {
            let order = getOrderForTeam(team)
            
            var allAudioRecordedForTeam = true
            var filePaths = [URL]()
            for playerItem in team.players
            {
                let player = playerItem as! DJPlayer
                if player.audio.voiceProviderURL == nil
                {
                    if (order!.orderStatus != .REVOICING && order!.orderStatus != .ADDONPAID)
                    {
                        allAudioRecordedForTeam = false
                        break
                    }
                }
                else
                {
                    filePaths.append(player.audio.voiceProviderURL)
                }
            }
            
            if allAudioRecordedForTeam && team.teamOrderUploaded == false
            {
                let sem = DispatchSemaphore(value: 0)
                
                DJTeamUploader.shareTeam(team, voicerMode: true)
                { team,success in
                    DJTeamUploader.uploadTeamFilesVoicer(team.teamId, paths: filePaths) {
                        
                        guard let order = self.getOrderForTeam(team) else { sem.signal(); return }
                        
                        DJOrderBackendService.markOrderComplete(self.authToken, order: order)
                        {_,_ in
                            
                            team.teamOrderUploaded = true
                            sem.signal()
                            
                        }
                    }
                }

                sem.wait(timeout: DispatchTime.distantFuture)
            }
            
        }
        
        let alertController = UIAlertController(title: "Info", message: "Orders uploaded to server", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func getOrderForTeam(_ team:DJTeam) -> DJVoiceOrder?
    {
        for order in orders {
            if order.teamId == team.teamId
            {
                return order
            }
        }
        
        return nil
    }
    
    @IBAction func refreshButtonClicked(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "Info", message: "Not implemented yet", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func resetButtonClicked(_ sender: AnyObject)
    {
        delegate?.getOrdersAndTeams() {
            orders, teams in
                self.teams = teams
                self.orders = orders
                self.resetUI()
        }

    }
  
    func audioRecorderBeginInterruption(_ recorder: AVAudioRecorder) {
        print("Here1!!!")
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.titleLabel?.text = "Record"
        recordButton.setTitle("Record", for: UIControlState())
        recordButton.setTitle("Record", for: .highlighted)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error decoding!")
        recordButton.titleLabel?.text = "Record"
        recordButton.setTitle("Record", for: UIControlState())
        recordButton.setTitle("Record", for: .highlighted)
    }

}
