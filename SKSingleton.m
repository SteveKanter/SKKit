//
//  SKSingleton.m
//  OfficeAttacks
//
//  Created by Steve Kanter on 12/8/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

#import "SKSingleton.h"

@implementation SKSingleton
-(id) init {
	if( (self = [super init]) ) {
		if([self automaticallyAddToSingletonManager]) {
			[[SKSingletonManager sharedSingletonManager] addSingletonToManager:self];
		}
	}
	return self;
}
-(BOOL) automaticallyAddToSingletonManager {
	return YES;	
}
-(void) dealloc {
	NSLog(@"Singleton Dealloc '%@'", NSStringFromClass([self class]));
#if !__has_feature(objc_arc)
	[super dealloc];
#endif
}

@end

//========================================================================//
//========================================================================//

@interface SKSingletonManager ()
@property(nonatomic, readwrite, strong) NSMutableSet *singletons;

@end


@implementation SKSingletonManager

SK_MAKE_SINGLETON(SKSingletonManager, sharedSingletonManager)
@synthesize singletons=_singletons;

-(id) init {
	if( (self = [super init]) ) {
		self.singletons = [NSMutableSet set];
	}
	return self;
}
-(void) addSingletonToManager:(id)singleton {
	[[self singletons] addObject:singleton];
}
-(void) endManager {
	[_singletons makeObjectsPerformSelector:@selector(__killSingleton)];
	self.singletons = nil;
	[self __killSingleton];
}
-(void) dealloc {
	NSLog(@"SingletonManagerDealloc '%@'", NSStringFromClass([self class]));
#if !__has_feature(objc_arc)
	[super dealloc];
#endif
}

@end

