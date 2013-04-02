//
//  SKCCSprite.h
//  OfficeAttacks
//
//  Created by Steve Kanter on 12/7/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

/// Posted when a nodes' animations should be sped up.  If the object is nil, any animation implementing SKCCSpriteAnimationOptionsRespondToSpeedNotifications will respond, otherwise the object should be the node.  The speed is defined as the "animationSpeed" key in the userInfo dictionary.
extern NSString *const SKCCSpriteAnimationSpeedNotification;


/** Options that can be sent to a SKCCSprite animation */
typedef enum {
	/// Whether to restore the original image after the animation completes.  Without this option the animation ends on the last frame. */
    SKCCSpriteAnimationOptionsRestoreOriginalFrame			= 1 <<  0,
	/// Whether load the "preloadAnimationControlFile" async [if a "preloadAnimationControlFile" is set on the animation]
    SKCCSpriteAnimationOptionsPreloadControlFileAsync		= 1 <<  1,
	/// Used internally. only use if you know what you're doing.
    SKCCSpriteAnimationOptionsSkipPreload					= 1 <<  2,
	/// Whether to repeat animations - good when you want to do tests of all animations.
    SKCCSpriteAnimationOptionsDontRepeat					= 1 <<  3,
	/** Whether this animation abides by speed notifications.
	 @see SKCCSpriteAnimationSpeedNotification */
    SKCCSpriteAnimationOptionsRespondToSpeedNotifications	= 1 <<  4,
	/// If this animation has a completion block and a "nextAnimation", it won't call it's completion block, but set it on the next animation.
    SKCCSpriteAnimationOptionsPassCompletedBlockOn			= 1 <<  5,
//    SKSpriteAnimationOptionsRandomStartingFrame				= 1 <<  100, /** Whether to use a random starting frame.  Defaults to the first frame without this option. */ //NOT currently implemented.
} SKCCSpriteAnimationOptions;

/** This is the base sprite class to be used when doing anything other than simply showing a graphic.
 
 SKCCSprite handles things such as touches/clicks as well as running animations from plists.
 */

@interface SKCCSprite : CCSprite <SKKitInput>

/** Initializers */

/** Get an instance of an SKCCSprite that automatically sets it's rect to the first frame of the sprite, if it's a spritesheet.
 @param filename the filename of the file */
+(id) spriteWithFirstFrameOfSpritesheetFromFile:(NSString *)filename;

/** Get an instance of an SKCCSprite that will automatically load in the specified control file, which uses TexturePacker's plists and graphics for displaying frames/animations.
 @param filename the filename of the file */
+(id) spriteFromTexturePackerControlFile:(NSString *)filename;

//#if IS_iOS
/** Add an observer to [NSNotificationCenter defaultCenter].  The reason we do this is so that when it returns its observer object, we hold onto that object in an iVar so when we call removeObserver on ourselves, it removes all these blocks as well.
 @param name name of the notification
 @param object to listen on, or nil for any object.
 @param queue the NSOperationQueue to listen on.  Usually either nil or [NSOperationQueue currentQueue]
 @param block the block to call with the notification */
-(void) addObserverForName:(NSString *)name object:(id)object queue:(NSOperationQueue *)queue usingBlock:(SKNotificationCenterBlock)block;

/** Remove the receiver as an observer from [NSNotificationCenter defaultCenter] and remove any blocks added from self addObserverForName:object:queue:usingBlock: */
-(void) removeObserver;
/** Get a __weak version of self.  Usefull for addObserverForName:object:queue:usingBlock:
 @returns __weak version of self. */
-(SKCCSprite *) weak;
//#endif

/** @name Display */

/** The config from the plist associated with the sprite.  It's simply public for testing the plist loading - you should never rely on this for information. */
@property(nonatomic, readonly) NSDictionary *config;

/** The texture filename of the sprite - this is the final file used for the sprite */
@property(nonatomic, readwrite, strong) NSString *textureFilename;

@property(nonatomic, readwrite, strong) NSMutableDictionary *runningAnimations;
@property(nonatomic, readwrite, strong) NSMutableArray *runningAnimationsBasedOnSpeed;

/** @name Input */

/** Take the touch, or event [Mac] and determine whether it is inside the contents of the node.
 @param touch the touch or event object*/
-(BOOL) inputIsInBoundingBox:(id)touch;
/** Take the touch, or event [Mac] and get it's position in terms of the "world" using the openGL coord system [0,0 at BL].
 @param touch the touch or event object */
-(CGPoint) inputPositionInOpenGLTerms:(id)touch;
/** Take the touch, or event [Mac] and get it's position in terms of the BL corner of the node.
 @param touch the touch or event object */
