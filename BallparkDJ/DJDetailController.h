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
#import <StoreKit/StoreKit.h>
#import "MBProgressHUD.h"

@interface DJDetailController : UIViewController <UIAlertViewDelegate,UIPopoverControllerDelegate,MBProgressHUDDelegate>{
    MBProgressHUD *HUD;
    NSArray *_products;
}

//Model objects
@property (strong, nonatomic) DJTeam *team;
@property (strong, nonatomic) DJPlayer *player;
@property (assign, nonatomic) int playerIndex;
@property (weak, nonatomic) UIViewController *parent;

//View Objects
@property (strong, nonatomic) IBOutlet UITextField *playerNumberField;
@property (strong, nonatomic) IBOutlet UITextField *playerNameField;
@property (strong, nonatomic) IBOutlet UIButton *announceEditBtn;
@property (strong, nonatomic) IBOutlet UIButton *announcePlayBtn;
@property (strong, nonatomic) IBOutlet UIView *announceEdit;
@property (strong, nonatomic) DJOverlapSlider* overlapSlider;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playBtn;

@property (strong, nonatomic) IBOutlet UIButton *musicEditBtn;
@property (strong, nonatomic) IBOutlet UIButton *musicPlayBtn;
@property (strong, nonatomic) IBOutlet UIView *musicEdit;
@property (strong, nonatomic) IBOutlet UISwitch *benchSlider;
@property (strong, nonatomic) IBOutlet UIView *vwRelativeVolume;
@property (strong, nonatomic) IBOutlet UISlider *sliderVolumeMode;
@property (strong, nonatomic) IBOutlet UILabel *lblRoudestMusic;
@property (strong, nonatomic) IBOutlet UIButton *btnRoudestMusic;
@property (strong, nonatomic) IBOutlet UILabel *lblRouderMusic;
@property (strong, nonatomic) IBOutlet UIButton *btnRouderMusic;
@property (strong, nonatomic) IBOutlet UILabel *lblEven;
@property (strong, nonatomic) IBOutlet UIButton *btnEven;
@property (strong, nonatomic) IBOutlet UILabel *lblRouderVoice;
@property (strong, nonatomic) IBOutlet UIButton *btnRouderVoice;
@property (strong, nonatomic) IBOutlet UILabel *lblRoudestVoice;
@property (strong, nonatomic) IBOutlet UIButton *btnRoudestVoice;

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
