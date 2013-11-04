//
//  SKCCSprite.m
//  OfficeAttacks
//
//  Created by Steve Kanter on 12/7/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

#if COCOS2D_VERSION || FORCE_COCOCS2D

#import "SKCCSprite.h"
#import "SKKitDefines.h"

NSString *const SKCCSpriteAnimationSpeedNotification = @"SKCCSpriteAnimationSpeedNotification";
static float SKCCSpriteTouchScaleFactor = 1.0f;

@class SKSpriteAnimationAsyncLoader;
@interface SKCCSprite (SKSpriteAnimationAsyncLoadAdditions)

-(void) removeAsyncLoader:(SKSpriteAnimationAsyncLoader *)loader;
-(void) removeAllAsyncLoaders;
-(void) addAsyncLoader:(SKSpriteAnimationAsyncLoader *)loader;

@end


@interface SKSpriteAnimationAsyncLoader : NSObject

@property(nonatomic, readwrite, SK_PROP_WEAK) SKCCSprite *delegate;
@property(nonatomic, readwrite, copy) NSString *animationName;
@property(nonatomic, readwrite, copy) SKKitBlock animationBlock;
@property(nonatomic, readwrite, copy) NSString *animationSpritesheetControlFile;
@property(nonatomic, readwrite, assign) SKCCSpriteAnimationOptions animationOptions;

-(void) loadTextureAsync:(NSString *)texture;
@end


@implementation SKSpriteAnimationAsyncLoader


-(void) doneLoading:(CCTexture2D *)texture {
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:_animationSpritesheetControlFile
																 texture:texture];
	[[self delegate] runAnimation:_animationName completionBlock:_animationBlock options:_animationOptions];
	[[self delegate] removeAsyncLoader:self];
}
-(void) loadTextureAsync:(NSString *)texture {
	[[CCTextureCache sharedTextureCache] addImageAsync:texture target:self selector:@selector(doneLoading:)];
}

@end


/** A private class to SKCCSprite for maintaining a list of cached config files. */
@interface SKSpriteManager : SKSingleton {
	NSMutableDictionary *configs_;
}
+(SKSpriteManager *) sharedSpriteManager;
-(NSDictionary *) getConfigByFilename:(NSString *)filename;
@end

