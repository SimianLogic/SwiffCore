//
//  SwiftSoundPlayer.m
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-27.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftSoundPlayer.h"

#import "SwiftSoundEvent.h"
#import "SwiftSoundDefinition.h"

#import <AudioToolbox/AudioToolbox.h>

@interface _SwiftSoundChannel : NSObject {
@private
    AudioQueueRef         m_queue;
    SwiftSoundEvent      *m_event;
    SwiftSoundDefinition *m_definition;
}

- (id) initWithEvent:(SwiftSoundEvent *)event definition:(SwiftSoundDefinition *)definition;

- (void) stop;

@property (nonatomic, retain, readonly) SwiftSoundEvent *event;
@property (nonatomic, retain, readonly) SwiftSoundDefinition *definition;

@end


static void sFillASBDForSoundDefinition(AudioStreamBasicDescription *asbd, SwiftSoundDefinition *definition)
{
    UInt32 formatID        = 0;
    UInt32 formatFlags     = 0;
    UInt32 bytesPerPacket  = 0;
    UInt32 framesPerPacket = 0;
    UInt32 bytesPerFrame   = 0;

    SwiftSoundFormat format = [definition format];
    
    if ((format == SwiftSoundFormatUncompressedNativeEndian) || (format == SwiftSoundFormatUncompressedLittleEndian)) {
        formatID    = kAudioFormatLinearPCM;
        formatFlags = kAudioFormatFlagsCanonical;

#if TARGET_RT_BIG_ENDIAN
        if ([definition format] == SwiftSoundFormatUncompressedLittleEndian) {
            formatFlags &= ~kAudioFormatFlagIsBigEndian;
        }
#endif
        bytesPerPacket  = 0; //!i: fill out
        bytesPerFrame   = 0; //!i: fill out
        framesPerPacket = 0; //!i: fill out

    } else if (format == SwiftSoundFormatMP3) {
        formatID = kAudioFormatMPEGLayer3;
    }

    asbd->mSampleRate       = [definition sampleRate];
    asbd->mFormatID         = formatID;
    asbd->mFormatFlags      = formatFlags;
    asbd->mBytesPerPacket   = bytesPerPacket;
    asbd->mFramesPerPacket  = framesPerPacket;
    asbd->mBytesPerFrame    = bytesPerFrame;
    asbd->mChannelsPerFrame = [definition isStereo] ? 2 : 1;
    asbd->mBitsPerChannel   = [definition bitsPerChannel];
    asbd->mReserved         = 0;
}


@implementation _SwiftSoundChannel

static void sAudioQueueCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    
}


- (id) initWithEvent:(SwiftSoundEvent *)event definition:(SwiftSoundDefinition *)definition
{
    if ((self = [super init])) {
        OSStatus err = noErr;
        
        AudioStreamBasicDescription inFormat;
        sFillASBDForSoundDefinition(&inFormat, definition);
        
        err = AudioQueueNewOutput(&inFormat, sAudioQueueCallback, self, CFRunLoopGetMain(), kCFRunLoopCommonModes, 0, &m_queue);

        if (err != noErr) {
            [self release];
            return nil;
        }

        m_event = [event retain];
        m_definition = [definition retain];
    }
    
    return self;
}


- (void) dealloc
{
    if (m_queue) {
        AudioQueueDispose(m_queue, true);
        m_queue = NULL;
    }

    [m_event      release];  m_event      = nil;
    [m_definition release];  m_definition = nil;

    [super dealloc];
}


- (void) stop
{
    AudioQueuePause(m_queue);
}


@synthesize event      = m_event,
            definition = m_definition;


@end



@implementation SwiftSoundPlayer

+ (SwiftSoundPlayer *) sharedInstance
{
    static id sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}


#pragma mark -
#pragma mark Private Methods

- (void) _startEventSound:(SwiftSoundEvent *)event
{
    _SwiftSoundChannel *channel = [[_SwiftSoundChannel alloc] initWithEvent:event definition:[event definition]];

    NSNumber       *libraryID = [[NSNumber alloc] initWithUnsignedShort:[event libraryID]];
    NSMutableArray *channels  = [m_libraryIDTChannelArrayMap objectForKey:libraryID];

    if (!channels) {
        if (!m_libraryIDTChannelArrayMap) {
            m_libraryIDTChannelArrayMap = [[NSMutableDictionary alloc] init];
        }
    
        channels = [[NSMutableArray alloc] init];
        [m_libraryIDTChannelArrayMap setObject:channels forKey:libraryID];
        [channels release];
    }
    
    if (channel) {
        [channels addObject:channel];
    }

    [channel release];
    [libraryID release];
}


- (void) _stopEventSound:(SwiftSoundEvent *)event
{
    NSNumber       *libraryID = [[NSNumber alloc] initWithUnsignedShort:[event libraryID]];
    NSMutableArray *channels  = [m_libraryIDTChannelArrayMap objectForKey:libraryID];

    [channels makeObjectsPerformSelector:@selector(stop)];
    [m_libraryIDTChannelArrayMap removeObjectForKey:libraryID]; 

    [libraryID release];
    
    if ([m_libraryIDTChannelArrayMap count] == 0) {
        [m_libraryIDTChannelArrayMap release];
        m_libraryIDTChannelArrayMap = nil;
    }
}


- (void) _stopAllEventSounds
{
    for (NSArray *channels in [m_libraryIDTChannelArrayMap allValues]) {
        [channels makeObjectsPerformSelector:@selector(stop)];
    }
    
    [m_libraryIDTChannelArrayMap release];
    m_libraryIDTChannelArrayMap = nil;
}


- (void) _processEvent:(SwiftSoundEvent *)event
{
    NSNumber       *libraryID = [[NSNumber alloc] initWithUnsignedShort:[event libraryID]];
    NSMutableArray *channels  = [m_libraryIDTChannelArrayMap objectForKey:libraryID];

    if ([event shouldStop]) {
        [self _stopEventSound:event];
    } else if (![channels count] || [event allowsMultiple]) {
        [self _startEventSound:event];
    }
    
    [libraryID release];
}


- (void) _stopStreamSound
{
    [m_currentStreamChannel stop];
    [m_currentStreamChannel release];
    m_currentStreamChannel = nil;
}


- (void) _startStreamSound:(SwiftSoundDefinition *)definition
{
    if ([m_currentStreamChannel definition] != definition) {
        [self _stopStreamSound];
        m_currentStreamChannel = [[_SwiftSoundChannel alloc] initWithEvent:nil definition:definition];
    }
}


#pragma mark -
#pragma mark Public Methods

- (void) processMovie:(SwiftMovie *)movie frame:(SwiftFrame *)frame
{
    for (SwiftSoundEvent *event in [frame soundEvents]) {
        [self _processEvent:event];
    }
    
    SwiftSoundDefinition *streamSound = [frame streamSound];
    if (streamSound) {
        [self _startStreamSound:streamSound];
    }
}


- (void) stopAllSounds
{
    [self _stopStreamSound];
    [self _stopAllEventSounds];
}


#pragma mark -
#pragma mark Accessors

- (BOOL) isPlaying
{
    return (m_libraryIDTChannelArrayMap != nil) || [self isStreaming];
}

- (BOOL) isStreaming
{
    return (m_currentStreamChannel != nil);
}   

@end
