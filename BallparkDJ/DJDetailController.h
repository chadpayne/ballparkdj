//
//  DJDetailController.h
//  BallparkDJ
//
//  Created by Jonathan Howard on 2/22/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DJLeague.h"
#import "DJAppDelegate.h"
#import "DJTeam.h"
#import "DJPlayer.h"
#import "DJOverlapSlider.h"
#import <QuartzCore/QuartzCore.h>

@interface DJDetailController : UIViewController <UIAlertViewDelegate,UIPopoverControllerDelegate>

//Model objects
@property (retain, nonatomic) DJTeam *team;
@property (retain, nonatomic) DJPlayer *player;
@property (assign, nonatomic) int playerIndex;
@property (assign, nonatomic) UIViewController *parent;

//View Objects
@property (retain, nonatomic) IBOutlet UITextField *playerNumberField;
@property (retain, nonatomic) IBOutlet UITextField *playerNameField;
@property (retain, nonatomic) IBOutlet UIButton *announceEditBtn;
@property (retain, nonatomic) IBOutlet UIButton *announcePlayBtn;
@property (retain, nonatomic) IBOutlet UIView *announceEdit;
@property (retain, nonatomic) DJOverlapSlider* overlapSlider;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *playBtn;

@property (retain, nonatomic) IBOutlet UIButton *musicEditBtn;
@property (retain, nonatomic) IBOutlet UIButton *musicPlayBtn;
@property (retain, nonatomic) IBOutlet UIView *musicEdit;
@property (retain, nonatomic) IBOutlet UISwitch *benchSlider;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withPlayer:(DJPlayer *)p;

- (IBAction)musicEdit:(id)sender;
- (IBAction)musicPlay:(id)sender;
- (IBAction)announceEdit:(id)sender;
- (IBAction)announcePlay:(id)sender;

- (IBAction)playAudio:(id)sender;
- (IBAction)stopAudio:(id)sender;

-(void)respondToRemovedAnnounce:(id)sender;
-(void)respondToRemovedAudio:(id)sender;
@end
