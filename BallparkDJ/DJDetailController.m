//
//  DJDetailController.m
//  BallparkDJ
//
//  Revised by Jonathan Howard on 3/27/13
//  Created by Jonathan Howard on 2/22/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import "DJDetailController.h"
#import "DJPlayersViewController.h"
#import "DJMusicEditorController.h"
#import "DJRecorderController.h"

@interface DJDetailController (){
    bool newPlayer;
    float overlapHeight;
    NSTimer *overlapTimer;
}

@end

@implementation DJDetailController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withPlayer:(DJPlayer *)p
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.player = p;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem * backButton = [[[UIBarButtonItem alloc] initWithTitle:@"Player" style:UIBarButtonItemStyleDone target:self action:@selector(backButtonPressed:)]autorelease];
    [self.navigationItem setBackBarButtonItem:backButton];
    
    self.overlapSlider = [[DJOverlapSlider alloc] initWithFrame:CGRectMake(100, 700, 500, 300)];
    [self.view addSubview:self.overlapSlider];
    [self.overlapSlider setFrame:CGRectMake(0, 256, 320, 120)];
    
    //round the buttons
    [self.announcePlayBtn.layer setCornerRadius:8.0f];
    [self.announceEditBtn.layer setCornerRadius:8.0f];
    [self.musicEditBtn.layer setCornerRadius:8.0f];
    [self.musicPlayBtn.layer setCornerRadius:8.0f];
   
    if(self.player){
        newPlayer = false;
        self.playerNameField.text = self.player.name;
        [self.benchSlider setOn:self.player.b_isBench];
        
        self.playerNumberField.text = (self.player.number == -42) ? @"" : [NSString stringWithFormat:@"%d",self.player.number];
        if(self.player.name != NULL){
            [self setEditViewsHidden:FALSE];
        }
        
//        [self setSliderValues];
        
        if(self.player.audio.isMusicClipValid){
            [self showMusicPlay];
        }
        
        if(self.player.audio.isAnnouncementClipValid){
             [self showAnnouncePlay];
        }
        
        if(!self.announcePlayBtn.isHidden && !self.musicPlayBtn.isHidden){
            [self.playBtn setEnabled:TRUE];
            [self.overlapSlider setHidden:FALSE];
        } else{
            [self.playBtn setEnabled:FALSE];
            [self.overlapSlider setHidden:TRUE];
        }
        
    }
    else{
        self.player = [[DJPlayer alloc] initWithName:@"New Player" andWithNumber:1];
        newPlayer = true;
        [self setSliderValues];
        [self.playBtn setEnabled:FALSE];
        [self.overlapSlider setHidden:TRUE];
        [self.playerNameField becomeFirstResponder];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handle_DJSliderValueDidChangeNotification:)
                                                 name:@"DJSliderValueDidChangeNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopAudio:)
                                                 name:@"DJSliderDidStartChangeNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMusicPlay) name:@"DJMusicDidSelect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAnnouncePlay) name:@"DJAnnounceDidSave" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playAudio:) name:@"DJOverlapDidReleaseNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAudio:) name:@"DJOverlapDidSelectNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAudio:) name:@"DJAudioDidFinish" object:nil];
  
	// Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToSongFinished) name:@"DJAudioDidFinish" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToSongStarted) name:@"DJAudioDidStart" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToRemovedAudio:) name:@"DJAudioMusicRemoved" object:self.player.audio];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToRemovedAnnounce:) name:@"DJAudioAnnounceRemoved" object:self.player.audio];
    
    [self setSliderValues];
    [super viewWillAppear:animated];
    self.playBtn.title = @"Play";
}

-(void)viewWillDisappear:(BOOL)animated {
    
    self.player.number = (self.playerNumberField.text.length == 0) ? -42 : [self.playerNumberField.text intValue];
    self.player.name = self.playerNameField.text;
    self.player.b_isBench = self.benchSlider.isOn;
    if([self.player.name length] == 0)
        self.player.name = self.player.audio.title;
    
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        if(newPlayer){
            if(self.playerNameField.text.length == 0) {
                if (self.player.audio.isMusicClipValid) {
                    self.player.name = [self getTrackName:self.player.audio.musicURL];
                    [(DJPlayersViewController *)self.parent addNewPlayerToTeam:self.player];
                }
            } else {
                [(DJPlayersViewController *)self.parent addNewPlayerToTeam:self.player];
            }
        } else {
            [((DJPlayersViewController *)self.parent).team.players removeObjectAtIndex:self.playerIndex];
            [((DJPlayersViewController *)self.parent).team.players insertObject:self.player atIndex:self.playerIndex];
            [((DJPlayersViewController *)self.parent).playerTable reloadData];
        }
        [(DJPlayersViewController *)self.parent save];
    }
    [self.player.audio stop];
    [self.playerNameField resignFirstResponder];
    [self.playerNumberField resignFirstResponder];
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)showMusicPlay{
    [self.musicPlayBtn setHidden:FALSE];
    
    if (!self.announcePlayBtn.isHidden) {
        [self.overlapSlider setHidden:FALSE];
        [self.playBtn setEnabled:YES];
    }
    [self setSliderValues];
}

