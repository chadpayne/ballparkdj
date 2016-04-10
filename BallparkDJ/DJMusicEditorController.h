//
//  DJMusicEditorController.h
//  BallparkDJ
//
//  Created by Jonathan Howard on 2/22/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAudioPlayer.h>

#import "DJAudio.h"
#import "DJDetailController.h"
#import "DJClipsController.h"

@interface DJMusicEditorController : UIViewController
    <MPMediaPickerControllerDelegate,
        UIPopoverControllerDelegate,
        UITextFieldDelegate>

@property (assign, nonatomic) double songStart;
@property (assign, nonatomic) double songLength;
@property (strong, nonatomic) NSTimer *startTimer;
@property (strong, nonatomic) NSTimer *lengthTimer;
@property (strong, nonatomic) NSTimer *replayTimer;
@property (strong, nonatomic) NSTimer *stopTimer;


//Model Properties
//@property (retain, nonatomic, readonly) AVAudioPlayer *music;
@property (weak, nonatomic) DJAudio *parentAudio;
@property (strong, nonatomic) NSURL* audioURL;
//View Properties

@property (strong, nonatomic) IBOutlet UISegmentedControl *songLibraryBtn;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (strong, nonatomic) IBOutlet UITextField *songStartTextView;
@property (strong, nonatomic) IBOutlet UITextField *songStartLabel;
@property (strong, nonatomic) IBOutlet UIButton *songStartForward;
@property (strong, nonatomic) IBOutlet UIButton *songStartBackward;
@property (strong, nonatomic) IBOutlet UISlider *songStartSlider;
@property (strong, nonatomic) IBOutlet UITextField *songLengthTextView;
@property (strong, nonatomic) IBOutlet UITextField *songLengthLabel;
@property (strong, nonatomic) IBOutlet UIButton *songLengthForward;
@property (strong, nonatomic) IBOutlet UIButton *songLengthBackward;
@property (strong, nonatomic) IBOutlet UISlider *songLengthSlider;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playBtn;
@property (strong, nonatomic) IBOutlet UISwitch *wholeSongSwitch;
@property (strong, nonatomic) IBOutlet UILabel *wholeSongLabel;

-(void)showUI;
-(void)hideUITotally:(BOOL)bol;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *) nibBundleOrNil playerAudio:(DJAudio *) audioOrNil;
- (IBAction)songLibrarySelector:(UISegmentedControl *)sender;
- (IBAction)startButton:(id)sender;
- (IBAction)cancelStartTimer:(id)sender;
- (IBAction)songStartWillChange:(id)sender;
- (IBAction)songStartChanged:(id)sender;
- (IBAction)lengthButton:(id)sender;
- (IBAction)cancelLengthTimer:(id)sender;
- (IBAction)songLengthWillChange:(id)sender;
- (IBAction)songLengthChanged:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)replay;
- (IBAction)allSongSwitchChanged:(id)sender;

@end
