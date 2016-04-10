//
//  DJVoiceRecorderViewController.h
//  BallparkDJ
//
//  Created by Timothy Goodson on 6/6/12.
//  Copyright (c) 2012 BallparkDJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioRecorder.h>
#import <AVFoundation/AVAudioSettings.h>
#import "DJAppDelegate.h"
#import "MBProgressHUD.h"

@interface DJRecorderController : UIViewController <AVAudioPlayerDelegate,UIPopoverControllerDelegate, MBProgressHUDDelegate>{
@private
    AVAudioRecorder* _recorder;
    MBProgressHUD *HUD;
    
    NSArray *_products;
    NSNumberFormatter * _priceFormatter;
}
@property (strong, nonatomic) DJAppDelegate* parentDelegate;
@property(strong, nonatomic) AVAudioRecorder* recorder;
@property (strong, nonatomic) DJAudio *announcement;
@property(assign, nonatomic) BOOL isRecording;

@property (strong, nonatomic) IBOutlet UILabel *elapsedTimeMeter;
@property (strong, nonatomic) IBOutlet UIButton *recordPauseButton;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UISegmentedControl *cancelDoneButton;
@property (strong, nonatomic) IBOutlet UIButton *recordButton
;
@property (strong, nonatomic) IBOutlet UIImageView *mainPic;

@property(copy, nonatomic) NSString* filename;
@property(strong, nonatomic) AVAudioPlayer* musicPlayer;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapToStop;

- (void)initRecorderWithFileName:(NSString*)fileName;
- (IBAction)recordPauseButtonDidGetPressed:(id)sender;
- (IBAction)playButtonDidGetPressed:(id)sender;
//- (IBAction)cancelDoneButtonPressed:(UISegmentedControl *)sender;
//- (IBAction)cancelButtonPressed:(UIButton *)sender;
//- (IBAction)doneButtonPressed:(UIButton *)sender;

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL0;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL1;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL2;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL3;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL4;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL5;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL6;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL7;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL8;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL9;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL10;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL11;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL12;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL13;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL14;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL15;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL16;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL17;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL18;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL19;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL20;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL21;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL22;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL23;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL24;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL25;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL26;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *powerMeterL27;


@end