@implementation SKSpriteManager
SK_MAKE_SINGLETON(SKSpriteManager, sharedSpriteManager)
-(id) init {
	if( (self = [super init]) ) {
		configs_ = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	return self;
}
-(NSDictionary *) getConfigByFilename:(NSString *)filename {
	NSDictionary *config = configs_[filename];
	if(!config) {
		NSString *file = filename;
		if(![filename isAbsolutePath]) {
			file = [[CCFileUtils sharedFileUtils] fullPathForFilename:filename];
		}
		config = [NSDictionary dictionaryWithContentsOfFile:file];
		if(config) {
			configs_[filename] = config;
		}
	}
	return config;
}
-(void) dealloc {
	configs_ = nil;
#if !__has_feature(objc_arc)
	[super dealloc];
#endif
}

@end


@interface SKCCSprite ()
@property(nonatomic, readwrite, strong) NSString *lastUsedAnimation;
@end

@implementation SKCCSprite {
//#if IS_iOS
	__strong NSMutableArray *observers_;
//#endif
	
	__strong NSString *_spritesheetPrefix;
	__strong NSMutableArray *_loaders;
	
	NSString *_lastUsedAnimation;
}

@synthesize inputEnabled=_inputEnabled;

-(void) setupTextureFilenameWithFilename:(NSString *)filename {
	self.textureFilename = filename;
#if CC_IS_RETINA_DISPLAY_SUPPORTED
#error fix this - it's old and doesn't support iPad retina.  should resolve that.
	if( CC_CONTENT_SCALE_FACTOR() == 2 ) {
		NSString *filenameWithoutExtension = [ccRemoveHDSuffixFromFile(filename) stringByDeletingPathExtension];
		NSString *extension = [filename pathExtension];
		NSString *retinaName = [filenameWithoutExtension stringByAppendingString:CC_RETINA_DISPLAY_FILENAME_SUFFIX];
		retinaName = [retinaName stringByAppendingPathExtension:extension];
		self.textureFilename = retinaName;
	}
#endif
}

#if IS_Mac
-(NSString *) removeSuffix:(NSString*)suffix fromPath:(NSString*)path {
	// quick return
	if( ! suffix || [suffix length] == 0 )
		return path;
	
	NSString *name = [path lastPathComponent];
	
	// check if path already has the suffix.
	if( [name rangeOfString:suffix].location != NSNotFound ) {
		
		NSString *newLastname = [name stringByReplacingOccurrencesOfString:suffix withString:@""];
		
		NSString *pathWithoutLastname = [path stringByDeletingLastPathComponent];
		return [pathWithoutLastname stringByAppendingPathComponent:newLastname];
	}
	
	// suffix was not removed
	return path;
}
#endif

-(void) setupConfigWithFilename:(NSString *)filename {
	
	// see if the file with whatever suffix is already on it exists.
	
	NSString *finalFilename = nil;
	NSString *testFilename = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];
	BOOL found = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:testFilename]) {
		finalFilename = testFilename;
		found = YES;
	}
	if(!found && [[NSFileManager defaultManager] fileExistsAtPath:RESOURCEFILE(testFilename)]) {
		finalFilename = testFilename;
		found = YES;
	}
	if(!found) {
		// strip off the suffix, and then try adding on the default suffix for the current mode.
#if IS_iOS
		testFilename = [[CCFileUtils sharedFileUtils] removeSuffixFromFile:filename];
#endif
#if IS_Mac
		testFilename = [self removeSuffix:@"-hd" fromPath:testFilename];
		testFilename = [self removeSuffix:@"-iPadHD" fromPath:testFilename];
#endif
		// turn the relative into an absolute, to see if having the suffix helps.
		testFilename = [[CCFileUtils sharedFileUtils] fullPathForFilename:testFilename];
		// remove the path extension
		testFilename = [testFilename stringByDeletingPathExtension];
		// slap on the plist extension and BAM - we got a plist filename.
		testFilename = [testFilename stringByAppendingPathExtension:@"plist"];
		if([[NSFileManager defaultManager] fileExistsAtPath:testFilename]) {
			finalFilename = testFilename;
			found = YES;
		}
	}
	if(!found) {
#if IS_iOS
		finalFilename = [[CCFileUtils sharedFileUtils] removeSuffixFromFile:filename];
#endif
#if IS_Mac
		finalFilename = [self removeSuffix:@"-hd" fromPath:filename];
		finalFilename = [self removeSuffix:@"-iPadHD" fromPath:filename];
#endif
		// remove the path extension
		finalFilename = [finalFilename stringByDeletingPathExtension];
		// slap on the plist extension and BAM - we got a plist filename.
		finalFilename = [finalFilename stringByAppendingPathExtension:@"plist"];
		found = YES;
		// default to NO extension.
	}
	_config = [[SKSpriteManager sharedSpriteManager] getConfigByFilename:finalFilename];
}
-(id) initWithTexture:(CCTexture2D *)texture rect:(CGRect)rect rotated:(BOOL)rotated {
	if( (self = [super initWithTexture:texture rect:rect rotated:rotated]) ) {
		_inputEnabled = YES;
		_textureFilename = nil;
		_config = nil;
		_lastUsedAnimation = nil;
		_spritesheetPrefix = nil;
//#if IS_iOS
		observers_ = [NSMutableArray arrayWithCapacity:3];
//#endif
		_runningAnimations = [[NSMutableDictionary alloc] initWithCapacity:2];
		_runningAnimationsBasedOnSpeed = [NSMutableArray arrayWithCapacity:2];
		
		_loaders = [NSMutableArray arrayWithCapacity:10];
	}
	return self;
}
-(void) setSpritesheetPrefix:(NSString *)prefix {
	_spritesheetPrefix = prefix;
}
+(NSString *) texturePackerAbsoluteFileFromControlFile:(NSString *)controlFile {
	if([controlFile isAbsolutePath]) {
		return controlFile;
	}
	return [[CCFileUtils sharedFileUtils] fullPathForFilename:controlFile];
}

