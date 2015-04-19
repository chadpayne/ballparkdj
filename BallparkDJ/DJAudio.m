//
//  DJAudio.m
//  BallparkDJ
//
//  Created by Jonathan Howard on 2/21/13.
//  Copyright (c) 2013 BallparkDJ. All rights reserved.
//

#import "DJAudio.h"

@implementation DJAudio

@synthesize overlap,musicStartTime,announcementDuration;
@synthesize shouldFade;
@synthesize title;

//Very confusing name–songDuration is the duration of the song
// musicDuration is the duration of the music subclip
-(double)songDuration {
    return musicClip.duration;
}

#pragma mark - Initialization:

-(id)init {
    self = [super init];
    announcementClip = nil;
    musicClip   = nil;
    
    overlap = -0.5;
    self.musicStartTime = 0.0;
    self.musicDuration = 8.0;
    shouldFade = false;
    self.shouldPlayAll = NO;
    
    timer = [[NSTimer alloc] init];
    return self;
    self.isDJClip = NO;
    self.title = @"Test";
    
}

-(id)initFromAnnouncePath:(NSURL *)aPath andMusicPath:(NSURL *)mPath {
    self = [super init];
    
    NSError *err = nil;
    announcementClip    =  [[[AVAudioPlayer alloc]
                                initWithContentsOfURL:aPath
                                    error:&err] retain];
    if(err){
        announcementClip = nil;
        err = nil;
    }
    musicClip           =  [[[AVAudioPlayer alloc]
                                initWithContentsOfURL:mPath
                                    error:&err] retain];
    if (err) {
        NSLog(@"%@", err);
        musicClip = nil;
        err = nil;
    }
    [announcementClip prepareToPlay];
    [musicClip prepareToPlay];
    
    overlap = 0.0;
    musicStartTime = 0.0;
    self.musicDuration = 8.0;
    shouldFade = false;
    timer = [[NSTimer alloc] init];
    
    [self play];
    [self stop];
    
    return self;
}

#pragma mark - Serialization:

-(id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    NSLog(@"%@", [coder decodeObjectForKey:@"_musicURL"]);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

//    NSLog(@"TEST: %@", [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:basePath, [[coder decodeObjectForKey:@"_announcementURL"] lastPathComponent], nil]]);
    
    announcementClip =  [[AVAudioPlayer alloc]
                         initWithContentsOfURL:[NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:basePath, [[coder decodeObjectForKey:@"_announcementURL"] lastPathComponent], nil]]
                                error:nil];
    
    if([[[coder decodeObjectForKey:@"_musicURL"] scheme] isEqual:@"ipod-library"]) {
        
//        NSURL *url = [NSURL URLWithString:[coder decodeObjectForKey:@"_musicURL"]];
        
        musicClip =         [[AVAudioPlayer alloc]
                            initWithContentsOfURL:[coder decodeObjectForKey:@"_musicURL"]
                                error:nil];
    } else {
        
        NSLog(@"Title /=/%@", [coder decodeObjectForKey:@"_title"]);
        
        NSString *path = nil;
        
        if([[coder decodeObjectForKey:@"_title"] length] > 0)
            path = [[NSBundle mainBundle] pathForResource:[coder decodeObjectForKey:@"_title"] ofType:@"m4a"];

        if(path)
            musicClip = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] error:nil];
        else
            musicClip =         [[AVAudioPlayer alloc]
                                initWithContentsOfURL:[NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:[[NSBundle mainBundle] resourcePath], [[coder decodeObjectForKey:@"_musicURL"] lastPathComponent], nil]]
                                     error:nil];
        
//        NSLog(@"Generated URL: %@", musicClip.url);
//        NSLog(@"TESTMUSIC: %@", [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:basePath, [[coder decodeObjectForKey:@"_musicURL"] lastPathComponent], nil]]);
        
    }
    
    [announcementClip prepareToPlay];
    [musicClip prepareToPlay];
    
//    [announcementClip play];
//    [musicClip play];
    
    self.musicURL =         [[coder decodeObjectForKey:@"_musicURL"] retain];
    self.title =         [[coder decodeObjectForKey:@"_title"] retain];
    
//    self.announcementURL =  [coder decodeObjectForKey:@"_announcementURL"];
    self.overlap =          [coder decodeDoubleForKey:@"_overlap"];
    self.musicStartTime =   [coder decodeDoubleForKey:@"_musicStartTime"];
    self.musicDuration =    [coder decodeDoubleForKey:@"_duration"];
    self.shouldFade =       [coder decodeBoolForKey:@"_shouldFade"];
    self.isDJClip =         [coder decodeBoolForKey:@"_djClip"];
    self.shouldPlayAll =    [coder decodeBoolForKey:@"_playAll"];
    
//    [self play];
    [self stop];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[announcementClip url] forKey:@"_announcementURL"];
    [coder encodeObject:[musicClip url] forKey:@"_musicURL"];
    [coder encodeDouble:self.overlap forKey:@"_overlap"];
    [coder encodeDouble:self.musicStartTime forKey:@"_musicStartTime"];
    [coder encodeDouble:self.musicDuration forKey:@"_duration"];
    [coder encodeBool:self.shouldFade forKey:@"_shouldFade"];
    [coder encodeBool:self.isDJClip forKey:@"_djClip"];
    [coder encodeBool:self.shouldPlayAll forKey:@"_playAll"];
   [coder encodeObject:self.title forKey:@"_title"];
}

#pragma mark - Setter/Getters

