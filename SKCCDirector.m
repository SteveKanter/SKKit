//
//  SKCCDirector.m
//  FriendlyBet
//
//  Created by Steve Kanter on 9/5/12.
//
//

#import "SKCCDirector.h"

#ifdef COCOS2D_VERSION

@interface CCDirectorDisplayLink ()
//-(void) threadMainLoop;
-(void) calculateDeltaTime;
@end

@implementation SKCCDirector {
	__strong NSTimer *_cocos2dTimer;
	__strong UIViewController *_definedRootViewController;
	BOOL _inTrackingMode;
}

-(void) setRootViewController:(id)rootViewController {
	_definedRootViewController = rootViewController;
}
-(id) rootViewController {
	if(_definedRootViewController) return _definedRootViewController;
	
	return [[[UIApplication sharedApplication] keyWindow] rootViewController];
}

-(void) calculateDeltaTime {
	if(_inTrackingMode) {
		struct timeval now;
		
		if( gettimeofday( &now, NULL) != 0 ) {
			CCLOG(@"cocos2d: error in gettimeofday");
			_dt = 0;
			return;
		}
		
		// new delta time
		if( _nextDeltaTimeZero ) {
			_dt = 0;
			_nextDeltaTimeZero = NO;
		} else {
			_dt = (now.tv_sec - _lastUpdate.tv_sec) + (now.tv_usec - _lastUpdate.tv_usec) / 1000000.0f;
			_dt = MAX(0,_dt);
		}
		
#ifdef IS_Debug
		// If we are debugging our code, prevent big delta time
		if( _dt > 0.2f )
			_dt = 1/60.0f;
#endif
		_lastUpdate = now;
	} else {
		[super calculateDeltaTime];
	}
}
-(void) _recreateCocos2dTimer {
	[_cocos2dTimer invalidate];
	_cocos2dTimer = nil;
	_cocos2dTimer = [NSTimer scheduledTimerWithTimeInterval:1/30.f
													 target:self
												   selector:@selector(animateWhileDragging)
												   userInfo:nil
													repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:_cocos2dTimer forMode:UITrackingRunLoopMode];
}
-(id) init {
	if( (self = [super init]) ) {
		[self _recreateCocos2dTimer];
		_inTrackingMode = NO;
	}
	return self;
}
-(void) setAnimationInterval:(NSTimeInterval)animationInterval {
	[super setAnimationInterval:animationInterval];
	
	[self _recreateCocos2dTimer];
}
-(void) animateWhileDragging {
	if([[NSRunLoop currentRunLoop] currentMode] == UITrackingRunLoopMode) {
		
		if(_animationInterval == 1/60.f) {
			[self setAnimationInterval:1/30.f];
		}
		_inTrackingMode = YES;
		
		[[CCDirector sharedDirector] drawScene];
		
	} else if(_animationInterval == 1/30.f) {
		
		_inTrackingMode = NO;
		
		[self setAnimationInterval:1/60.f];
	}
}
-(void) dealloc {
	[_cocos2dTimer invalidate];
	_cocos2dTimer = nil;
#if !__has_feature(objc_arc)
	[super dealloc];
#endif
}

@end

#endif