//
//  SKSingleton.h
//  OfficeAttacks
//
//  Created by Steve Kanter on 12/8/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef SK_MAKE_SINGLETON

#define SK_MAKE_SINGLETON(class_name, shared_method_name) \
\
__strong static id ___shared ## class_name = nil; \
\
+(id) shared_method_name { \
	static dispatch_once_t pred = 0; \
	dispatch_once(&pred, ^{ \
		___shared ## class_name = [[class_name alloc] init]; \
	}); \
	return ___shared ## class_name; \
}\
-(void) __killSingleton {\
	if([self respondsToSelector:@selector(__beforeKillSingleton)]) {\
		[self performSelector:@selector(__beforeKillSingleton)];\
	}\
	___shared ## class_name = nil;\
}
#endif

/** SKSingleton is an abstract base class for singleton classes.
 
 It's designed to be subclassed for things such as "grid managers" and other model-related tasks.
 
 It includes the macro SK_MAKE_SINGLETON(className, classMethodName) to create the singleton as well as the ability to release it at the end of execution.
 
 */
 
@interface SKSingleton : NSObject

/** Override point to have the singleton NOT automatically added to the manager upon initialization.
 @returns BOOL whether or not to add to manager.
 */
-(BOOL) automaticallyAddToSingletonManager;
@end

/** SKSingletonManager is itself an instance of SKSingleton.  It's designed to automatically maintain a list of pointers to currently used singletons, and is designed to be the single point for destroying singletons.
 */
@interface SKSingletonManager : NSObject
/** @returns SKSingletonManager shared singleton manager instance */
+(SKSingletonManager *) sharedSingletonManager;
/** Add a singleton to the shared manager to get removed at the end of execution
 @param singleton the singleton
 */
-(void) addSingletonToManager:(id)singleton;
/** End the manager and all it's singletons.  Call in the app delegate's dealloc method. */
-(void) endManager;
@end

