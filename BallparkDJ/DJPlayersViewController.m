//
//  DJPlayersViewController.m
//  BallparkDJ
//
//  Created by Jonathan Howard on 2/22/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import "DJPlayersViewController.h"
#import "DJLeagueViewController.h"
#import "BallparkDJ-Swift.h"
//#import "MKStoreKitConfigs.h"
//#import "MKStoreManager.h"
#import "RageIAPHelper.h"
#import <StoreKit/StoreKit.h>
#import <MessageUI/MessageUI.h>

#define SINGLE_LABEL @"Single Play"
#define CONTINUOUS_LABEL @"Continuous Play"

@protocol ClickableImageViewDelegate
-(void)imageClicked:(NSInteger)row;
@end

@interface ClickableImageView : UIImageView
@property(nonatomic,assign) id<ClickableImageViewDelegate> delegate;
@property(nonatomic,strong) DJPlayer *player;
@property(nonatomic,assign) NSInteger row;
@end

@implementation ClickableImageView
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.delegate imageClicked:self.row];
}
@end

@interface NSMutableArray (MoveArray)

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to;

@end

@implementation NSMutableArray (MoveArray)

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to
{
    if (to != from) {
        id obj = [self objectAtIndex:from];
        [self removeObjectAtIndex:from];
        if (to >= [self count]) {
            [self addObject:obj];
        } else {
            [self insertObject:obj atIndex:to];
        }
    }
}
@end

enum PostAuthenticationAction
{
    SHARE_TEAM,
    ORDER_VOICE,
    REORDER_VOICE,
    ADDON_VOICE
};


@interface DJPlayersViewController ()<UINavigationControllerDelegate,EmailAddressViewControllerDelegate,DJPlayerRevoiceViewDelegate> {
    bool playerEditing;
}

@property(nonatomic,strong) MFMailComposeViewController *mailController;
@property(nonatomic,assign) enum PostAuthenticationAction action;

@end

@implementation DJPlayersViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFinishPurchase)
                                                 name:@"InAppPurchase" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFinishRestore)
                                                 name:@"RestoreInAppPurchase" object:nil];

    
    playerEditing = false;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(callDetailViewForNewPlayer:)];
    UIBarButtonItem * backButton = [[UIBarButtonItem alloc] initWithTitle:@"Players" style:UIBarButtonItemStyleDone target:self action:@selector(backButtonPressed:)];
    [self.navigationItem setBackBarButtonItem:backButton];
    //[self.navigationItem setLeftBarButtonItem:backButton animated:YES];
    self.editButtonItem.action = @selector(setEditing);
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.editButtonItem, addButton, nil] animated:YES];
    [self.playerTable reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeRespondsToNotification:) name:@"DJAudioDidFinish" object:nil];
    
    //Set up nextUp view
    CGRect frame = CGRectMake(150, 0, 160, 40);
    UILabel *view = [[UILabel alloc] initWithFrame:frame];
    view.textAlignment = NSTextAlignmentRight;
//    view.text = @"Next Up";
    view.tag = NEXT_UP_TAG;
    view.backgroundColor = [UIColor clearColor];
    
    nextUpLabel = view;
    
    // Set up colors:
    upnextColor = [UIColor colorWithRed:147.0/255.0 green:201.0/255.0 blue:255.0/255.0 alpha:1.0f];
    
	// Do any additional setup after loading the view.
    self.title = @"Players";
    
    [self.playerTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"PlayerCell"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelQueue];
    [super viewWillDisappear:animated];
}

- (void)teamDataUpdated {
    [self.playerTable reloadData];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(teamDataUpdated) name:@"DJTeamDataUpdated" object:self.team];
    
    for (int i = 0; i < [self.team.players count]; i++)
    {
        DJPlayer *player = [self.team.players objectAtIndex:i];
        
        if(player.b_isBench == YES)
        {
            [self.team.players moveObjectFromIndex:i toIndex:[self.team.players count]];
        }
    }
    
     [self.playerTable reloadData];
}

-(void)revoiceRequestCompleted
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Info" message:@"Your request has been successfully sent.  We will notify you via email once the revoicing is completed." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:okButton];
    
    [self presentViewController:alertController animated:NO completion:nil];
}

-(void)addOnRequestCompleted
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Info" message:@"Your request has been successfully sent. Please check your email to complete the voice order." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:okButton];
    
    [self presentViewController:alertController animated:NO completion:nil];
}


