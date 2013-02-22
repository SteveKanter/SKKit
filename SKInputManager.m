//
//  SKInputManager.m
//  OfficeAttacks
//
//  Created by Steve Kanter on 12/8/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

#import "SKInputManager.h"

@interface SKInputManager () {
	NSMutableArray *handlers;
	NSMutableArray *sortedHandlers;
	NSMutableDictionary *claimedInput;
}
/** Objects that are registered as handlers of touches and clicks.  Each object of the array is an instance of SKInputManagerHandler. **/
@property(nonatomic, readwrite, strong) NSMutableArray *handlers;
/** Sorted array of handlers - recreated each time the handlers array is modified. **/
@property(nonatomic, readwrite, strong) NSMutableArray *sortedHandlers;
/** Key is the hash of the touch or event with the object being the handler object. **/
@property(nonatomic, readwrite, strong) NSMutableDictionary *claimedInput;
@end

@implementation SKInputManager
SK_MAKE_SINGLETON(SKInputManager, sharedInputManager)

@synthesize handlers, sortedHandlers, claimedInput, disableReSortingOfHandlers;

-(id) init {
	if( (self = [super init]) ) {
		self.handlers = [NSMutableArray arrayWithCapacity:10];
		self.sortedHandlers = [NSMutableArray arrayWithCapacity:10];
		self.claimedInput = [NSMutableDictionary dictionaryWithCapacity:10];
	}
	return self;
}
-(void) dealloc {
	[[self handlers] makeObjectsPerformSelector:@selector(resetHandler)];
	[[self sortedHandlers] makeObjectsPerformSelector:@selector(resetHandler)];
#if !__has_feature(objc_arc)
	[super dealloc];
#endif
}
-(void) setDisableReSortingOfHandlers:(BOOL)resort {
	disableReSortingOfHandlers = resort;
	[self recreateSortedHandlers];
}
-(void) recreateSortedHandlers {
	if(disableReSortingOfHandlers) return;
	[self setSortedHandlers:[[self handlers] mutableCopy]];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:NO];
	[[self sortedHandlers] sortUsingDescriptors:@[sortDescriptor]];
}
-(void) removeHandler:(id)node {
	SKInputManagerHandler *handler = [self handlerObjectForNode:node];
	[handler resetHandler];
	[[self handlers] removeObject:handler];
	[self recreateSortedHandlers];
}
-(void) removeAllHandlers {
	[[self handlers] makeObjectsPerformSelector:@selector(resetHandler)];
	[[self handlers] removeAllObjects];
	[self recreateSortedHandlers];
}
-(SKInputManagerHandler *) addHandler:(id<SKKitInput>)nodeObject withPriority:(int)priority {
	if(priority == -1) {
		int highestPriority = 0;
		for(SKInputManagerHandler *handler in [self handlers]) {
			highestPriority = MAX(handler.priority, highestPriority);
		}
		priority = highestPriority + 1;
	}
	if([self handlerIsRegistered:nodeObject]) {
		SKInputManagerHandler *handler = [self handlerObjectForNode:nodeObject];
		handler.priority = priority;
		[self recreateSortedHandlers];
		return handler;
	}
	SKInputManagerHandler *handler = [[SKInputManagerHandler alloc] init];
	handler.nodeObject = nodeObject;
	handler.priority = priority;
	[[self handlers] addObject:handler];
	[self recreateSortedHandlers];
	return handler;
}
-(SKInputManagerHandler *) handlerObjectForNode:(id)node {
	id finalHandlerObject = nil;
	for(SKInputManagerHandler *o in [self handlers]) {
		if(o.nodeObject == node) {
			finalHandlerObject = o;
		}
	}
	return finalHandlerObject;
}
-(int) getHashFromInput:(id)input andEvent:(id)event {
#if IS_iOS
	return [input hash];
#elif IS_Mac
	return 1;//[event hash]; //using NSEvent's hash doesn't seem to be working.  Simple enough - there's only ever going to be 1 click anway.
#endif
}
-(id) getInputObjectFromInput:(id)input andEvent:(id)event {
#if IS_iOS
	return input;
#elif IS_Mac
	return event;
#endif	
}
-(void) inputBegan:(id)input withEvent:(id)event {
	
	if(!_inputEnabled) return;
	
	int hash = [self getHashFromInput:input andEvent:event];
	if(![self claimedInput][@(hash)]) {
		for(SKInputManagerHandler *handler in [self sortedHandlers]) {
			id object = [handler nodeObject];
			BOOL theyWantTheTouch = NO;
#if IS_iOS
			if([object respondsToSelector:@selector(skTouchBegan:)]) {
				theyWantTheTouch = [object skTouchBegan:input];
			}
#elif IS_Mac
			if([object respondsToSelector:@selector(skClickBegan:)]) {
				theyWantTheTouch = [object skClickBegan:event];
			}
#endif
			if(theyWantTheTouch) {
				[self claimedInput][@(hash)] = handler;
				if(handler.inputBeganBlock) {
					handler.inputBeganBlock(object, [self getInputObjectFromInput:input andEvent:event]);
				}
				break;
			}
		}
	}
}
-(void) inputMoved:(id)input withEvent:(id)event {
	
	if(!_inputEnabled) return;
	
	int hash = [self getHashFromInput:input andEvent:event];
	SKInputManagerHandler *handler = [self claimedInput][@(hash)];
	if(handler) {
		id object = [handler nodeObject];
#if IS_iOS
		if([object respondsToSelector:@selector(skTouchMoved:)]) {
			[object skTouchMoved:input];
		}
#elif IS_Mac
		if([object respondsToSelector:@selector(skClickMoved:)]) {
			[object skClickMoved:event];
		}
#endif
		if(handler.inputMovedBlock) {
			handler.inputMovedBlock(object, [self getInputObjectFromInput:input andEvent:event]);
		}
	}
}
-(void) inputEnded:(id)input withEvent:(id)event {
	
	if(!_inputEnabled) return;
	
	int hash = [self getHashFromInput:input andEvent:event];
	SKInputManagerHandler *handler = [self claimedInput][@(hash)];
	if(handler) {
		id object = [handler nodeObject];
#if IS_iOS
		if([object respondsToSelector:@selector(skTouchEnded:)]) {
			[object skTouchEnded:input];
		}
#elif IS_Mac
		if([object respondsToSelector:@selector(skClickEnded:)]) {
			[object skClickEnded:event];
		}
#endif
		if(handler.inputEndedBlock) {
			handler.inputEndedBlock(object, [self getInputObjectFromInput:input andEvent:event]);
		}
		[[self claimedInput] removeObjectForKey:@(hash)];
	}
}
-(void) inputCancelled:(id)input withEvent:(id)event {
	
	if(!_inputEnabled) return;
	
	int hash = [self getHashFromInput:input andEvent:event];
	SKInputManagerHandler *handler = [self claimedInput][@(hash)];
	if(handler) {
		id object = [handler nodeObject];
#if IS_iOS
		if([object respondsToSelector:@selector(skTouchCancelled:)]) {
			[object skTouchCancelled:input];
		}
#elif IS_Mac
		if([object respondsToSelector:@selector(skClickCancelled:)]) {
			[object skClickCancelled:event];
		}
#endif
		if(handler.inputCancelledBlock) {
			handler.inputCancelledBlock(object, [self getInputObjectFromInput:input andEvent:event]);
		}
		[[self claimedInput] removeObjectForKey:@(hash)];
	}
}
-(void) mouseMovedWithEvent:(id)event {
	
	if(!_inputEnabled) return;
	
#if IS_Mac
	for(SKInputManagerHandler *handler in self.handlers) {
		if(handler.mouseMovedBlock) {
			id object = [handler nodeObject];
			handler.mouseMovedBlock(object, [self getInputObjectFromInput:nil andEvent:event]);
		}
	}
#endif
}
-(BOOL) handlerIsRegistered:(id)theHandler {
	return ([self handlerObjectForNode:theHandler] != nil);
}
@end

@implementation SKInputManagerHandler
@synthesize nodeObject;
@synthesize priority;
@synthesize inputBeganBlock;
@synthesize inputMovedBlock;
@synthesize inputEndedBlock;
@synthesize inputCancelledBlock;
@synthesize mouseMovedBlock;


-(void) resetHandler {
	self.nodeObject = nil;
	
	self.inputBeganBlock = nil;
	self.inputMovedBlock = nil;
	self.inputEndedBlock = nil;
	self.inputCancelledBlock = nil;
	self.mouseMovedBlock = nil;
}
-(void) dealloc {
	[self resetHandler];
#if !__has_feature(objc_arc)
	[super dealloc];
#endif
}
@end