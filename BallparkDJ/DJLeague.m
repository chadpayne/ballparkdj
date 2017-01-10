//
//  DJLeague.m
//  BallparkDJ
//
//  Created by Jonathan Howard on 2/22/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import "DJLeague.h"
#import <Foundation/Foundation.h>

@implementation DJLeague {
    bool saving;
}

#pragma mark - Serialization:
#define djTeams @"teamsKey"
#define djDataFile @"data.plist"
#define djTeamCount @"teamCount"

-(id)init{
    self = [super init];
    if(self) {
        self.teams = [[NSMutableArray alloc] init];
        if([[NSFileManager defaultManager] fileExistsAtPath:[[self dataPath]
                                                             stringByAppendingPathComponent:@"teams"]]) {
            NSNumber *num = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self dataPath]
                                        stringByAppendingPathComponent:@"teams"]];

            for(int i = 0; i < [num integerValue]; i++) {
                [[self teams] addObject:[NSKeyedUnarchiver
                                         unarchiveObjectWithFile:
                                         [[self dataPath] stringByAppendingPathComponent:
                                          [NSString stringWithFormat:@"%i", i]]]];
            }
        }
    }
    return self;
}

-(void)encode {
    for(int i = 0; i < [self.teams count]; i++) {
        [NSKeyedArchiver archiveRootObject:[self.teams objectAtIndex:i]
                                    toFile:[[self dataPath]
                                            stringByAppendingPathComponent:[NSString stringWithFormat:@"%i", i]]];
    }
    [NSKeyedArchiver archiveRootObject:[NSNumber numberWithUnsignedInteger:[self.teams count]] toFile:[[self dataPath]
         stringByAppendingPathComponent:@"teams"]];
}

-(NSString *)dataPath {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    // Prevent potential crash
    if (paths.count == 0) {
        return nil;
    }
    
        return [paths objectAtIndex:0];
}

#pragma mark - Teams:

-(DJTeam *)getObjectAtIndex:(int)idx {

    // Prevent potential crash
    if (idx >= self.teams.count) {
        return nil;
    }
    
    return [self.teams objectAtIndex:idx];
}

-(void)addTeam:(DJTeam *)team {
    [self.teams addObject:team];
}

- (void)insertObject:(DJTeam *)object inTeamsAtIndex:(int)index{
    [self.teams insertObject:object atIndex:index];
}

- (void)reorderTeams:(NSIndexPath *)origin toIndexPath:(NSIndexPath *)destination{
    [self.teams exchangeObjectAtIndex:origin.row withObjectAtIndex:destination.row];
}

-(void)saveTeam:(DJTeam *)team {
    [self encode];
}

-(DJTeam *)duplicateTeam:(DJTeam *)team
{
    NSData *teamData = [NSKeyedArchiver archivedDataWithRootObject:team];
    
    if (teamData == nil)
    {
        // ::TODO: Indicate operation failed
        return nil;
    }
    
    DJTeam *newTeam = [NSKeyedUnarchiver unarchiveObjectWithData:teamData];
    newTeam.teamName = [self generateUniqueTeamName:newTeam];
    
    [self.teams addObject:newTeam];
    
    // Force save
    [self encode];

    // Send Notification so main UI can refresh
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DJTeamDataUpdated" object:nil];
    
    return newTeam;
}

-(void)importTeam:(DJTeam *)team
{
    // Check to see if we are updating a team
    int teamIndex = 0;
    NSInteger foundTeamIndex = NSNotFound;
    
    for (DJTeam *aTeam in self.teams)
    {
        if ([aTeam.teamId isEqualToString:team.teamId])
        {
            foundTeamIndex = teamIndex;
            break;
        }
        teamIndex++;
    }

    // Update current array, save, and send notification
    if (foundTeamIndex != NSNotFound)
    {
        DJTeam *foundTeam = self.teams[foundTeamIndex];
        
        // Replace order information
        foundTeam.orderRevoiceExpirationDate = team.orderRevoiceExpirationDate;
        foundTeam.orderId = team.orderId;
        
        // For each player in team for server - get PlayerID
        for (DJPlayer *serverPlayer in team.players)
        {
            // If UUID matches - then replace recorded audio only in merge
            BOOL audioMerged = NO;
            if (serverPlayer.uuid != nil && ![serverPlayer.uuid isEqualToString:@""])
            {
                for (DJPlayer *localPlayer in foundTeam.players)
                {
                    if ([localPlayer.uuid isEqualToString:serverPlayer.uuid])
                    {
                        localPlayer.audio.announcementURL = serverPlayer.audio.announcementURL;
                        localPlayer.audio.announcementClip = serverPlayer.audio.announcementClip;
                        localPlayer.audio.announcementDuration = serverPlayer.audio.announcementDuration;
                        localPlayer.audio.announcementVolume = serverPlayer.audio.announcementVolume;

                        audioMerged = YES;
                    }
                }
            }

            if (audioMerged == NO)
            {
                // Attempt merge based on Player # and Name - as no 2 players should
                // have both the same # and name (at least I hope not).
                for (DJPlayer *localPlayer in foundTeam.players)
                {
                    if ([localPlayer.name isEqualToString:serverPlayer.name] && localPlayer.number == serverPlayer.number)
                    {
                        localPlayer.audio.announcementURL = serverPlayer.audio.announcementURL;
                        localPlayer.audio.announcementClip = serverPlayer.audio.announcementClip;
                        localPlayer.audio.announcementDuration = serverPlayer.audio.announcementDuration;
                        localPlayer.audio.announcementVolume = serverPlayer.audio.announcementVolume;
                        audioMerged = YES;
                    }
                }
            }

            // If we reach here then this must be a new player that we don't have, so
            // lets add to team
            if (audioMerged == NO)
            {
                [foundTeam.players addObject:serverPlayer];
            }
        }
        
        
        [self encode];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DJTeamDataUpdated" object:nil];
        return;
    }
    
    
    DJTeam *newTeam = team;
    newTeam.teamName = [self generateUniqueTeamName:newTeam];

    [self.teams addObject:newTeam];
    
    // Force save
    [self encode];
    
    // Send Notification so main UI can refresh
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DJTeamDataUpdated" object:nil];
}


-(NSString *)generateUniqueTeamName:(DJTeam *)team
{
    BOOL teamNameFound = false;
    
    for (DJTeam *aTeam in self.teams)
    {
        if ([team.teamName isEqualToString:aTeam.teamName])
        {
            teamNameFound = true;
            break;
        }
    }
    
    if (!teamNameFound)
    {
        return team.teamName;
    }
    
    NSArray *teamNameComponents = [team.teamName componentsSeparatedByString:@"-"];
    NSString *teamNamePrefix = @"";
    
    if (teamNameComponents.count == 1)
    {
        teamNamePrefix = teamNameComponents[0];
    }
    else
    {
        for (int i=0; i < teamNameComponents.count-1; i++)
        {
            teamNamePrefix = [teamNamePrefix stringByAppendingString:teamNameComponents[i]];
            
            if (i < teamNameComponents.count-2)
            {
                teamNamePrefix = [teamNamePrefix stringByAppendingString:@"-"];
            }
        }
    }
    
    NSInteger teamSuffixIndex = 0;
    for (DJTeam *aTeam in self.teams)
    {
        if ([aTeam.teamName hasPrefix:teamNamePrefix])
        {
            teamSuffixIndex++;
        }
    }
    
    NSString *teamName = [[NSString alloc] initWithFormat:@"%@-%ld",teamNamePrefix, (long)teamSuffixIndex];
    return teamName;
}


@end