//===========================
//
//  IBActions for buttons!
//
//===========================
-(IBAction)backButtonPressed:(id)sender{
    if([[self.team objectInPlayersAtIndex:self.playerIndex].audio isPlaying]){
        [[[[self team] objectInPlayersAtIndex:self.playerIndex] audio] stop];
        [self cancelQueue];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)setEditing {
    playerEditing = !playerEditing;
    [super setEditing:playerEditing animated:YES];
    [self.playerTable setEditing:playerEditing animated:YES];
    
    [[[upNext contentView] viewWithTag:NEXT_UP_TAG] removeFromSuperview];
    [upNext setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
    upNext = nil;
}

-(void)callDetailViewForNewPlayer:(id)sender{
    //TODO: add better receipt checking to IAP
    
    NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];

    BOOL isPurchased = [userDefaults boolForKey:@"IS_ALLREADY_PURCHASED_FULL_VERSION"];
    
    if (self.team.players.count >= 3 && (isPurchased != YES))
    {
        
        HUD = [MBProgressHUD showHUDAddedTo:[DJAppDelegate sharedDelegate].window animated:YES];
        [[DJAppDelegate sharedDelegate].window addSubview:HUD];
        
        HUD.delegate = self;
        HUD.labelText = @"Loading..";
        
        [HUD showWhileExecuting:@selector(removeHud) onTarget:self withObject:nil animated:YES];

        
        [self reload];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
        
        [self performSelector:@selector(presentIAPAlertView) withObject:nil afterDelay:5.0];

        return;
        
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    DJDetailController *detailViewController = [[DJDetailController alloc] initWithNibName:@"DJDetailView" bundle:nil];
    detailViewController.parent = self;
    detailViewController.team = self.team;
    detailViewController.playerIndex = [self.playerTable numberOfRowsInSection:0]-2;
    [self.navigationController pushViewController:detailViewController animated:YES];

}

- (void)removeHud
{
    sleep(4);
    
//    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.team.teamName;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.team.players count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlayerCell";
    
    UITableViewCell *cell = nil;
    
    UILabel *label;
    ClickableImageView *musicImageView;
    ClickableImageView *voiceImageView;

    //
    // ::TODO:: This code needs to be re-written to use XIB's with Auto-layout.
    // Sorry, poor developer - which hopefully is not future me - but I had to add to already messy code
    // and I was under a deadline to finish this :-(
    //
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];

    CGRect rect = cell.bounds;
    rect.origin.x = 20;
    rect.size.width = 228;

    CGRect musicImageRect = CGRectMake(320-38, rect.origin.y + (rect.size.height - 38)/2, 38, 38);
    CGRect voiceImageRect = CGRectMake(320-38-38+7, rect.origin.y + (rect.size.height - 38)/2, 38, 38);

    if (cell.contentView.subviews.count == 0)
    {
        label = [[UILabel alloc] initWithFrame:rect];
        label.tag = indexPath.row + 2000;
        
        musicImageView = [[ClickableImageView alloc] initWithFrame:musicImageRect];
        voiceImageView = [[ClickableImageView alloc] initWithFrame:voiceImageRect];
        
        musicImageView.userInteractionEnabled = YES;
        voiceImageView.userInteractionEnabled = YES;
        musicImageView.delegate = self;
        voiceImageView.delegate = self;
        
        [cell.contentView addSubview:label];
        [cell.contentView addSubview:musicImageView];
        [cell.contentView addSubview:voiceImageView];
    }
    else
    {
        label = cell.contentView.subviews[0];
        label.frame = rect;

        musicImageView = cell.contentView.subviews[1];
        musicImageView.frame = musicImageRect;
        
        voiceImageView = cell.contentView.subviews[2];
        voiceImageView.frame = voiceImageRect;
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    [cell setEditingAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    cell.showsReorderControl = YES;
//    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    DJPlayer *tempPlayer = [self.team objectInPlayersAtIndex:indexPath.row];
    
    musicImageView.player = tempPlayer;
    voiceImageView.player = tempPlayer;
    musicImageView.row = indexPath.row;
    voiceImageView.row = indexPath.row;

    if (tempPlayer.audio.musicURL != nil || [tempPlayer.audio.title length] > 0)
    {
        musicImageView.image = [UIImage imageNamed:@"BPDJ_IconMusicBlueScaled"];
    }
    else
    {
        musicImageView.image = [UIImage imageNamed:@"BPDJ_IconMusicMissingScaled"];
    }

    if (tempPlayer.audio.announcementClip != nil)
    {
        voiceImageView.image = [UIImage imageNamed:@"BPDJ_IconVoiceGoldScaled"];
    }
    else
    {
        voiceImageView.image = [UIImage imageNamed:@"BPDJ_IconVoiceMissingScaled"];
    }

    
    if(tempPlayer.b_isBench == NO)
        label.textColor = [UIColor blackColor];
    else
        label.textColor = [UIColor colorWithRed:129.0 / 255.0 green:129.0 / 255.0 blue:129.0 / 255.0 alpha:1.0];
//        label.textColor = [UIColor colorWithRed:220.0 / 255.0 green:220.0 / 255.0 blue:220.0 / 255.0 alpha:1.0];

    
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    if(tempPlayer.b_isBench == YES)
        selectedBackgroundView.backgroundColor = [UIColor clearColor];
    else
//        selectedBackgroundView.backgroundColor = [UIColor colorWithRed:183.0 / 255.0 green:246.0 / 255.0 blue:150.0 / 255.0 alpha:1.0];
        label.textColor = [UIColor blackColor];
    

    cell.selectedBackgroundView = selectedBackgroundView;

    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    if(tempPlayer.b_isBench == YES)
        backgroundView.backgroundColor = [UIColor colorWithRed:192.0 / 255.0 green:192.0 / 255.0 blue:192.0 / 255.0 alpha:1.0];
    else
        backgroundView.backgroundColor = [UIColor clearColor];
    
    cell.backgroundView= backgroundView;


    NSString *topDigits;
    if([tempPlayer.name isKindOfClass:[NSString class]]){
        if(tempPlayer.number != -42) {
            NSString *allDigits = [NSString stringWithFormat:@"%d", tempPlayer.number];
            if(allDigits.length >= 3){
                topDigits = [@"#" stringByAppendingString:[allDigits substringToIndex:3]];
            }
            else{
                topDigits = [@"#" stringByAppendingString:allDigits];
            }
            topDigits = [[topDigits stringByPaddingToLength:4 withString:@" " startingAtIndex:0] stringByAppendingString:@"\t"];;
        }
        else {
            topDigits = [NSString stringWithFormat:@"    \t"];
        }

        label.text = [topDigits stringByAppendingString:tempPlayer.name];
        UIFont *defaultFont = label.font;
        label.font = [UIFont fontWithName:@"Courier" size:defaultFont.pointSize];
    }
 
    if (self.upNextIndexPath.row == indexPath.row) {
        [[cell contentView] addSubview:nextUpLabel];
        [cell setBackgroundColor:[UIColor colorWithRed:191/255.0f green:238/255.0f blue:252/255.0f alpha:1.0f]];
    }
    
    return cell;
}

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSLog(@"Scroll Event");
//    return YES;
//}



- (void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell  *cell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *label = (UILabel*)[cell.contentView viewWithTag:indexPath.row + 2000];
    
    CGRect rect = label.frame;
    rect.origin.x = 100;
//    rect.size.width = 190;
    
    label.frame = rect;
    
    NSLog(@"Swipe Start");
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onFinish:) userInfo:indexPath repeats:NO];
    

    NSLog(@"Swipe End");
}

- (void) onFinish:(NSTimer*)timer
{
    [UIView beginAnimations:@"moveScrollView" context:nil];
    [UIView setAnimationDuration:0.2];

    NSIndexPath *indexPath = (NSIndexPath*)timer.userInfo;
    
    UITableViewCell  *cell = [self.playerTable cellForRowAtIndexPath:timer.userInfo];
    UILabel *label = (UILabel*)[cell.contentView viewWithTag:indexPath.row + 2000];
    
    CGRect rect = label.frame;
    rect.origin.x = 20;
    rect.size.width = 280;
    label.frame = rect;
    
    [UIView commitAnimations];

}
//UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//
//cell.contentView.backgroundColor = [UIColor lightTextColor];
//cell.backgroundColor = [UIColor lightTextColor];


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.playerIndex = indexPath.row;
//    [self cancelQueue];
    
    
    if(playerEditing) {
        if(self.active) {
            [self setActive:nil];
        }
        playerEditing = !playerEditing;
        [self callDetailViewOnRow:indexPath.row];
        [self setEditing:NO animated:YES];
    }
    else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //        [defaults setBool:NO forKey:@"IS_ALLREADY_PURCHASED_FULL_VERSION"];
        //        [defaults synchronize];
        BOOL isPurchased = [defaults boolForKey:@"IS_ALLREADY_PURCHASED_FULL_VERSION"];
        DJAudio* audio = [[self.team.players objectAtIndex:indexPath.row] audio];;
        
        if (audio.announcementDuration >= 10.0 && isPurchased == NO){
            //        [self ShowIAPAlert];
            HUD = [MBProgressHUD showHUDAddedTo:[DJAppDelegate sharedDelegate].window animated:YES];
            [[DJAppDelegate sharedDelegate].window addSubview:HUD];
            
            HUD.delegate = self;
            HUD.labelText = @"Loading..";
            
            [HUD showWhileExecuting:@selector(removeHud) onTarget:self withObject:nil animated:YES];
            
            
            [self reload];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
            
            [self performSelector:@selector(presentIAPAlertViewForVoice) withObject:nil afterDelay:5.0];
            [[self playBtn] setTitle:@"Play"];
            return;
        }
        DJPlayer    *player = [self.team.players objectAtIndex:indexPath.row];
        if(player.b_isBench == YES)
            return;

        if([self.continuousBtn.title isEqualToString:CONTINUOUS_LABEL])
        {
            [self cancelQueue];
            upNext = [self.playerTable cellForRowAtIndexPath:indexPath];
            [self playSet];
        }
        else
        {
            [self playSingle:[self.playerTable cellForRowAtIndexPath:indexPath]];
            if(self.active) [[self playBtn] setTitle:@"Stop"];
            else [[self playBtn] setTitle:@"Play"];
        }
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    //_setPlaying = NO;
    if(self.active){
        [self setActive:nil];
        [[self playBtn] setTitle:@"Play"];
    }
}

