//
//  DJPlayersViewController.h
//  BallparkDJ
//
//  Created by Jonathan Howard on 2/22/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>

#import "DJAudio.h"
#import "DJAppDelegate.h"
#import "DJDetailController.h"
#import "DJLeague.h"
#import "DJTeam.h"
#import "DJPlayer.h"
#import "DJAudio.h"
#import "MBProgressHUD.h"

#define NEXT_UP_TAG 117117

@interface DJPlayersViewController : UIViewController<AVAudioPlayerDelegate, UIPopoverControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, MBProgressHUDDelegate,MFMailComposeViewControllerDelegate>{
    
//    UIColor *defaultcolor;
    UIColor *upnextColor;
    
    NSRange songQueue;
    UITableViewCell *upNext;
    UITableViewCell *currPlay;
    UILabel *nextUpLabel;
    
    NSArray *_products;
    NSNumberFormatter * _priceFormatter;

    MBProgressHUD *HUD;

}

@property (weak, nonatomic) DJAudio *active; 

@property (strong, nonatomic) IBOutlet UITableView *playerTable;
@property (strong, nonatomic) DJTeam *team;
@property (assign, nonatomic) int playerIndex;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *playBtn;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *continuousBtn;

@property (weak, nonatomic) DJAudio *audioPlayer;
@property (strong, nonatomic) DJAppDelegate* parentDelegate;

- (void)save;
- (IBAction)play:(id)sender;
- (IBAction)setContinuous:(id)sender;
- (void)addNewPlayerToTeam:(DJPlayer *) p;

- (void)cancelQueue;
- (void)nextQueueSong:(NSNotification *)notification;
@end