+(id) spriteFromTexturePackerControlFile:(NSString *)filename {
	SKCCSprite *sprite = [[[self class] alloc] init];
	[sprite setupConfigWithFilename:filename];
	NSDictionary *config = [sprite config];
	if(config[@"spritesheetControlFile"]) {
		NSString *controlFile = [config[@"spritesheetControlFile"] stringByAppendingPathExtension:@"plist"];
		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:controlFile];
		[sprite setSpritesheetPrefix:config[@"spritesheetFramePrefix"]];
		[sprite setupTextureFilenameWithFilename:config[@"spritesheetControlFile"]];
	}
	return sprite;
}
+(id) spriteWithFirstFrameOfSpritesheetFromFile:(NSString *)filename {
	SKCCSprite *sprite = [[self class] spriteWithFile:filename];
	if(sprite.config) {
		CGSize size = SKCGSizeMake([[sprite config][@"spriteWidth"] intValue], [[sprite config][@"spriteHeight"] intValue]);
		sprite.textureRect = CGRectMake(0, 0, size.width, size.height);
	}
	return sprite;
}
-(id) initWithFile:(NSString *)filename {
	if( (self = [super initWithFile:filename]) ) {
		[self setupTextureFilenameWithFilename:filename];
		[self setupConfigWithFilename:filename];
	}
	return self;
}
-(id) initWithFile:(NSString *)filename rect:(CGRect)rect {
	if( (self = [super initWithFile:filename rect:rect]) ) {
		[self setupTextureFilenameWithFilename:filename];
		[self setupConfigWithFilename:filename];
	}
	return self;
}
-(void) onEnter {
	[super onEnter];
	[[self weak] addObserverForName:SKCCSpriteAnimationSpeedNotification
							 object:nil
							  queue:nil
						 usingBlock:^(NSNotification *notification) {
							 float speed = [[notification userInfo][@"animationSpeed"] floatValue];
							 for(CCAction *action in _runningAnimationsBasedOnSpeed) {
								 if((notification.object == nil || notification.object == action) && [action isKindOfClass:[CCSpeed class]]) {
									 ((CCSpeed *)action).speed = speed;
								 }
							 }
						 }];
}
-(void) onExit {
	self.runningAnimations = nil;
	_runningAnimationsBasedOnSpeed = nil;
	[[SKInputManager sharedInputManager] removeHandler:self];
	[self removeAllAsyncLoaders];
	[self removeObserver];
	[super onExit];
}

-(CGPoint) inputPositionInOpenGLTerms:(id)touch {
#if IS_iOS
	CGPoint position = [touch locationInView:[[CCDirector sharedDirector] view]];
	position = [[CCDirector sharedDirector] convertToGL:position];
	position.x *= 1.f / SKCCSpriteTouchScaleFactor;
	position.y *= 1.f / SKCCSpriteTouchScaleFactor;
	return position;
#elif IS_Mac
	return NSPointToCGPoint([touch locationInWindow]);
#endif
}
-(CGPoint) inputPositionInNode:(id)touch {
	return [self convertToNodeSpace:[self inputPositionInOpenGLTerms:touch]];
}
-(BOOL) inputIsInBoundingBox:(id)touch {
	CGPoint pos = [self inputPositionInNode:touch];
	
	CGRect box = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
	return CGRectContainsPoint(box, pos);
}

-(BOOL) anyParentsDenyingTouch {
	
	CCNode <SKKitInputDenier> *parent = (id)self;
	
	CGRect box = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
	box.origin = [self convertToWorldSpace:box.origin];
	
	while(parent) {
		if([parent conformsToProtocol:@protocol(SKKitInputDenier)]) {
			if(![parent inputValidForNode:self withWorldRect:box]) {
				return YES;
			}
		}
		
		parent = (id)parent.parent;
	}
	return NO;
}

