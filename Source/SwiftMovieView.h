/*
    SwiftMovieView.h
    Copyright (c) 2011, musictheory.net, LLC.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.
        * Neither the name of musictheory.net, LLC nor the names of its contributors
          may be used to endorse or promote products derived from this software
          without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL MUSICTHEORY.NET, LLC BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

@class SwiftLayer, SwiftMovie, SwiftScene, SwiftFrame, SwiftPlayhead;

@protocol SwiftMovieViewDelegate;

@interface SwiftMovieView : UIView {
@private
    id<SwiftMovieViewDelegate> m_delegate;

    SwiftLayer    *m_layer;
    SwiftMovie    *m_movie;
    SwiftPlayhead *m_playhead;

    CADisplayLink *m_displayLink;
    CFTimeInterval m_displayLinkPlayStart;
    long           m_displayLinkPlayIndex;

    CFTimeInterval m_framesPerSecond;

    BOOL m_playing;
    BOOL m_showsBackgroundColor;
    BOOL m_usesMultipleLayers;
    BOOL m_interpolatesFrames;
    BOOL m_delegate_movieView_willDisplayScene_frame;
    BOOL m_delegate_movieView_didDisplayScene_frame;
}

@property (nonatomic, retain) SwiftMovie *movie;
@property (nonatomic, assign) id<SwiftMovieViewDelegate> delegate;

@property (nonatomic, retain, readonly) SwiftPlayhead *playhead;

@property (nonatomic, assign, getter=isPlaying) BOOL playing;
@property (nonatomic, assign) BOOL showsBackgroundColor;
@property (nonatomic, assign) BOOL usesMultipleLayers;  // Experimental, defaults to NO
@property (nonatomic, assign) BOOL interpolatesFrames;

@end


@protocol SwiftMovieViewDelegate <NSObject>
@optional
- (void) movieView:(SwiftMovieView *)movieView willDisplayScene:(SwiftScene *)scene frame:(SwiftFrame *)frame;
- (void) movieView:(SwiftMovieView *)movieView didDisplayScene:(SwiftScene *)scene  frame:(SwiftFrame *)frame;
@end

#endif