-(void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (int) getFirstBenchIndex
{
    int benchIndex = -1;
    for (int i = 0; i < [self.team.players count]; i++)
    {
        DJPlayer *player = [self.team.players objectAtIndex:i];
        if(player.b_isBench == YES)
        {
            benchIndex = (i - 1 == 0) ? 0 : (i -1);
            break;
        }
    }
    
    return benchIndex;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    int benchIndex = [self getFirstBenchIndex];
    
    DJPlayer *object = [self.team.players objectAtIndex:sourceIndexPath.row];
    
    int val = destinationIndexPath.row;
    
    if(destinationIndexPath.row <= benchIndex)
        object.b_isBench = NO;
    
    [self.team.players removeObjectAtIndex:sourceIndexPath.row];
    [self.team.players insertObject:object atIndex:destinationIndexPath.row];
    
    [tableView reloadData];

}



//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return UITableViewCellEditingStyleDelete;
//}


-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [self.team.players removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadData];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
    }
}

-(void)save{
    [self.parentDelegate.league encode];
}

-(void)addNewPlayerToTeam:(DJPlayer *) p{
    NSLog(@"%@",self.team.teamName);
    NSLog(@"%d", self.team.players.count);
    NSLog(@"%d", [self.playerTable numberOfRowsInSection:0]-1);
    int lastPlayerIdx;
    NSIndexPath *indexPath;
    
    if(self.team.players.count > 0)
    {
        lastPlayerIdx = self.team.players.count;
        BOOL isDuplicate = false;
        for (int i = 0 ; i < self.team.players.count; i++) {
            DJPlayer* player = [self.team.players objectAtIndex:i];
            int player_number = player.number;
            NSString* player_name = player.name;
            if ([p.name isEqualToString:player_name] && p.number == player_number) {
                isDuplicate = true;
            }
        }
        if (isDuplicate == true) {
            return;
        }
        [self.team insertObject:p inPlayersAtIndex:lastPlayerIdx];
        indexPath = [NSIndexPath indexPathForRow:[self.playerTable numberOfRowsInSection:0]-1 inSection:0];
        [self.playerTable insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.playerTable reloadData];
        
        [[self.playerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.playerTable numberOfRowsInSection:0]inSection:0]] setHidden:FALSE];
    } else {
        lastPlayerIdx = 0;
        [self.team insertObject:p inPlayersAtIndex:lastPlayerIdx];
        indexPath = [NSIndexPath indexPathForRow:[self.playerTable numberOfRowsInSection:0] inSection:0];
        [self.playerTable insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.playerTable reloadData];
        [[self.playerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.playerTable numberOfRowsInSection:0]inSection:0]] setHidden:FALSE];
 
    }
}

