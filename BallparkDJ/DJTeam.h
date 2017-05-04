//
//  DJTeam.h
//  BallparkDJ
//
//  Created by Jonathan Howard on 2/22/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DJPlayer.h"

@interface DJTeam : NSObject <NSCoding> {
    
}

@property (nonnull, strong, nonatomic) NSMutableArray<DJPlayer *> *players;
@property (strong, nonatomic) NSString *teamName;
@property (strong, nonatomic) NSString *teamId;
@property (strong, nonatomic) NSString *teamOwnerEmail;
@property (strong, nonatomic) NSDate *orderRevoiceExpirationDate;
@property (strong, nonatomic) NSDate *shareExpirationDate;
@property (strong, nonatomic) NSString *orderId;
@property (assign, nonatomic) BOOL voiceReOrder;
@property (assign, nonatomic) BOOL voiceAddOn;
@property (assign, nonatomic) BOOL teamOrderUploaded;
@property (assign, nonatomic) BOOL teamImportedOrderedOnTestEnvironment;

-(id)initWithName:(NSString *)name;

-(id)initWithCoder:(NSCoder *)coder;
//-(id)initWithUnarchiver:(NSKeyedUnarchiver *)unarchiver withPath:(NSString *) index;
//-(void)encodeWithArchiver:(NSKeyedArchiver *)archiver withPath:(NSString *) index;
-(void)encodeWithCoder:(NSCoder *)coder;
-(void)insertObject:(DJPlayer *)player inPlayersAtIndex:(NSInteger)index;
-(DJPlayer*)objectInPlayersAtIndex:(NSUInteger)index;
@end