-(BOOL) inVisibleTree {
	CCNode *parent = (id)self;
	while(parent) {
		if(!parent.visible) return NO;
		parent = parent.parent;
	}
	return YES;
}

#if IS_iOS
-(BOOL) skTouchBegan:(UITouch *)touch {
	if(!_inputEnabled || ![self inVisibleTree]) return NO;
	BOOL myTouch = [self inputIsInBoundingBox:touch];
	
	if(myTouch) {
		if([self anyParentsDenyingTouch]) {
			myTouch = NO;
		}
	}
	
	if(myTouch) {
		CGPoint pos = [self inputPositionInOpenGLTerms:touch];
		[self inputBeganWithLocation:pos];
	}
	return myTouch;
}
-(void) skTouchMoved:(UITouch *)touch {
	CGPoint pos = [self inputPositionInOpenGLTerms:touch];
	[self inputMovedWithLocation:pos];
}
-(void) skTouchEnded:(UITouch *)touch {
	CGPoint pos = [self inputPositionInOpenGLTerms:touch];
	[self inputEndedWithLocation:pos];
}
-(void) skTouchCancelled:(UITouch *)touch {
	CGPoint pos = [self inputPositionInOpenGLTerms:touch];
	[self inputCancelledWithLocation:pos];
}
#endif
#if IS_Mac
-(BOOL) skClickBegan:(NSEvent *)event {
	if(!_inputEnabled || !self.visible) return NO;
	BOOL myClick = [self inputIsInBoundingBox:event];
	if(myClick) {
		CGPoint pos = [self inputPositionInOpenGLTerms:event];
		[self inputBeganWithLocation:pos];
	}
	return myClick;

}
-(void) skClickMoved:(NSEvent *)event {
	CGPoint pos = [self inputPositionInOpenGLTerms:event];
	[self inputMovedWithLocation:pos];
}
-(void) skClickEnded:(NSEvent *)event {
	CGPoint pos = [self inputPositionInOpenGLTerms:event];
	[self inputEndedWithLocation:pos];
}
-(void) skClickCancelled:(NSEvent *)event {
	CGPoint pos = [self inputPositionInOpenGLTerms:event];
	[self inputCancelledWithLocation:pos];
}
#endif
-(void) inputBeganWithLocation:(CGPoint)position {
	
}
-(void) inputMovedWithLocation:(CGPoint)position {
	
}
-(void) inputEndedWithLocation:(CGPoint)position {
	
}
-(void) inputCancelledWithLocation:(CGPoint)position {
	
}
-(void) addToInputManagerWithPriority:(int)priority {
	[[SKInputManager sharedInputManager] addHandler:self withPriority:priority];
}
-(void) setInputBeganHandler:(SKInputHandlerBlock)block {
	SKInputManager *inputManager = [SKInputManager sharedInputManager];
	SKInputManagerHandler *handler = [inputManager handlerObjectForNode:self];
	[handler setInputBeganBlock:block];
}
-(void) setInputMovedHandler:(SKInputHandlerBlock)block {
	SKInputManager *inputManager = [SKInputManager sharedInputManager];
	SKInputManagerHandler *handler = [inputManager handlerObjectForNode:self];
	[handler setInputMovedBlock:block];
}
-(void) setInputEndedHandler:(SKInputHandlerBlock)block {
	SKInputManager *inputManager = [SKInputManager sharedInputManager];
	SKInputManagerHandler *handler = [inputManager handlerObjectForNode:self];
	[handler setInputEndedBlock:block];
}
-(void) setInputCancelledHandler:(SKInputHandlerBlock)block {
	SKInputManager *inputManager = [SKInputManager sharedInputManager];
	SKInputManagerHandler *handler = [inputManager handlerObjectForNode:self];
	[handler setInputCancelledBlock:block];
}
-(void) setMouseMovedHandler:(SKInputHandlerBlock)block {
	SKInputManager *inputManager = [SKInputManager sharedInputManager];
	SKInputManagerHandler *handler = [inputManager handlerObjectForNode:self];
	[handler setMouseMovedBlock:block];
}
-(void) setRightClickMouseUpHandler:(SKInputHandlerBlock)block {
	SKInputManager *inputManager = [SKInputManager sharedInputManager];
	SKInputManagerHandler *handler = [inputManager handlerObjectForNode:self];
	[handler setRightMouseUpBlock:block];
}
-(void) setInputBeganOutsideHandler:(SKInputHandlerBlock)block {
	SKInputManager *inputManager = [SKInputManager sharedInputManager];
	SKInputManagerHandler *handler = [inputManager handlerObjectForNode:self];
	[handler setInputBeganOutsideBlock:block];
}