-(void)callDetailViewOnRow:(NSInteger)selectedRow{
    
    DJDetailController *detailViewController = [[DJDetailController alloc] initWithNibName:@"DJDetailView" bundle:nil withPlayer:[self.team objectInPlayersAtIndex:selectedRow]];
    detailViewController.parent = self;
    detailViewController.team = self.team;
    detailViewController.playerIndex = self.playerIndex;
    
    [self.playerTable setEditing:NO animated:YES];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actionsButtonClicked:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Actions" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *shareAction = [UIAlertAction actionWithTitle:@"Share Team" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self shareTeam];
    }];

    UIAlertAction *duplicateTeamAction = [UIAlertAction actionWithTitle:@"Duplicate Team" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self duplicateTeam];
    }];

    UIAlertAction *orderVoiceAction = [UIAlertAction actionWithTitle:@"Order Voice" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self orderVoice];
    }];

    UIAlertAction *voiceReorderVoiceAction = [UIAlertAction actionWithTitle:@"Request Voice Order Redo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self revoiceOrder];
    }];

    UIAlertAction *orderAddOnPlayerAction = [UIAlertAction actionWithTitle:@"Order Add-On Player(s)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self orderAddOnPlayers];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:shareAction];
    [alertController addAction:duplicateTeamAction];

    // If within grace-period allow for re-order/re-do
    if (self.team.orderRevoiceExpirationDate != nil && [self.team.orderRevoiceExpirationDate compare:[NSDate date]] == NSOrderedDescending)
    {
        [alertController addAction:voiceReorderVoiceAction];
    }
    
    if (self.team.orderId == nil || [self.team.orderId isEqualToString:@""])
    {
        [alertController addAction:orderVoiceAction];
    }
    else
    {
        // Order for team previously placed - display add on option
        [alertController addAction:orderAddOnPlayerAction];
    }
    
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];

}

-(BOOL)userEmailAddressExists
{
    NSString *email = [[NSUserDefaults standardUserDefaults] objectForKey:@"userEmailAddress"];
    
    if (email == nil)
    {
        return NO;
    }
    
    return YES;
}

