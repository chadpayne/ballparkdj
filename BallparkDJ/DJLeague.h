//
//  DJLeague.h
//  BallparkDJ
//
//  Created by Jonathan Howard on 2/22/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DJTeam.h"


@interface DJLeague : NSObject {
    NSString *_dataPath;
}

@property (strong, nonatomic) NSMutableArray *teams;


-(id)init;
-(void)encode;

-(DJTeam *)getObjectAtIndex:(int)idx;
-(void)addTeam:(DJTeam*) team;
-(void)insertObject:(DJTeam *)object inTeamsAtIndex:(int)index;
-(DJTeam *)duplicateTeam:(DJTeam *)team;
-(void)importTeam:(DJTeam *)team;

-(void)saveTeam:(DJTeam *)team;

- (void)reorderTeams:(NSIndexPath *)origin toIndexPath:(NSIndexPath *)destination;
//-(void)encodeWithCoder:(NSCoder *)coder;

@end