-(int) getSpriteSheetColumn:(int)frameNumber {
	int numColumns = [(self.config)[@"numColumns"] intValue];
	return frameNumber % numColumns;
}
-(int) getSpriteSheetRow:(int)frameNumber {
	int numColumns = [(self.config)[@"numColumns"] intValue];
	return ceil(frameNumber / numColumns);
}
-(NSString *) getRunningZeros:(int)lengthOfNumbers forNumber:(int)number {
	NSMutableString *final = [NSMutableString stringWithFormat:@"%i", number];
	while([final length] < lengthOfNumbers) {
		[final insertString:@"0" atIndex:0];
	}
	return final;
}
-(NSString *) getRandomAnimationKey {
	NSArray *keys = [self allAnimationNames];
	NSString *key = keys[RANDOM_INT(0,[keys count]-1)];
	return key;
}
-(void) stopAllAnimations {
	for(id key in [self runningAnimations]) {
		CCAction *ac = [self runningAnimations][key];
		[self stopAction:ac];
	}
	[[self runningAnimations] removeAllObjects];
	[_runningAnimationsBasedOnSpeed removeAllObjects];
}
-(void) stopAnimationByName:(NSString *)name {
	CCAction *ac = [self runningAnimations][name];
	[self stopAction:ac];
	[[self runningAnimations] removeObjectForKey:name];
	if([_runningAnimationsBasedOnSpeed containsObject:ac]) {
		[_runningAnimationsBasedOnSpeed removeObject:ac];
	}
}

-(NSArray *) allAnimationNames {
	return [[self config][@"animations"] allKeys];
}

-(BOOL) containsAnimation:(NSString *)name {
	return [[self allAnimationNames] containsObject:name];
}
-(NSString *) animationNameForKey:(int)animationKey fromGroupWithKey:(int)animationGroupKey {
	// get all the groups
	NSDictionary *groups = [self config][@"animationGroups"];
	for(NSString *name in groups) {
		NSDictionary *group = groups[name];
		int groupKey = [group[@"groupKey"] intValue];
		// see if the group's key is the one we want
		if(groupKey == animationGroupKey) {
			NSDictionary *groupAnimations = group[@"animations"];
			for(NSString *animationKeyString in groupAnimations) {
				int thisAnimationKey = [animationKeyString intValue];
				// see if the group defines the name of the animation for this key
				if(thisAnimationKey == animationKey) {
					return groupAnimations[animationKeyString];
				}
			}
		}
	}
#if ANIMATION_TEST
	return nil;
#endif
	// since we got this far, the group we wanted either didn't exist, or the animation didn't exist in it. return an animation if possible
	for(NSString *name in groups) {
		NSDictionary *group = groups[name];
		NSDictionary *groupAnimations = group[@"animations"];
		for(NSString *animationKeyString in groupAnimations) {
			int thisAnimationKey = [animationKeyString intValue];
			// see if THIS group defines the name of the animation for this key
			if(thisAnimationKey == animationKey) {
				return groupAnimations[animationKeyString];
			}
		}
	}	
	return nil;
}
-(NSString *) textureFilenameFromSpritesheetControlFile:(NSString *)plist {
	NSString *path = [[self class] texturePackerAbsoluteFileFromControlFile:plist];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
	
    NSString *texturePath = nil;
    NSDictionary *metadataDict = dict[@"metadata"];
    if( metadataDict )
        // try to read  texture file name from meta data
        texturePath = metadataDict[@"textureFileName"];
	
	
    if( texturePath ) {
        // build texture path relative to plist file
        NSString *textureBase = [plist stringByDeletingLastPathComponent];
        texturePath = [textureBase stringByAppendingPathComponent:texturePath];
    }
	return texturePath;
}