-(void)revoiceOrderConfirmedGoodToGo
{
    if (![self userEmailAddressExists]) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Security" bundle:nil];
        
        EmailAddressViewController *emailAddressViewController = [storyboard instantiateInitialViewController];
        emailAddressViewController.delegate = self;
        
        self.action = ORDER_VOICE;
        
        [self presentViewController:emailAddressViewController animated:YES completion:nil];
        return;
    }
    
    self.team.teamOwnerEmail = [[NSUserDefaults standardUserDefaults] objectForKey:@"userEmailAddress"];
    
    for (DJPlayer *player in self.team.players)
    {
        player.addOnVoice = NO;
    }
    
    DJPlayerRevoiceViewController *viewController = [[DJPlayerRevoiceViewController alloc] initWithNibName:@"DJPlayerRevoiceView" bundle:[NSBundle mainBundle]];
    viewController.team = self.team;
    viewController.delegate = self;
    [self presentViewController:viewController animated:YES completion:nil];
}
                                                        
-(void)shareTeam
{
    DJTeamUploader *uploader = [[DJTeamUploader alloc] init];
    
    if (![self userEmailAddressExists]) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Security" bundle:nil];
        
        EmailAddressViewController *emailAddressViewController = [storyboard instantiateInitialViewController];
        emailAddressViewController.delegate = self;
        
        self.action = SHARE_TEAM;
        
        [self presentViewController:emailAddressViewController animated:YES completion:nil];
        return;
    }

    if (![MFMailComposeViewController canSendMail]) {
        // No email accounts setup!
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"No email accounts are setup on your device.  Please add an email account and retry" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:okButton];
        
        [self presentViewController:alertController animated:NO completion:nil];
        return;
    }
    
    self.team.teamOwnerEmail = [[NSUserDefaults standardUserDefaults] objectForKey:@"userEmailAddress"];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    if (self.team.teamImportedOrderedOnTestEnvironment) {
        [DJServerInfo setBaseServerURL:[DJServerInfo testServerURL]];
    } else {
        [DJServerInfo setBaseServerURL:[DJServerInfo productionServerURL]];
    }
    
    [uploader shareTeam:self.team completion:^(DJTeam *team,BOOL success) {

        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        
        if (success == NO) {
            return;
        }

        NSString *shareLink =  [NSString stringWithFormat:@"%@/importteam/%@", [DJServerInfo baseServerURL], team.teamId];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        NSString *formatedShareExpirationDate = [dateFormatter stringFromDate:self.team.shareExpirationDate];
                
        self.mailController = [[MFMailComposeViewController alloc] init];
        self.mailController.mailComposeDelegate = self;
        [self.mailController setSubject:[NSString stringWithFormat:@"BallparkDJ Team: %@",team.teamName]];
        [self.mailController setMessageBody:[NSString stringWithFormat:@"I am sharing my BallparkDJ team %@ with you.  To open this team in BallparkDJ, simply open this email on the iPhone or iPad on which you've installed BallparkDJ and click on the link below:\n\n%@\n\nThe team should then appear in BallparkDJ.  Feel free to share the team with other parents, grandparents, kids, coaches, or friends using the Actions: Share Team option.\n\n(Note: If you are unable to open this email on your iPhone or iPad, you may alternatively open Safari on the device and type in the address/URL above.  This link expires on %@).", team.teamName, shareLink, formatedShareExpirationDate] isHTML:NO];
         
        [self presentViewController:self.mailController animated:YES completion:nil];
        
    }];
}

-(void)duplicateTeam
{
    DJLeague *league = ((DJAppDelegate *)[[UIApplication sharedApplication] delegate]).league;
    DJTeam *newTeam = [league duplicateTeam:self.team];
    
    NSString *msg = [NSString stringWithFormat:@"New Team name is %@.", newTeam.teamName];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Info" message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        DJLeagueViewController *leagueController = (DJLeagueViewController *)self.navigationController.viewControllers[0];
        [leagueController teamDataUpdated];
    }];
    [alertController addAction:okButton];
    
    [self presentViewController:alertController animated:NO completion:nil];
}

-(void)orderVoice
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Security" bundle:nil];
    
    EmailAddressViewController *emailAddressViewController = [storyboard instantiateInitialViewController];
    emailAddressViewController.delegate = self;
    
    self.action = ORDER_VOICE;
    
    [self presentViewController:emailAddressViewController animated:YES completion:nil];
}

-(void)orderVoicePostEmailEntered
{
    self.team.teamOwnerEmail = [[NSUserDefaults standardUserDefaults] objectForKey:@"userEmailAddress"];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"VERY IMPORTANT" message:@"Before submitting a team for professional voicing, please ensure you’ve entered all players names and numbers and PRE-RECORD ANY PLAYERS that might be difficult or questionable to pronounce.  More options will be presented after submitted.  For more information, visit www.ballparkdj.com/faq" preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"Submit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self orderVoiceConfirmedGoodToGo];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // do not do anything
    }];

    [alertController addAction:submitAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:NO completion:nil];
}