-(CGPoint) inputPositionInNode:(id)touch;

/** Adds this node to the shared instance of SKInputManager.  If it already exists in the input manager, it will simply change the priority.
 @param priority priority to add this node to the manager at.  -1 = highest possible priority.
 */
-(void) addToInputManagerWithPriority:(int)priority;
/** Set a block to be called when a valid input begins on the object.
 @param block block to be called.
 */
-(void) setInputBeganHandler:(SKInputHandlerBlock)block;
/** Set a block to be called when a valid input moves on the object.
 @param block block to be called.
 */
-(void) setInputMovedHandler:(SKInputHandlerBlock)block;
/** Set a block to be called when a valid input ends on the object.
 @param block block to be called.
 */
-(void) setInputEndedHandler:(SKInputHandlerBlock)block;
/** Set a block to be called when a valid input cancelles on the object.
 @param block block to be called.
 */
-(void) setInputCancelledHandler:(SKInputHandlerBlock)block;

/** Set a block to be called when the mouse moves.
 @param block block to be called.
 @warning *Warning:* this is _*Mac Only*_.  Has no effect on iOS.
 */
-(void) setMouseMovedHandler:(SKInputHandlerBlock)block;

/** Called when input is started.
 @param position position of the input, in world space.
 */
-(void) inputBeganWithLocation:(CGPoint)position;
/** Called when input moves.
 @param position position of the input, in world space.
 */
-(void) inputMovedWithLocation:(CGPoint)position;
/** Called when input ends.
 @param position position of the input, in world space.
 */
-(void) inputEndedWithLocation:(CGPoint)position;
/** Called when input is cancelled.
 @param position position of the input, in world space.
 */
-(void) inputCancelledWithLocation:(CGPoint)position;

/** @name Animations */

/** Run an animation
 @param name the name of the animation.  This is defined in the plist of the spritesheet automatically generated from the extendscript photoshop script. */
-(void) runAnimation:(NSString *)name;
/** Run an animation with completion callback
 @param name the name of the animation.  This is defined in the plist of the spritesheet automatically generated from the extendscript photoshop script.
 @param block block to call upon completion of the animation */
-(void) runAnimation:(NSString *)name completionBlock:(SKKitBlock)block;
/** Run an animation with completion callback and options
 @param name the name of the animation.  This is defined in the plist of the spritesheet automatically generated from the extendscript photoshop script.
 @param block block to call upon completion of the animation
 @param options an OR bitwise integer of options. *See _SKCCSpriteAnimationOptions_* */
-(void) runAnimation:(NSString *)name completionBlock:(SKKitBlock)block options:(SKCCSpriteAnimationOptions)options;
/** Run an animation with completion callback and options and playback speed
 @param name the name of the animation.  This is defined in the plist of the spritesheet automatically generated from the extendscript photoshop script.
 @param block block to call upon completion of the animation
 @param options an OR bitwise integer of options. *See _SKCCSpriteAnimationOptions_*
 @param speed the speed to start the animation at.  __Requires SKCCSpriteAnimationOptionsRespondToSpeedNotifications to be set.__ *See _SKCCSpriteAnimationOptions_* to respond to speed notifications. */
-(void) runAnimation:(NSString *)name completionBlock:(SKKitBlock)block options:(SKCCSpriteAnimationOptions)options playbackSpeed:(float)speed;

/** Run any random animation from the plist */
-(NSString *) runRandomAnimation;
/** Run any random animation from the plist with completion callback
 @param block block to call upon completion of the animation */
-(NSString *) runRandomAnimationWithCompletionBlock:(SKKitBlock)block;
/** Run any random animation from the plist with completion callback and options
 @param block block to call upon completion of the animation
 @param options an OR bitwise integer of options. *See _SKCCSpriteAnimationOptions_* */
-(NSString *) runRandomAnimationWithCompletionBlock:(SKKitBlock)block options:(SKCCSpriteAnimationOptions)options;

/** Stop the animation currently running on this node.
 @param name the name of the animation.  Same name used to run the animation. */
-(void) stopAnimationByName:(NSString *)name;
/** Stop all animations currently running on this node. */
-(void) stopAllAnimations;

/** Get all of a sprites' animations.
 @returns array of all sprites' animation names */
-(NSArray *) allAnimationNames;

/** Whether or not a sprite has an animation defined
 @param name the animations' name
 @returns if the animation is defined */
-(BOOL) containsAnimation:(NSString *)name;

-(NSString *) animationNameForKey:(int)animationKey fromGroupWithKey:(int)animationGroupKey;

-(NSArray *) allChildrenInNodeTreeIncludingSelf:(BOOL)includeSelf;

@end
