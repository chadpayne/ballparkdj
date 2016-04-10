//
//  DJLeagueViewController.h
//  BallparkDJ
//
//  Created by Jonathan Howard on 3/1/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DJAppDelegate.h"
#import "MBProgressHUD.h"


@interface DJLeagueViewController : UIViewController<UIPopoverControllerDelegate, MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    
    NSArray *_products;
    NSNumberFormatter * _priceFormatter;

}

@property (strong, nonatomic) IBOutlet UITableView *teamTable;
@property (strong, nonatomic) DJAppDelegate* parentDelegate;
@property (strong, nonatomic) IBOutlet UIView *teamNameView;
@property (strong, nonatomic) IBOutlet UITextField *teamNameField;
@end