-(NSString *) runRandomAnimation {
	return [self runRandomAnimationWithCompletionBlock:nil options:0];
}
-(NSString *) runRandomAnimationWithCompletionBlock:(SKKitBlock)block {
	return [self runRandomAnimationWithCompletionBlock:block options:0];
}
-(NSString *) runRandomAnimationWithCompletionBlock:(SKKitBlock)block options:(SKCCSpriteAnimationOptions)options {
	NSString *key = [self getRandomAnimationKey];
	[self runAnimation:key completionBlock:block options:options];
	return key;
}

-(void) runAnimation:(NSString *)name {
	[self runAnimation:name completionBlock:nil options:0];
}
-(void) runAnimation:(NSString *)name completionBlock:(SKKitBlock)block {
	[self runAnimation:name completionBlock:block options:0];
}
-(void) runAnimation:(NSString *)name completionBlock:(SKKitBlock)block options:(SKCCSpriteAnimationOptions)options {
	[self runAnimation:name completionBlock:block options:options playbackSpeed:1.f];
}
-(void) runAnimation:(NSString *)name completionBlock:(SKKitBlock)block options:(SKCCSpriteAnimationOptions)options playbackSpeed:(float)speed {
	
	if(!name) return;
	
	BOOL restoreFrame = options & SKCCSpriteAnimationOptionsRestoreOriginalFrame;
	
	// of the animation requires a control file loaded, and it's not, whether or not to load it in a seperate thread.
	BOOL preloadControlFileAsync = options & SKCCSpriteAnimationOptionsPreloadControlFileAsync;
	
//	BOOL randomFrame = options & SKCCSpriteAnimationOptionsRandomStartingFrame;
	self.lastUsedAnimation = name;
	NSDictionary *animationData = [self config][@"animations"][name];
	if(!animationData && block) {
		[self runAction:[CCCallBlock actionWithBlock:block]];  //this way, we call the completion block but wait until the next run of the loop.  prevents the block being called before you're ready for it.
		return;
	}
	NSString *animationName = [self.textureFilename stringByAppendingFormat:@":%@", name];

	
	CCAnimation *animation = [[CCAnimationCache sharedAnimationCache] animationByName:animationName];
	//NSLog(@"animation: %@", animationName);
	
	if(!animation && animationData[@"randomPreloadFrameRanges"]) {
		NSMutableDictionary *newAnimationData = [animationData mutableCopy];
		NSDictionary *frameKeys = animationData[@"randomPreloadFrameRanges"];
		NSString *key = [frameKeys allKeys][RANDOM_INT(0, [frameKeys count] - 1)];
		NSString *range = frameKeys[key];
		newAnimationData[@"preloadAnimationControlFile"] = key;
		newAnimationData[@"frameRange"] = range;
		animationData = [newAnimationData copy];
	}
	
	if(!animation && animationData[@"preloadAnimationControlFile"]) {
		NSString *path = [animationData[@"preloadAnimationControlFile"] stringByAppendingPathExtension:@"plist"];
		NSString *fullPath = [[self class] texturePackerAbsoluteFileFromControlFile:path];
		NSString *currentPath = fullPath;
#if IS_iOS
		currentPath = [[CCFileUtils sharedFileUtils] removeSuffixFromFile:fullPath];
#endif
		NSString *key = [self textureFilenameFromSpritesheetControlFile:currentPath];
		if(![[CCTextureCache sharedTextureCache] textureForKey:key] &&
		   !(options & SKCCSpriteAnimationOptionsSkipPreload)) {
			if(preloadControlFileAsync) {
				SKSpriteAnimationAsyncLoader *loader = [[SKSpriteAnimationAsyncLoader alloc] init];
				loader.delegate = self;
				loader.animationName = name;
				loader.animationBlock = block;
				options = options | SKCCSpriteAnimationOptionsSkipPreload;
				loader.animationOptions = options;
				loader.animationSpritesheetControlFile = path;
				
				[loader loadTextureAsync:key];
				
				return; // we're going to load again later, so no sense continuing. things will shit.
			} else {
				[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:path];
			}
		}
	}
	
	if(!animation) {
		
		NSMutableArray *frameIndexes = animationData[@"frames"];
		
		if(animationData[@"frameRange"]) {
			NSArray *array = [animationData[@"frameRange"] componentsSeparatedByString:@"-"];
			if([array count] == 2) {
				int startIndex = [array[0] intValue];
				int endIndex = [array[1] intValue];
				frameIndexes = [NSMutableArray arrayWithCapacity:endIndex - startIndex + 1];
				for(int i = startIndex; i <= endIndex; i++) {
					[frameIndexes addObject:@(i)];
				}
			} else if([array count] == 1) {
				frameIndexes = [NSMutableArray arrayWithCapacity:1];
				[frameIndexes addObject:@([array[0] intValue])];
			}
		}
		
		NSMutableArray *frames = [NSMutableArray arrayWithCapacity:[frameIndexes count]];
		
		if(!_spritesheetPrefix) { // not from texturepacker
			CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithTexture:self.texture];
			CCTexture2D *animationTexture = spriteSheet.textureAtlas.texture;
			CGRect baseRect = SKCGRectMake(0,0, [(self.config)[@"spriteWidth"] intValue], [(self.config)[@"spriteHeight"] intValue]);
			for(NSNumber *frameNumber in frameIndexes) {
				CGRect frameRect = baseRect;
				frameRect.origin.x = frameRect.size.width * [self getSpriteSheetColumn:([frameNumber intValue] - 1)];
				frameRect.origin.y = frameRect.size.height * [self getSpriteSheetRow:([frameNumber intValue] - 1)];
				[frames addObject:[CCSpriteFrame frameWithTexture:animationTexture rect:frameRect]];
			}
		} else {
			for(NSNumber *frameNumber in frameIndexes) {
				NSString *key = [_spritesheetPrefix stringByAppendingString:[self getRunningZeros:4 forNumber:[frameNumber intValue]]];
				CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:key];
				if(frame) {
					[frames addObject:frame];
				}
			}
		}
		animation = [CCAnimation animationWithSpriteFrames:frames delay:[animationData[@"timePerFrame"] floatValue]];
		animation.restoreOriginalFrame = restoreFrame;
		//we don't wanna cross-contaminate "walk" animations, for example.
		//specific to the sprite "type" [name] and animation name.
		//this way multiple instances of the same sprite type still use the same one, though.
		
		[[CCAnimationCache sharedAnimationCache] addAnimation:animation name:animationName];
	}
	id finalAnimation;
	int repeat = [animationData[@"repeat"] intValue];
	
	CCAnimate *animate = [CCAnimate actionWithAnimation:animation];
	
	if(options & SKCCSpriteAnimationOptionsDontRepeat) {
		// don't repeat.
		repeat = 0;
	}
	
	if(repeat == -1) {
		finalAnimation = [CCRepeatForever actionWithAction:animate];
	} else if(repeat == 0) {
		finalAnimation = animate;
	} else {
		finalAnimation = [CCRepeat actionWithAction:animate times:repeat];
	}
	if(animationData[@"sound"]) {
//		[[SKAudioManager sharedAudioManager] playSoundFile:[animationData objectForKey:@"sound"]];
	}
	if(animationData[@"translations"]) {
		NSDictionary *translationData = animationData[@"translations"];
		for(NSString *translationKey in translationData) {
			NSDictionary *translation = translationData[translationKey];
			id translationAction = [CCScaleTo actionWithDuration: [translation[@"time"] floatValue]
														   scale: [translation[@"scaleTo"] floatValue]];
			if([translationKey isEqual:@"scale"]) {
				finalAnimation = [CCSpawn actions:finalAnimation, translationAction, nil];
			}
			// add more "translation"s here if/as needed.
		}
	}
	BOOL hasANextAnimationAndShouldntCallBlockOurselves = (animationData[@"nextAnimation"]) && (options & SKCCSpriteAnimationOptionsPassCompletedBlockOn);
	if(block &&
	   ![finalAnimation isKindOfClass:[CCRepeatForever class]] &&
	   !hasANextAnimationAndShouldntCallBlockOurselves) { // can't sequence actions that never end.
		finalAnimation = [CCSequence actions:finalAnimation, [CCCallBlock actionWithBlock:block], nil];
	}
	if(![finalAnimation isKindOfClass:[CCRepeatForever class]] && animationData[@"nextAnimation"]) {
		SKKitBlock completionBlock = nil;
		if((options & SKCCSpriteAnimationOptionsPassCompletedBlockOn)) {
			completionBlock = block;
			options = options ^ SKCCSpriteAnimationOptionsPassCompletedBlockOn;
		}
		finalAnimation = [CCSequence actionOne:finalAnimation
										   two:[CCCallBlock actionWithBlock:^{
				[self runAnimation:animationData[@"nextAnimation"]
				   completionBlock:completionBlock
						   options:options
					 playbackSpeed:speed];
		}]];
	}
	if(options & SKCCSpriteAnimationOptionsRespondToSpeedNotifications) {
		if(speed <= 0.f) {
			speed = 1.f; // 0 speed and negative speeds are not allowed.
		}
		
		finalAnimation = [CCSpeed actionWithAction:finalAnimation speed:speed];
		[_runningAnimationsBasedOnSpeed addObject:finalAnimation];
	}
	
	[self stopAnimationByName:name];
	[self runningAnimations][name] = finalAnimation;
	[self runAction:finalAnimation];
	[animate update:0]; //to prevent flicker
}

