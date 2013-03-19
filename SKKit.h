//
//  SKKit.h
//  OfficeAttacks
//
//  Created by Steve Kanter on 12/7/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef __SKKit
#define __SKKit 1

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
	#define IS_iOS 1
#else
	#define IS_iOS 0
#endif

#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
	#define IS_Mac 1
#else
	#define IS_Mac 0
#endif


#if IS_iOS
	#import <UIKit/UIKit.h>
#endif

/** Any object wishing to handle their own touches must impliment the SKKitInput protocol fully.
 */
@protocol SKKitInput <NSObject>
@required
#if IS_iOS
/**
 Called when a touch is recognized.
 @param touch the UITouch object
 @return BOOL indicating whether the object wants to "own" this touch.
 */
-(BOOL) skTouchBegan:(UITouch *)touch;
/**
 Called when a touch moves.
 @param touch the UITouch object
 */
-(void) skTouchMoved:(UITouch *)touch;
/**
 Called when a touch is complete.
 @param touch the UITouch object
 */
-(void) skTouchEnded:(UITouch *)touch;
/**
 Called when a touch is cancelled.
 @param touch the UITouch object
 */
-(void) skTouchCancelled:(UITouch *)touch;
#endif
#if IS_Mac
/**
 Called when a click is recognized.
 @param event the NSEvent object
 @return BOOL indicating whether the object wants to "own" this click.
 */
-(BOOL) skClickBegan:(NSEvent *)event;
/**
 Called when a click moves.
 @param event the NSEvent object
 */
-(void) skClickMoved:(NSEvent *)event;
/**
 Called when a click ends.
 @param event the NSEvent object
 */
-(void) skClickEnded:(NSEvent *)event;
/**
 Called when a click is cancelled.
 @param event the NSEvent object
 */
-(void) skClickCancelled:(NSEvent *)event;
#endif



/** Whether or not the object accepts touches and clicks [touches and clicks]. */
@property(nonatomic, readwrite, assign) BOOL inputEnabled;

@end


@protocol SKKitInputDenier <NSObject>

-(BOOL) inputValidForNode:(id<SKKitInput>)node withWorldRect:(CGRect)rect;

@end


@class SKCCSprite;
/** Generic block with many purposes. */
typedef void(^SKKitBlock)(void);
/** The block that is called from a handler */
typedef void(^SKInputHandlerBlock)(SKCCSprite *node, id inputObject);
/** Block to be used when adding observers for NSNotificationCenter */
typedef void(^SKNotificationCenterBlock)(NSNotification *notification);

#define ___GENERATE_RANDOM(__MIN__, __MAX__) ((__MIN__) + arc4random() % (__MAX__ - __MIN__ + 1))
#define RANDOM_INT(__MIN__, __MAX__) (MIN_INT((__MAX__),MAX_INT((__MIN__),___GENERATE_RANDOM(__MIN__, __MAX__))))

#define MAX_INT(a,b)  ( ((a) > (b)) ? (a) : (b) )
#define MIN_INT(a,b)  ( ((a) < (b)) ? (a) : (b) )

#define OPACITY(__FLOAT__) (__FLOAT__ * 255.0f)
#define REVERSEOPACITY(__FLOAT__) (__FLOAT__ / 255.0f)

#define CGPointCCBBCenterFor(_parent_) CGPointMake(_parent_.contentSize.width/2.f,_parent_.contentSize.height/2.f)
#define CGPointCCCenter CGPointMake([[CCDirector sharedDirector] winSize].width/2.f,[[CCDirector sharedDirector] winSize].height/2.f)
#define CGPointCCBBCenter CGPointCCBBCenterFor(self)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromRGBWithAlpha(rgbValue,a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \ green:((float)((rgbValue & 0xFF00) >> 8))/255.0\ blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]

#define CCColorFromRGB(rgbValue) ccc3(((rgbValue & 0xFF0000) >> 16), ((rgbValue & 0xFF00) >> 8), (rgbValue & 0xFF))
#define CCColorFromRGBWithAlpha(rgbValue,a) ccc4(((rgbValue & 0xFF0000) >> 16), ((rgbValue & 0xFF00) >> 8), (rgbValue & 0xFF), a)
#define CCColorFromRGBString(rgbStringValue) ({unsigned int rgbValue;[[NSScanner scannerWithString:rgbStringValue] scanHexInt:&rgbValue]; CCColorFromRGB(rgbValue);})
#define CCColorFromRGBStringWithAlpha(rgbStringValue, a) ({unsigned int rgbValue;[[NSScanner scannerWithString:rgbStringValue] scanHexInt:&rgbValue]; CCColorFromRGBWithAlpha(rgbValue, a);})

#define RESOURCEFILE(__FILENAME__) ([NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], __FILENAME__])
#define DOCUMENTSFILE(__FILENAME__) ([NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], __FILENAME__])

#import "SKKitDefines.h"
#import "SKPlatformUtilities.h"
#import "SKCCDirector.h"
#import "SKSingleton.h"
#import "SKCCSprite.h"
#import "SKCCLayer.h"
#import "SKCCLayerColor.h"
#import "SKInputManager.h"
#import "SKUtilities.h"
#import "SKGameCenterManager.h"
#import "SKServerSignature.h"

#endif