//
//  SKCCLayer.m
//  OfficeAttacks
//
//  Created by Steve Kanter on 12/8/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

#if COCOS2D_VERSION || FORCE_COCOCS2D

#import "SKCCLayer.h"

@implementation SKCCLayer {
//#if IS_iOS
	__strong NSMutableArray *observers_;
//#endif
}

-(id) init {
	if( (self = [super init]) ) {
//#if IS_iOS
		observers_ = [NSMutableArray arrayWithCapacity:3];
//#elif IS_Mac
//		observers_ = [[NSMutableArray alloc] initWithCapacity:3];
//#endif
	}
	return self;
}

-(ccColor3B) color {
	return ccc3(255, 255, 255);
}
-(void) setColor:(ccColor3B)color {
	// don't do anything. please.
}
-(void) onExit {
	[[SKInputManager sharedInputManager] removeHandler:self];
	[self removeObserver];
	[super onExit];
}

#if IS_iOS
-(void) fadeOutUIKitWithBlock:(SKKitBlock)block {
	[UIView animateWithDuration:1.0
					 animations:^{
						 for(UIView *view in [[[CCDirector sharedDirector] view] subviews]) {
							 view.alpha = 0.0f;
						 }
					 }
					 completion:^(BOOL finished) {
						 if(finished) {
							 block();
						 }
					 }];
}
#endif
#if IS_Mac
-(void) fadeOutUIKitWithBlock:(SKKitBlock)block {
	block();
}
#endif

#pragma mark Touches
#if IS_iOS
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	for(UITouch *touch in touches) {
		[[SKInputManager sharedInputManager] inputBegan:touch withEvent:event];
	}
}
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	for(UITouch *touch in touches) {
		[[SKInputManager sharedInputManager] inputMoved:touch withEvent:event];
	}
}
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	for(UITouch *touch in touches) {
		[[SKInputManager sharedInputManager] inputEnded:touch withEvent:event];
	}
}
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	for(UITouch *touch in touches) {
		[[SKInputManager sharedInputManager] inputCancelled:touch withEvent:event];
	}
}
#endif

#pragma mark Mouse
#if IS_Mac
-(BOOL) ccMouseDown:(NSEvent *)event {
	[[SKInputManager sharedInputManager] inputBegan:nil withEvent:event];
	return YES;
}
-(BOOL) ccMouseDragged:(NSEvent *)event {
	[[SKInputManager sharedInputManager] inputMoved:nil withEvent:event];
	return YES;
}
-(BOOL) ccMouseUp:(NSEvent *)event {
	[[SKInputManager sharedInputManager] inputEnded:nil withEvent:event];
	return YES;
}
-(BOOL) ccMouseMoved:(NSEvent *)event {
	[[SKInputManager sharedInputManager] mouseMovedWithEvent:event];
	return YES;
}
-(BOOL) ccFlagsChanged:(NSEvent *)event {
	return NO;
}
-(BOOL) ccKeyUp:(NSEvent *)event {
	return NO;
}

#endif

//#if IS_iOS
-(SKCCLayer *) weak {
	SK_VAR_WEAK id weakSelf = self;
	return weakSelf;
}
//#endif

-(void) addObserverForName:(NSString *)name object:(id)object queue:(NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *notification))block {
	id observer = [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserverForName:name object:object queue:queue usingBlock:block];
	[observers_ addObject:observer];
}
-(void) removeObserver {
	for(id observer in observers_) {
		[[NSNotificationCenter defaultCenter] removeObserver:observer];
	}
	[observers_ removeAllObjects];
}

@end

#endif