//#if IS_iOS
-(void) addObserverForName:(NSString *)name object:(id)object queue:(NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *notification))block {
	id observer = [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserverForName:name object:object queue:queue usingBlock:block];
	[observers_ addObject:observer];
}

-(SKCCSprite *) weak {
	SK_VAR_WEAK id weakSelf = self;
	return weakSelf;
}
-(void) removeObserver {
	for(id observer in observers_) {
		[[NSNotificationCenter defaultCenter] removeObserver:observer];
	}
	[observers_ removeAllObjects];
}
//#endif


-(void) removeAsyncLoader:(SKSpriteAnimationAsyncLoader *)loader {
	[_loaders removeObject:loader];
}
-(void) removeAllAsyncLoaders {
	[_loaders removeAllObjects];
}
-(void) addAsyncLoader:(SKSpriteAnimationAsyncLoader *)loader {
	[_loaders addObject:loader];
}
-(NSArray *) _allChildrenInNodeTree:(CCNode *)node includingSelf:(BOOL)includeSelf {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:10];
	if(includeSelf) {
		[array addObject:node];
	}
	if(node.children && [node.children count] > 0) {
		for(CCNode *child in node.children) {
			[array addObjectsFromArray:[self _allChildrenInNodeTree:child includingSelf:YES]];
		}
	}
	return array;
}
-(NSArray *) allChildrenInNodeTreeIncludingSelf:(BOOL)includeSelf {
	return [self _allChildrenInNodeTree:self includingSelf:includeSelf];
}

+(void) setTouchScalingFactor:(float)factor {
	SKCCSpriteTouchScaleFactor = factor;
}
+(float) touchScalingFactor {
	return SKCCSpriteTouchScaleFactor;
}

@end

#endif
