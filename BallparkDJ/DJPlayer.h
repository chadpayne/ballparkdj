//
//  DJPlayer.h
//  BallparkDJ
//
//  Created by Jonathan Howard on 2/22/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DJAudio.h"

@interface DJPlayer : NSObject <NSCoding> {
    
}

@property (nonatomic,strong) DJAudio * _Nonnull audio;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,assign) int number;
@property BOOL  b_isBench;
@property (nonatomic,assign) BOOL revoicePlayer;
@property (nonatomic,assign) BOOL addOnVoice;
@property (nonatomic,strong) NSString *uuid;

-(nonnull instancetype)init;
-(nonnull instancetype)initWithName:(NSString *_Nonnull)pName andWithNumber:(int)number;

/*
 * NSCoding methods
 */
-(id _Nonnull )initWithCoder:(NSCoder *_Nonnull)coder;
-(void)encodeWithCoder:(NSCoder *_Nonnull)coder;
@end