-(void)orderAddOnPlayers
{
    if (![self userEmailAddressExists]) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Security" bundle:nil];
        
        EmailAddressViewController *emailAddressViewController = [storyboard instantiateInitialViewController];
        emailAddressViewController.delegate = self;
        
        self.action = ADDON_VOICE;
        
        [self presentViewController:emailAddressViewController animated:YES completion:nil];
        return;
    }
    
    self.team.teamOwnerEmail = [[NSUserDefaults standardUserDefaults] objectForKey:@"userEmailAddress"];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Before ordering additional voices for new players for professional voicing, make sure you enter all new players with name and number, and pre-record any players that might be difficult or questionable to pronounce.  More options will be presented after submitting." preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"Select Players" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self orderAddOnPlayersGoodToGo];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // do not do anything
    }];
    
    [alertController addAction:submitAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:NO completion:nil];
}

-(void)orderAddOnPlayersGoodToGo
{
    self.team.teamOwnerEmail = [[NSUserDefaults standardUserDefaults] objectForKey:@"userEmailAddress"];
    
    DJPlayerRevoiceViewController *viewController = [[DJPlayerRevoiceViewController alloc] initWithNibName:@"DJPlayerRevoiceView" bundle:[NSBundle mainBundle]];
    viewController.team = self.team;
    viewController.delegate = self;
    viewController.addOnOrder = true;
    [self presentViewController:viewController animated:YES completion:nil];
}

-(void)revoiceOrder
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Before continuing, please ensure that you have re-recording the voices for any players that are not correct.  You will be prompted to choose the player(s) that need revoicing." preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self revoiceOrderConfirmedGoodToGo];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // do not do anything
    }];
    
    [alertController addAction:submitAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:NO completion:nil];
}


-(void)orderVoiceConfirmedGoodToGo
{
    DJTeamUploader *uploader = [[DJTeamUploader alloc] init];
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    for (DJPlayer *player in self.team.players)
    {
        player.addOnVoice = TRUE;
    }
    
    [uploader orderVoice:self.team completion:^(DJTeam *team,BOOL success) {

        dispatch_async(dispatch_get_main_queue(),^() {
        [MBProgressHUD hideHUDForView:self.view animated:NO];
            
            if (success) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Success" message:@"Team Uploaded: Please check your email to complete the voice order." preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                
                [alertController addAction:okAction];
                
                [self presentViewController:alertController animated:YES completion:nil];
            }
        });
        
    }];
}


#pragma mark - Song Queue:

- (IBAction)play:(id)sender {
//    [[[[self team] objectInPlayersAtIndex:self.playerIndex] audio] stop];
//    [[self.playerTable cellForRowAtIndexPath:[self.playerTable indexPathForSelectedRow]] setSelected:NO];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //        [defaults setBool:NO forKey:@"IS_ALLREADY_PURCHASED_FULL_VERSION"];
    //        [defaults synchronize];
    BOOL isPurchased = [defaults boolForKey:@"IS_ALLREADY_PURCHASED_FULL_VERSION"];

    // Check array bounds
    if (self.playerIndex >= self.team.players.count) {
        
        NSString *msg = self.team.players.count == 0 ? @"You must add at least 1 player to the team." : @"Unable to play player";
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:NO completion:nil];
        return;
    }
    
    DJAudio* audio = [[self.team.players objectAtIndex:self.playerIndex] audio];;

    if (audio.announcementDuration >= 10.0 && isPurchased == NO){
//        [self ShowIAPAlert];
        HUD = [MBProgressHUD showHUDAddedTo:[DJAppDelegate sharedDelegate].window animated:YES];
        [[DJAppDelegate sharedDelegate].window addSubview:HUD];
        
        HUD.delegate = self;
        HUD.labelText = @"Loading..";
        
        [HUD showWhileExecuting:@selector(removeHud) onTarget:self withObject:nil animated:YES];
        
        
        [self reload];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
        
        [self performSelector:@selector(presentIAPAlertViewForVoice) withObject:nil afterDelay:5.0];
        [[self playBtn] setTitle:@"Play"];
        return;
    }
    [sender setEnabled:NO];
    if([[self.playBtn title] isEqual:@"Play"]) {
//        if (UIBarButtonItemStyleDone == self.continuousBtn.style) { //continuous
        if([self.continuousBtn.title isEqualToString:CONTINUOUS_LABEL]) {
            [self playSet];
        } else {
            if(nil != upNext) {
                [self playSingle:upNext];
            } else {
                [self playSingle:[self.playerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]];
            }
        }
    } else {
        [self cancelQueue];
    }
    [sender setEnabled:YES];
}

- (void)playSingle:(UITableViewCell *)sender {
    [self playSingle:sender indexPath:nil];
}

