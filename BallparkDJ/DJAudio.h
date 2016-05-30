#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define FADEOUT_TIME 2.0

@interface DJAudio : NSObject <NSCoding> {
//    AVAudioPlayer *announcementClip;
//    AVAudioPlayer *musicClip;
    
    bool isFading;
    double volumeInc;
    NSTimer *timer;
    NSTimer *musicTimer;
    NSTimer *announcementTimer;
    double endPoint;
    
    
    NSDate *startDate;
}
@property (strong,nonatomic) AVAudioPlayer *announcementClip;
@property (strong,nonatomic) AVAudioPlayer *musicClip;
@property (strong,nonatomic) NSURL *announcementURL;
@property (strong,nonatomic) NSURL *musicURL;
@property (strong, nonatomic) NSString    *title;
@property (assign, nonatomic) CGFloat announcementVolume;
@property (assign, nonatomic) CGFloat musicVolume;
@property (assign, nonatomic) int currentVolumeMode;
@property (assign,readonly,nonatomic) double songDuration;
@property (strong,nonatomic) NSURL *voiceProviderURL;
/*
 * Negative value = announcement first
 * Positive value = music first
 */
@property (assign,nonatomic) double overlap;
@property (assign,nonatomic) double musicStartTime;
@property (assign,nonatomic) double musicDuration;
@property (assign,nonatomic) double announcementDuration;
@property (assign,nonatomic) BOOL shouldFade;
@property (assign,nonatomic) BOOL isDJClip;
@property (assign, nonatomic) BOOL shouldPlayAll;

@property (strong,nonatomic) NSString *DJAudioFileName;


/*
 * NSCoding methods
 */
-(id)init;
-(id)initFromAnnouncePath:(NSURL *)aPath andMusicPath:(NSURL *)mPath;
-(bool)isPlaying;
-(id)initWithCoder:(NSCoder *)coder;
-(void)encodeWithCoder:(NSCoder *)coder;
/*
 * Instance methods
 */
-(void)setAnnouncementClipPath:(NSURL *)aPath;
-(void)setMusicClipPath:(NSURL *)mPath;
-(void)setEmptyAnnounceClip;
-(void)setEmptyMusicClip;
-(void)play;
-(bool)isMusicClipValid;
-(bool)isAnnouncementClipValid;
-(void)playAnnnouncement;
-(void)playMusic;
-(void)stop;
-(void)stopWithFade;

@end
