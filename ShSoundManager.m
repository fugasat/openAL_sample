//
//  ShSoundManager.m
//

#import "ShSoundManager.h"


@interface ShSoundManager ()

@property (strong, nonatomic) AVAudioPlayer *musicPlayer;
@property (strong, nonatomic) AVAudioPlayer *sePlayer;
@property (strong, nonatomic) NSMutableArray *musicPlayerArray;
@property (strong, nonatomic) NSMutableArray *musicVolumeArray;
@property (strong, nonatomic) NSMutableArray *seSoundArray;
@property (strong, nonatomic) NSMutableArray *seStatusArray;
//@property (strong, nonatomic) NSMutableArray *sePlayerArray;

@end

@implementation ShSoundManager

static ShSoundManager *sharedData_ = nil;
static ALCdevice *openALDevice;
static ALCcontext *openALContext;

+ (ShSoundManager *)sharedManager{
   @synchronized(self){
       if (!sharedData_) {
           sharedData_ = [ShSoundManager new];
       }
   }
   return sharedData_;
}

- (id)init
{
   self = [super init];
   if (self) {
       [self initializeSound];
   }
   return self;
}

- (void)initializeSound
{
   openALDevice = alcOpenDevice(NULL);
   openALContext = alcCreateContext(openALDevice, NULL);
   alcMakeContextCurrent(openALContext);
          
   //Initialization
   self.enabled = false;
   self.seEnabled = false;
   self.musicEnabled = false;
   self.currentMusicIndex = -1;
   self.musicPlayerArray = [NSMutableArray array];
   self.musicVolumeArray = [NSMutableArray array];
   NSArray *musicArray = @[@[@"bgm1", @1.0], @[@"bgm2", @0.85]];
   for (int i = 0; i < musicArray.count; i++) {
       NSArray *musicItemArray = [musicArray objectAtIndex:i];
       NSString *path = [[NSBundle mainBundle] pathForResource:[musicItemArray objectAtIndex:0] ofType:@"mp3"];
       NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
       NSError *error = nil;
       float volume = [[musicItemArray objectAtIndex:1] floatValue];
       AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
       [self.musicPlayerArray addObject:player];
       [self.musicVolumeArray addObject:[NSNumber numberWithFloat:volume]];
   }

   self.seSoundArray = [NSMutableArray array];
   self.seStatusArray = [NSMutableArray array];
   //self.sePlayerArray = [NSMutableArray array];
   NSArray *seArray = @[
   @[@"enemy_bomb",     @10, @0.4],
   @[@"battery_shot",   @01, @0.8],
   @[@"battery_appear", @01, @0.7],
   @[@"plant",          @01, @0.7],
   @[@"flare",          @01, @1.0],
   @[@"asteroid",       @01, @0.6],
   @[@"machine",        @01, @1.0],
   @[@"arm_broken",     @01, @1.0],
   @[@"plane_bomb",     @01, @1.0],
   @[@"laser",          @01, @0.1],
   @[@"rock",           @01, @1.0],
   @[@"volcano",        @01, @1.0],
   ];
   for (int i = 0; i < seArray.count; i++) {
       NSArray *seItemArray = [seArray objectAtIndex:i];
       
       // OpenAL
       [self.seSoundArray addObject:[NSNumber numberWithInt:[self entryAL:seItemArray]]];
       [self.seStatusArray addObject:[NSNumber numberWithBool:false]];

       // SystemSound
       //SystemSoundID soundID = [self entrySystemSound:seItemArray];
       //[self.seSoundArray addObject:[NSNumber numberWithInt:soundID]];

       // AVAudioPlayer
       //[self.sePlayerArray addObject:[self entryAVAudioPlayer:seItemArray]];
   }
}

- (ALuint)entryAL:(NSArray *)seItemArray
{
    ALuint sourceID;
    alGenSources(1, &sourceID);
    
    NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:[seItemArray objectAtIndex:0] ofType:@"caf"];
    NSURL *audioFileURL = [NSURL fileURLWithPath:audioFilePath];
    AudioFileID afid;
    OSStatus openAudioFileResult = AudioFileOpenURL((__bridge CFURLRef)audioFileURL, kAudioFileReadPermission, 0, &afid);
    if (0 != openAudioFileResult) {
        NSLog(@"An error occurred when attempting to open the audio file %@: %d", audioFilePath, (int)openAudioFileResult);
        return -1;
    }
    
    UInt64 audioDataByteCount = 0;
    UInt32 propertySize = sizeof(audioDataByteCount);
    OSStatus getSizeResult = AudioFileGetProperty(afid, kAudioFilePropertyAudioDataByteCount, &propertySize, &audioDataByteCount);
    if (0 != getSizeResult) {
        NSLog(@"An error occurred when attempting to determine the size of audio file %@: %d", audioFilePath, (int)getSizeResult);
    }
    
    UInt32 bytesRead = (UInt32)audioDataByteCount;
    void *audioData = malloc(bytesRead);
    OSStatus readBytesResult = AudioFileReadBytes(afid, false, 0, &bytesRead, audioData);
    if (0 != readBytesResult) {
        NSLog(@"An error occurred when attempting to read data from audio file %@: %d", audioFilePath, (int)readBytesResult);
    }
    AudioFileClose(afid);
    
    ALuint outputBuffer;
    alGenBuffers(1, &outputBuffer);
    alBufferData(outputBuffer, AL_FORMAT_STEREO16, audioData, bytesRead, 22050);
    if (audioData) {
        free(audioData);
        audioData = NULL;
    }
    
    alSourcef(sourceID, AL_GAIN, [[seItemArray objectAtIndex:2] floatValue]);
    alSourcef(sourceID, AL_PITCH, 1.0f);
    alSourcei(sourceID, AL_BUFFER, outputBuffer);
    return sourceID;
}