- (void)playSingle:(UITableViewCell *)sender indexPath:(NSIndexPath *)path
{
    self.playBtn.title = @"Stop";
    
    NSIndexPath *indexPath = path ?: [self.playerTable indexPathForCell:sender];
    [self setActive:[[self.team.players objectAtIndex:indexPath.row] audio]];
    [self.playerTable selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self.playerTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];


    //Remove content view:
    for (int i = 0; i < [self.playerTable numberOfRowsInSection:0]; i++) {
        [[[[self.playerTable cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]  ]contentView] viewWithTag:NEXT_UP_TAG] removeFromSuperview];
        [[self.playerTable cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]] setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
    }
    
    [[[sender contentView] viewWithTag:NEXT_UP_TAG] removeFromSuperview];
    [sender setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
    
    
    currPlay = [self.playerTable cellForRowAtIndexPath:indexPath];
    [currPlay setBackgroundColor:[UIColor colorWithRed:154.0 / 255.0 green:250.0 / 255.0 blue:114.0 / 255.0 alpha:1.0]];
    
    //Increment the index path and determine if we're at the end
    
    int benchIndex= [self getFirstBenchIndex];
    
    NSInteger row = [indexPath indexAtPosition:indexPath.length-1]+1;
    if (row > [self.team.players count]-1 || row == (benchIndex + 1)) row = 0;
    
    indexPath = [[indexPath indexPathByRemovingLastIndex] indexPathByAddingIndex:row];
    
    //Add the contentview to the new up next
    upNext = [self.playerTable cellForRowAtIndexPath:indexPath];
    self.upNextIndexPath = indexPath;
    [[upNext contentView] addSubview:nextUpLabel];
    [upNext setBackgroundColor:[UIColor colorWithRed:191/255.0f green:238/255.0f blue:252/255.0f alpha:1.0f]];
}

- (void)playSet {
    if([[self.playBtn title] isEqual:@"Play"]) {
        //Get the relevant subset of the playlist
        
        int benchIndex = [self getFirstBenchIndex] == -1 ? [self.team.players count] : [self getFirstBenchIndex] + 1;
        
        NSRange range;
        range.location = (upNext) ? [[self.playerTable indexPathForCell:upNext] row] : 0;
        range.length = (benchIndex)-range.location;
        
        songQueue = range;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(nextQueueSong:) name:@"DJAudioDidFinish" object:nil];
        
        [self nextQueueSong:nil];
        [[self playBtn] setTitle:@"Stop"];
    }
    else if([[self.playBtn title] isEqual:@"Stop"]) {
        [[self playBtn] setTitle:@"Play"];
        [self cancelQueue];
    }
}

- (IBAction)setContinuous:(id)sender {
    if ([self.continuousBtn.title isEqualToString:CONTINUOUS_LABEL]) {
        self.continuousBtn.title = SINGLE_LABEL; //is enabled, disable
    } else {
        self.continuousBtn.title = CONTINUOUS_LABEL; //is disabled, enable
    }
}

-(void)cancelQueue {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeRespondsToNotification:) name:@"DJAudioDidFinish" object:nil];
    if (self.active) {
        [self setActive:nil];
    }
//    [[self.playerTable cellForRowAtIndexPath:[self.playerTable indexPathForSelectedRow]] setSelected:NO];
    [self.playerTable deselectRowAtIndexPath:[self.playerTable indexPathForSelectedRow] animated:YES];
    
    [[self playBtn] setTitle:@"Play"];
}

-(void)nextQueueSong:(NSNotification *)notification {
    if(notification) {
        songQueue = NSMakeRange(++songQueue.location, --songQueue.length);
    }
    if (0 == songQueue.length) {
        [self cancelQueue];
        return;
    }
    DJPlayer *player = self.team.players[songQueue.location];
    
    
//    NSIndexPath *indexPath = [self.playerTable indexPathForCell:cell];
    DJAudio* audio = [player audio];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //        [defaults setBool:NO forKey:@"IS_ALLREADY_PURCHASED_FULL_VERSION"];
    //        [defaults synchronize];
    BOOL isPurchased = [defaults boolForKey:@"IS_ALLREADY_PURCHASED_FULL_VERSION"];
    if (audio.announcementDuration >= 10.0 && isPurchased == NO){
//        songQueue = NSMakeRange(++songQueue.location, --songQueue.length);
//        if (0 == songQueue.length) {
//            [self cancelQueue];
//            return;
//        }
        HUD = [MBProgressHUD showHUDAddedTo:[DJAppDelegate sharedDelegate].window animated:YES];
        [[DJAppDelegate sharedDelegate].window addSubview:HUD];
        
        HUD.delegate = self;
        HUD.labelText = @"Loading..";
        
        [HUD showWhileExecuting:@selector(removeHud) onTarget:self withObject:nil animated:YES];
        
        
        [self reload];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
        
        [self performSelector:@selector(presentIAPAlertViewForVoice) withObject:nil afterDelay:5.0];
        return;
    }
    
    NSIndexPath *fullPath = [NSIndexPath indexPathForRow:songQueue.location inSection:0];
    
    [self playSingle:[self.playerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:songQueue.location inSection:0]] indexPath:fullPath];