- (void)showAnnouncePlay{
    [self.player.audio setAnnouncementClipPath:self.player.audio.announcementURL];
    overlapHeight = self.overlapSlider.announceBox.frame.size.height;
    [self.announcePlayBtn setHidden:FALSE];
    if(!self.musicPlayBtn.isHidden){
        [self.overlapSlider setHidden:FALSE];
        [self.playBtn setEnabled:YES];
    }
    [self setSliderValues];
}

-(void)handle_DJSliderValueDidChangeNotification:(NSNotification*)notification{
   
//    if (self.player.audio.musicStartTime) {
//        self.player.audio.musicStartTime = self.overlapSlider.trailingDelay;
//    }

    float overlapText = 0;
    if (self.overlapSlider.topFirst) {
        overlapText = [[NSNumber numberWithFloat:self.overlapSlider.maxValueTop - self.overlapSlider.trailingDelay] floatValue];
    } else {
        overlapText = [[NSNumber numberWithFloat:self.overlapSlider.maxValueTop + self.overlapSlider.trailingDelay] floatValue];
    }
    self.player.audio.overlap = self.overlapSlider.trailingDelay;
    
    [self playAudio:nil];
}

-(void)setSliderValues{
//    self.overlapSlider.trailingDelay = self.player.audio.overlap;
    //    [self initializeRecordedAnnouncement];
    //    }
    self.overlapSlider.maxValueTop = self.player.audio.announcementDuration;
    //    if (self.overlapSlider.maxValueTop < 3) {
    //        self.overlapSlider.maxValueTop = 3;
    //    }
   
//    self.overlapSlider.trailingDelay = self.player.audio.overlap;
    self.overlapSlider.maxValueBottom = self.player.audio.musicDuration;
    self.overlapSlider.trailingDelay = self.player.audio.overlap;
}