-(void)setAnnouncementClipPath:(NSURL *)aPath {
    NSError *err = nil;
    AVAudioPlayer *temp = [[AVAudioPlayer alloc] initWithContentsOfURL:aPath error:&err];
    [announcementClip prepareToPlay];
    //TODO: profile and make sure this doesn't leak the previous AVAudioPlayer
    if(temp) announcementClip = temp;
    if(announcementClip) self.announcementDuration = announcementClip.duration;
}

-(void)setMusicClipPath:(NSURL *)mPath {
    if (musicClip) {
        [musicClip stop];
    }
    NSError *err = nil;
    AVAudioPlayer *temp = [[AVAudioPlayer alloc] initWithContentsOfURL:mPath error:&err];
    [temp prepareToPlay];
    //TODO: profile and make sure this doesn't leak the previous AVAudioPlayer
    if(temp) {
        musicClip = temp;
    }
}

-(void)setEmptyAnnounceClip {
    [announcementClip release];
    announcementClip = nil;
    [self.announcementURL release];
    self.announcementURL = nil;
    
    self.overlap = 0;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DJAudioAnnounceRemoved" object:self];
}

-(void)setEmptyMusicClip {
    [musicClip release];
    musicClip = nil;
    [self.musicURL release];
    self.musicURL = nil;
    
    self.title = @"Test";
    
    self.overlap = 0;
    self.musicDuration = 0;
    self.musicStartTime = 0;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DJAudioMusicRemoved" object:self];
}

#pragma mark - Playback:

-(void)updateClips:(id)sender {
    if(isFading && musicClip.volume > 0.0) {
        musicClip.volume -= volumeInc;
        announcementClip.volume -= volumeInc;
    }
    else if(!self.shouldPlayAll) {
        if(musicClip.currentTime >= ((self.musicStartTime + self.musicDuration) - FADEOUT_TIME))
            isFading = YES;
    } else {
        if(musicClip.currentTime >= (musicClip.duration - FADEOUT_TIME))
            isFading = YES;
    }
    if((endPoint <= fabs([startDate timeIntervalSinceNow])) || (musicClip.volume <= 0.0 || announcementClip.volume <= 0.0)) {
        [self stop];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DJAudioDidFinish" object:self];
    }
}
-(void)play {
    if(self.isPlaying) return;
    
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    volumeInc = [musicClip volume] / (FADEOUT_TIME * 100);
    //    endPoint = ((musicDuration > (overlap + announcementClip.duration))
//                 ? musicDuration : (overlap + announcementClip.duration)) +
//                ((overlap > 0) ? overlap : 0);
//
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DJAudioDidStart" object:self];
    if (!announcementClip && musicClip) {
        [self playMusic];
        return;
    } else if (!musicClip && announcementClip) {
        [self playAnnnouncement];
        return;
    } else if (self.overlap >= 0) {
        [announcementClip playAtTime:announcementClip.deviceCurrentTime + fabs(overlap)];
        if(self.musicDuration > (fabs(overlap) + announcementClip.duration)){
            endPoint = (!self.shouldPlayAll) ? self.musicDuration : musicClip.duration;
        } else endPoint = fabs(overlap) + ((!self.shouldPlayAll) ? self.announcementDuration : musicClip.duration);
        [musicClip play];
    }
    else {
        [musicClip playAtTime:musicClip.deviceCurrentTime + fabs(overlap)];
        endPoint = fabs(overlap) + ((!self.shouldPlayAll) ? self.musicDuration : musicClip.duration);

        [announcementClip play];
    }

    startDate = [[NSDate date] retain];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateClips:) userInfo:nil repeats:YES];
}

-(void)playAnnnouncement {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DJAudioDidStart" object:self];
    [announcementClip play];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateAnnouncePlay) userInfo:nil repeats:YES];
}

-(void)playMusic {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DJAudioDidStart" object:self];
    [musicClip play];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateMusicPlay) userInfo:nil repeats:YES];
}

-(void)updateMusicPlay {
    if((musicClip.currentTime >= (((self.shouldPlayAll) ? musicClip.duration : (self.musicDuration + self.musicStartTime)))) || musicClip.volume <= 0.0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DJAudioDidFinish" object:self];
        [self stop];
    }
    if(isFading)
        musicClip.volume -= volumeInc;
    else if (!self.shouldPlayAll && (musicClip.currentTime - self.musicStartTime) >= (self.musicDuration - FADEOUT_TIME))
        isFading = YES;
}

-(void)updateAnnouncePlay {
    if ((announcementClip.currentTime >= self.announcementDuration-0.11) || announcementClip.volume <= 0.0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DJAudioDidFinish" object:self];
        [self stop];
    }
    if(isFading)
        announcementClip.volume -= volumeInc;
}

-(bool)isPlaying{
    return ([musicClip isPlaying] || [announcementClip isPlaying]);
}

//The next two functions were added to allow checking the state of the individual
//avaudio objects so that we can properly display ui elements when they are first displayed
//For example: navigating to the edit view of a player that has had audio.music set up but not audio.announcement
- (bool)isMusicClipValid {
    if (musicClip)
        return YES;
    else
        return NO;
}

- (bool)isAnnouncementClipValid {
    if(announcementClip)
        return YES;
    else
        return NO;
}

-(void)stop {
    [musicClip pause];
    [announcementClip pause];
    if (timer) {
        [timer invalidate];
        timer = nil;
//        NSLog(@"Timer should stop!");
    }
    
    musicClip.currentTime = musicStartTime;
    announcementClip.currentTime = 0;
    
    musicClip.volume = 1.0;
    announcementClip.volume = 1.0;
    
    isFading = NO;
}

-(void)stopWithFade {
    volumeInc = 1.0 / ((FADEOUT_TIME - 0.5) * 100);
    isFading = YES;
}

@end