//    [self setActive:[[songQueue objectAtIndex:0] audio]];
    
}

-(void)setActive:(DJAudio *)active {
    if (_active.isPlaying) [_active stopWithFade];
    _active = active;
    if(nil != _active) {
        
        [_active play];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"_ActiveDidPlay" object:self];
    }
    NSLog(@"Active changed: %@", active);
}

-(void)activeRespondsToNotification:(NSNotification *)notification {
    if(notification.object == self.active) {
        [self setActive:nil];

        self.playBtn.title = @"Play";
        currPlay = [self.playerTable cellForRowAtIndexPath:[self.playerTable indexPathForSelectedRow]];
        [currPlay setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
        [self.playerTable deselectRowAtIndexPath:[self.playerTable indexPathForSelectedRow] animated:YES];
    }
}

-(void)imageClicked:(NSInteger)row
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    playerEditing = YES;
    [self tableView:self.playerTable didSelectRowAtIndexPath:indexPath];
}




# pragma marks - In App Purchase.

- (void)productPurchased:(NSNotification *)notification {
    
    NSString * productIdentifier = notification.object;
    [_products enumerateObjectsUsingBlock:^(SKProduct * product, NSUInteger idx, BOOL *stop) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            *stop = YES;
        }
    }];
}
- (void)presentIAPAlertViewForVoice {
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Upgrade!" message:@"The free version of BallparkDJ allows playback of voice recordings up to 10 seconds. Click below to purchase the full version for unlimited voice duration." delegate:self cancelButtonTitle:@"Continue Evaluating" otherButtonTitles:@"Upgrade to Pro ($6.99)", @"I've Already Upgraded!", nil];
    [a show];
}
- (void)presentIAPAlertView {
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Upgrade!" message:@"BallparkDJ is free for evaluation allowing up to 3 teams and 3 players per team.  Upgrade to the Pro version which allows full functionality with unlimited teams and unlimited players per team." delegate:self cancelButtonTitle:@"Continue Evaluating" otherButtonTitles:@"Upgrade to Pro ($6.99)", @"I've Already Upgraded!", nil];
    [a show];
}

-(void)stopHUDLoop
{
    if(HUD == nil)
        return;
    
    [HUD show:NO];
    [HUD removeFromSuperview];
    HUD = nil;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    self.playBtn.title = @"Play";
    switch (buttonIndex) {
        case 0:
            return;
        case 1:
        {
            HUD = [MBProgressHUD showHUDAddedTo:[DJAppDelegate sharedDelegate].window animated:YES];
            [[DJAppDelegate sharedDelegate].window addSubview:HUD];
            HUD.delegate = self;
            HUD.dimBackground = YES;
            HUD.labelText = @"Loading...";
            [HUD show:YES];

            
            SKProduct *product = _products[0];
            
            NSLog(@"Buying %@...", product.productIdentifier);
            [[RageIAPHelper sharedInstance] buyProduct:product];

            [self performSelector:@selector(stopHUDLoop) withObject:nil afterDelay:12.0];

            break;
        }
        case 2:
        {
            HUD = [MBProgressHUD showHUDAddedTo:[DJAppDelegate sharedDelegate].window animated:YES];
            [[DJAppDelegate sharedDelegate].window addSubview:HUD];
            HUD.delegate = self;
            HUD.dimBackground = YES;
            HUD.labelText = @"Loading...";
            [HUD show:YES];

            
            [[RageIAPHelper sharedInstance] restoreCompletedTransactions];

            [self performSelector:@selector(stopHUDLoop) withObject:nil afterDelay:12.0];

            break;
        }
        default:
            return;
    }
}

- (void) CallIAPPopup
{

}


- (void) onFinishPurchase
{
    [self stopHUDLoop];
}

- (void) onFinishRestore
{
    [self stopHUDLoop];
    
    [[[UIAlertView alloc] initWithTitle:@"Congratulation!" message:@"Successfully Restored" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

}

- (void)reload {
    _products = nil;
    [[RageIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            _products = products;
        }
    }];
    
    NSLog(@"_products in reload : %@", _products);
}

#pragma mark - Mail delegate methods
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EmailAddressViewController delegate
-(void)emailAddressEntered:(NSString *)emailAddress
{
    // Store user email
    [[NSUserDefaults standardUserDefaults] setObject:emailAddress forKey:@"userEmailAddress"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (self.action == SHARE_TEAM)
    {
        self.team.teamOwnerEmail = emailAddress;
        [self shareTeam];
    }
    else if (self.action == ORDER_VOICE)
    {
        self.team.teamOwnerEmail = emailAddress;
        [self orderVoicePostEmailEntered];
    }
    else if (self.action == REORDER_VOICE)
    {
        self.team.teamOwnerEmail = emailAddress;
        [self revoiceOrder];
    }
    else if (self.action == ADDON_VOICE)
    {
        self.team.teamOwnerEmail = emailAddress;
        [self orderAddOnPlayers];
    }
}

@end
