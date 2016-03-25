//
//  BallparkDJTests.m
//  BallparkDJTests
//
//  Created by Jonathan Howard on 2/21/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import "BallparkDJTests.h"
#import "DJAudio.h"
#import "DJPlayer.h"
#import "DJTeam.h"

@implementation BallparkDJTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

-(void)testSerialization {
    DJAudio *audio = [[DJAudio alloc] init];
    DJPlayer *player = [[DJPlayer alloc] init];
    DJTeam *team = [[DJTeam alloc] init];
    
    player.name = @"Master Chief";
    player.number = 117;
    player.audio = nil;
    
    team.teamName = @"Halo";
    [[team players] addObject:player];
    
    DJTeam *sTeam = [[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:team]] retain]
    ;
    
    //Team Assertations
    STAssertEqualObjects([team teamName], [sTeam teamName], @"FAILURE: sTeam comparison failed.");
    //Player assertations
    STAssertEqualObjects([player name], [(DJPlayer *)[[sTeam players] objectAtIndex:(NSUInteger)0] name], @"FAILURE: sPlayers comparison failed;");
    STAssertEqualObjects([player number], [(DJPlayer *)[[sTeam players] objectAtIndex:(NSUInteger)0] number], @"FAILURE: sPlayers comparison failed;");
    
    /**
     * File archiving
     **/
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"txt.txt"];
    
    [NSKeyedArchiver archiveRootObject:team toFile:path];
    DJTeam *fTeam = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    STAssertEqualObjects([team teamName], [fTeam teamName], @"FAILURE: fTeam comparison failed.");
    //Player assertations
    STAssertEqualObjects([player name], [[[fTeam players] objectAtIndex:(NSUInteger)0] name], @"FAILURE: fPlayers name comparison failed;");
    STAssertEqualObjects([player number], [(DJPlayer *)[[fTeam players] objectAtIndex:(NSUInteger)0] number], @"FAILURE: fPlayers # comparison failed;");
    
}

@end
