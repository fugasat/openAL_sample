//
//  ShSoundManager.h
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>
#import <OpenAl/al.h>
#import <OpenAl/alc.h>
#include <AudioToolbox/AudioToolbox.h>

#define SE_ENEMY_BOMB 0
#define SE_BATTERY_SHOT 1
#define SE_BATTERY_APPEAR 2
#define SE_PLANT 3
#define SE_FLARE 4
#define SE_ASTEROID 5
#define SE_MACHINE 6
#define SE_ARM_BROIKEN 7
#define SE_PLANE_BOMB 8
#define SE_LASER 9
#define SE_ROCK 10
#define SE_VOLCANO 11

@interface ShSoundManager : NSObject<AVAudioPlayerDelegate>

+ (ShSoundManager *)sharedManager;
@property (assign, nonatomic) bool enabled;
@property (assign, nonatomic) bool seEnabled;
@property (assign, nonatomic) bool musicEnabled;
@property (assign, nonatomic) int currentMusicIndex;

- (void)initializeSound;
- (void)startSE:(int)index;
- (void)startMusic:(int)index;
- (void)stopMusic;
- (void)reset;

@end

