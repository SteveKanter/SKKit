//
//  SKCCLayer.m
//  OfficeAttacks
//
//  Created by Steve Kanter on 12/8/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

#import "SKCCLayer.h"

@implementation SKCCLayer {
//#if IS_iOS
	__strong NSMutableArray *observers_;
//#endif
}
@synthesize opacityPropogates=opacityPropogates_, originalOpacity=originalOpacity_;

-(id) init {
	if( (self = [super init]) ) {
		self.opacityPropogates = NO;
		self.originalOpacity = 255;
//#if IS_iOS
		observers_ = [NSMutableArray arrayWithCapacity:3];
//#elif IS_Mac
//		observers_ = [[NSMutableArray alloc] initWithCapacity:3];
//#endif
	}
	return self;
}
-(GLubyte) opacity {
	return 255;
}
-(void) setOpacity:(GLubyte)opacity {
	if(self.originalOpacity != -1) {
		opacity = OPACITY(REVERSEOPACITY(self.originalOpacity) * REVERSEOPACITY(opacity));
	}
	if(self.opacityPropogates) {
		for(SKCCSprite *child in self.children) {
			if([child respondsToSelector:@selector(setOpacity:)]) {
				if([child respondsToSelector:@selector(originalOpacity)] && child.originalOpacity != -1) {
					[child setOpacity:OPACITY(REVERSEOPACITY(child.originalOpacity) * REVERSEOPACITY(opacity))];
				} else {
					[child setOpacity:opacity];
				}
			}
			if(![child respondsToSelector:@selector(opacityPropogates)]) {
				for(SKCCSprite *innerChild in child.children) {
					if([innerChild respondsToSelector:@selector(setOpacity:)]) {
						if([innerChild respondsToSelector:@selector(originalOpacity)] && innerChild.originalOpacity != -1) {
							[innerChild setOpacity:OPACITY(REVERSEOPACITY(innerChild.originalOpacity) * REVERSEOPACITY(opacity))];
						} else {
							[innerChild setOpacity:opacity];
						}
					}
				}
			}
		}
	}
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


-(CGRect) relativeFrameFor:(CCNode *)whom {
	CGPoint pos = [whom boundingBox].origin;
	CCNode *obj = whom.parent;
	float overallXScale = 1.0;
	float overallYScale = 1.0;
	while(obj && ![obj isKindOfClass:[CCLayer class]]) {
		pos.x += obj.boundingBox.origin.x;
		pos.y += obj.boundingBox.origin.y;
		overallXScale *= obj.scaleX;
		overallYScale *= obj.scaleY;
		obj = obj.parent;
		if(!obj) {obj = nil;}
	}
	overallXScale *= whom.scaleX;
	overallYScale *= whom.scaleY;
	return CGRectMake(pos.x * overallXScale, pos.y * overallYScale,
					  [whom boundingBox].size.width * overallXScale, [whom boundingBox].size.height * overallYScale);
}

-(CGRect) relativeFrame {
	return [self relativeFrameFor:self];
}
-(CGRect) frame {
	CGRect finalFrame = [self relativeFrame];
	for(id child in self.children) {
		if([child respondsToSelector:@selector(relativeFrame)]) {
			finalFrame = CGRectUnion(finalFrame, [(SKCCLayer *)child relativeFrame]);
		} else if([child isKindOfClass:[CCNode class]]) {
			finalFrame = CGRectUnion(finalFrame, [self relativeFrameFor:child]);
		}
	}
	return finalFrame;
}

@end