- (SystemSoundID)entrySystemSound:(NSArray *)seItemArray
{
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:[seItemArray objectAtIndex:0] withExtension:@"caf"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID ((CFURLRef)CFBridgingRetain(soundURL), &soundID);
    return soundID;
}

- (NSMutableArray *)entryAVAudioPlayer:(NSArray *)seItemArray
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[seItemArray objectAtIndex:0] ofType:@"caf"];
               
    NSMutableArray *playerArray = [NSMutableArray array];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    NSError *error = nil;
    int count = [[seItemArray objectAtIndex:1] intValue];
    float volume = [[seItemArray objectAtIndex:2] floatValue];
    for (int j = 0; j < count; j++) {
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        if ( error != nil )
        {
            NSLog(@"Error %@", [error localizedDescription]);
        }
        [player setVolume:volume];
        [playerArray addObject:player];
    }
    return playerArray;
}

- (void)startSE:(int)index
{
    if (self.enabled == false || self.seEnabled == false) {
        return;
    }
    
    // 短時間で連続再生するとプチノイズが出やすいので再生後にインターバルを設ける
    if (![[self.seStatusArray objectAtIndex:index] boolValue]) {
        [self.seStatusArray replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:true]];
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"index"];
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                              target:self
                                                            selector:@selector(enableSE:)
                                                            userInfo:userInfo
                                                             repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

        // OpenAL
        ALuint sourceID = [[self.seSoundArray objectAtIndex:index] intValue];
        alSourcePlay(sourceID);
    }
    
    // SystemSound
    //SystemSoundID soundId = [[self.seSoundIdArray objectAtIndex:index] intValue];
    //AudioServicesPlaySystemSound(soundId);
    
    // AVAudioPlayer
    /*
    NSArray *array = [self.sePlayerArray objectAtIndex:index];
    for (int i = 0; i < array.count; i++) {
        AVAudioPlayer *player = [array objectAtIndex:i];
        if ([player isPlaying] == false) {
            [player play];
            break;
        }
    }
     */
}

- (void)enableSE:(NSTimer *)timer
{
    int index = [[(NSDictionary*)timer.userInfo objectForKey:@"index"] intValue];
    [self.seStatusArray replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:false]];
}

- (void)startMusic:(int)index
{
    if (self.enabled == false || self.musicEnabled == false) {
        return;
    }
    self.currentMusicIndex = index;
    for (int i = 0; i < self.musicPlayerArray.count; i++) {
        AVAudioPlayer *player = [self.musicPlayerArray objectAtIndex:i];
        float volume = [[self.musicVolumeArray objectAtIndex:i] floatValue];
        if (i == self.currentMusicIndex) {
            if (self.currentMusicIndex == 0) {
                player.numberOfLoops = -1;
            }
            player.currentTime = 0;
            [player setVolume:volume];
            [player play];
        } else {
            [player setVolume:0 fadeDuration:4];
        }
    }
}

- (void)reset
{
    for (int i = 0; i < self.musicPlayerArray.count; i++) {
        AVAudioPlayer *player = [self.musicPlayerArray objectAtIndex:i];
        [player prepareToPlay];
    }
    /*
    for (int i = 0; i < self.sePlayerArray.count; i++) {
        NSArray *array = [self.sePlayerArray objectAtIndex:i];
        for (int j = 0; j < array.count; j++) {
            AVAudioPlayer *player = [array objectAtIndex:j];
            [player stop];
        }
    }
     */
}

- (void)stopMusic
{
    for (int i = 0; i < self.musicPlayerArray.count; i++) {
        AVAudioPlayer *player = [self.musicPlayerArray objectAtIndex:i];
        [player setVolume:0 fadeDuration:4];
    }
    self.currentMusicIndex = -1;
}

@end