- (void)backButtonPressed:(id)sender{
    if([self.player.audio isPlaying]){
        [[[self player] audio] stop];
    }
    UIAlertView *derp = [[UIAlertView alloc] initWithTitle:@"Save?"
                                                    message:@"Would you like to save your player?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles: @"Yes", @"No", nil];
    
    [derp show];
    [derp release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [alertView cancelButtonIndex]) {
        
    }
    else if(buttonIndex == 1){
        NSLog(@"%@",[alertView buttonTitleAtIndex:1]);
        if(newPlayer){
            [(DJPlayersViewController *)self.parent addNewPlayerToTeam:self.player];
        } else {
            [((DJPlayersViewController *)self.parent).team.players removeObjectAtIndex:self.playerIndex];
            [((DJPlayersViewController *)self.parent).team.players insertObject:self.player atIndex:self.playerIndex];
            [((DJPlayersViewController *)self.parent).playerTable reloadData];
        }
        [self.navigationController popToViewController:self.parent animated:YES];
        [(DJPlayersViewController *)self.parent save];
    }
    else if(buttonIndex == 2){
          [self.navigationController popToViewController:self.parent animated:YES];
    }
}

//=================================
//
//  TextFieldStuff
//
//=================================

-(BOOL)textFieldShouldReturn:(UITextField*)textField{
    if(textField == self.playerNameField){
        self.player.name = self.playerNameField.text;
        [textField resignFirstResponder];
        [self.playerNumberField becomeFirstResponder];
        [self.playerNumberField setEnabled:TRUE];
        
    }else if(textField == self.playerNumberField){
        self.player.number = (textField.text.length == 0) ? -42 : [self.playerNumberField.text intValue];
        self.player.name = self.playerNameField.text;
        [textField resignFirstResponder];
        //return YES;
        //        self.
    }
    
    else {
//        if (self.player.musicClip.isFirst) {
//            self.overlapSlider.trailingDelay = textField.text.floatValue - self.overlapSlider.maxValueTop;
//        } else {
//            self.overlapSlider.trailingDelay = self.overlapSlider.maxValueTop - textField.text.floatValue;
//        }
//        [textField resignFirstResponder];
    }
    
//    if(self.playerNameField.text.length > 0){
        [self setEditViewsHidden:FALSE];
//    }
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setEditViewsHidden:(bool)hide{
    [self.musicEdit setHidden:hide];
    [self.musicEditBtn setHidden:hide];
    [self.announceEdit setHidden:hide];
    [self.announceEditBtn setHidden:hide];
}


- (void)dealloc {
   /* [_team release];
    [_player release];
   
    [_playerNameField release];
    [_playerNumberField release];
    [_playBtn release];
    [_announceEdit release];
    [_musicEdit release];
    [_announceEdit release];
    [_announceEditBtn release];
    [_musicEdit release];
    [_musicEditBtn release];
    [_musicPlayBtn release];
    [_announcePlayBtn release];*/
    [_benchSlider release];
    [super dealloc];
}
- (void)viewDidUnload {
//    [self setTeam:nil];
////    [self setPlayer:nil];
//    [self setPlayerNameField:nil];
//    [self setPlayerNumberField:nil];
//    [self setPlayBtn:nil];
//    [self setAnnounceEdit:nil];
//    [self setMusicEdit:nil];
//    [self setAnnounceEdit:nil];
//    [self setAnnounceEditBtn:nil];
//    [self setMusicEdit:nil];
//    [self setMusicEditBtn:nil];
//    [self setMusicPlayBtn:nil];
//    [self setAnnouncePlayBtn:nil];
//    [self setOverlapSlider:nil];
    [super viewDidUnload];
}

- (IBAction)musicEdit:(id)sender {
   
    if(self.player.audio)
    {
        if(self.player.audio.isPlaying)
        {
            [self.player.audio stop];
        }
        
        DJMusicEditorController *musicEditor = [[DJMusicEditorController alloc] initWithNibName:@"DJMusicEditorView" bundle:nil playerAudio:self.player.audio];
        [self.navigationController pushViewController:musicEditor animated:YES];
        
    }
    else {
        self.player.audio = [[DJAudio alloc] init];
        DJMusicEditorController *musicEditor = [[DJMusicEditorController alloc] initWithNibName:@"DJMusicEditorView" bundle:nil playerAudio:self.player.audio];
        [self.navigationController pushViewController:musicEditor animated:YES];
    }
}

- (IBAction)musicPlay:(id)sender {
    if([self.player.audio isPlaying]) {
        [self.player.audio stop];
        self.musicPlayBtn.selected = NO;
    } else {
        [self.player.audio playMusic];
        self.musicPlayBtn.selected = YES;
    }
}

- (IBAction)announceEdit:(id)sender {
    if(!self.player.audio){
        self.player.audio = [[DJAudio alloc] init];
    }
    else if(self.player.audio.isPlaying){
        [self.player.audio stop];
    }
 
    DJRecorderController* voiceRecorder = [[[DJRecorderController alloc] initWithNibName:@"DJRecorderController" bundle:nil]autorelease];
    NSDateFormatter *formatter;
    NSString        *dateString;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"ddMMyyyyHHmmSS"];
    
    dateString = [formatter stringFromDate:[NSDate date]];
    NSLog(@"%@", dateString);
    [formatter release];
    voiceRecorder.announcement = self.player.audio;
    [voiceRecorder initRecorderWithFileName:[NSString stringWithFormat:@"%@",dateString]];

    [self presentViewController:voiceRecorder animated:YES completion:nil];
  
}

- (IBAction)announcePlay:(id)sender {
    if([self.player.audio isPlaying]) {
        [self.player.audio stop];
        self.announcePlayBtn.selected = NO;
    } else {
        [self.player.audio playAnnnouncement];
        self.announcePlayBtn.selected = YES;
    }
}

- (IBAction)playAudio:(id)sender {
    if ([self.player.audio isPlaying]) {
        [self.player.audio stop];
        self.playBtn.title = @"Play";
        self.musicPlayBtn.selected = NO;
        self.announcePlayBtn.selected = NO;
    } else {
        [self.player.audio play];
        self.playBtn.title = @"Stop";
    }
}

- (IBAction)stopAudio:(id)sender {
    [self.player.audio stop];
    self.playBtn.title = @"Play";
    self.musicPlayBtn.selected = NO;
    self.announcePlayBtn.selected = NO;
}

-(void)respondToSongFinished {
    self.playBtn.title = @"Play";
    self.musicPlayBtn.selected = NO;
    self.announcePlayBtn.selected = NO;
}

-(void)respondToSongStarted {
    self.playBtn.title = @"Stop";
}

-(void)respondToRemovedAnnounce:(id)sender {
    self.announcePlayBtn.selected = NO;
    self.announcePlayBtn.hidden = TRUE;
    [self.overlapSlider setHidden:TRUE];
    [self.playBtn setEnabled:NO];
}

-(void)respondToRemovedAudio:(id)sender {
    [self.musicPlayBtn setHidden:TRUE];
    [self.overlapSlider setHidden:TRUE];
    [self.playBtn setEnabled:NO];
}

-(NSString *)getTrackName:(NSURL *)url {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    if([[url scheme] isEqualToString:@"ipod-library"]){
        NSRange r = NSMakeRange(0, 32);
        NSString *pid = [[url absoluteString] stringByReplacingCharactersInRange:r withString:@""];
        MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:pid forProperty:MPMediaItemPropertyPersistentID];
        MPMediaQuery *songQuery = [[MPMediaQuery alloc] init];
        [songQuery addFilterPredicate:predicate];
        for (MPMediaItem *song in [songQuery items]) {
            return [song valueForProperty:MPMediaItemPropertyTitle];
        }
    } else {
        for (NSString *format in [asset availableMetadataFormats]) {
            for (AVMetadataItem *metaItem in [asset metadataForFormat:format]) {
                if([metaItem.commonKey isEqualToString:@"title"])
                    return [metaItem stringValue];
            }
        }
    }
    return nil;
}

@end
