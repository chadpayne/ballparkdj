//
//  DJPlayer.m
//  BallparkDJ
//
//  Created by Jonathan Howard on 2/22/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import "DJPlayer.h"

@implementation DJPlayer

@synthesize audio;
@synthesize name;
@synthesize number;
@synthesize b_isBench;

#pragma mark - Initialization:

-(id)init {
    self = [super init];
    if (self) {
        self.audio = [[DJAudio alloc] init];
        self.revoicePlayer = NO;
        self.addOnVoice = NO;
    }
    return self;
}

-(id)initWithName:(NSString *)pName andWithNumber:(int)pNumber {
    self = [super init];
    self.name = pName;
    self.number = pNumber;
    self.audio = [[DJAudio alloc] init];
    self.b_isBench = NO;
    self.revoicePlayer = NO;
    self.addOnVoice = NO;
    
    return self;
}

#pragma mark - Serialization:

-(id)initWithCoder:(NSCoder *)coder {
    self.audio = [coder decodeObjectForKey:@"_audio"];
    self.name  = [coder decodeObjectForKey:@"_name"];
    self.number = [coder decodeIntForKey:@"_number"];
    self.b_isBench = [coder decodeIntForKey:@"_bench"];
    self.revoicePlayer = NO;
    if ([coder containsValueForKey:@"_revoicePlayer"])
    {
        self.revoicePlayer = [coder decodeBoolForKey:@"_revoicePlayer"];
    }
    self.addOnVoice = NO;
    if ([coder containsValueForKey:@"_addOnVoice"])
    {
        self.addOnVoice = [coder decodeBoolForKey:@"_addOnVoice"];
    }

    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.audio forKey:@"_audio"];
    [coder encodeObject:self.name forKey:@"_name"];
    [coder encodeInt:self.number forKey:@"_number"];
    [coder encodeInt:self.b_isBench forKey:@"_bench"];
    [coder encodeBool:self.revoicePlayer forKey:@"_revoicePlayer"];
    [coder encodeBool:self.addOnVoice forKey:@"_addOnVoice"];
}

@end
