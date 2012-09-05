//
//  SKPlatformUtilities.h
//
//  Created by Steve Kanter on 1/9/11.
//  Copyright 2011 Steve Kanter. All rights reserved.
//
#import <Foundation/Foundation.h>

BOOL isIpad();
BOOL isRetina();
CGFloat SKScaleForPlatform(CGFloat num);
CGFloat SKScale(CGFloat num);
CGPoint SKCGPointMake(CGFloat x, CGFloat y);
CGPoint SKCGPointRegularfy(CGFloat x, CGFloat y);
CGRect SKCGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height);
CGSize SKCGSizeMake(CGFloat width, CGFloat height);
CGPoint SKCGPointFromString(NSString *pointString);
CGRect SKCGRectFromString(NSString *rectString);
CGSize SKCGSizeFromString(NSString *sizeString);
NSString *SKNSStringFromCGPoint(CGPoint point);
NSValue *SKGetNSValue(CGPoint point);
NSValue *SKGetNSValueSize(CGSize size);

NSString *SKGetFilenameOfFormat(NSString *filename,NSString *extension);
NSString* SKGetFilenameOfFormatNoiPadRetina(NSString *f,NSString *e);
NSString *SKGetPNGFilename(NSString *filename);
NSString *SKGetJPGFilename(NSString *filename);
NSString *SKGetFNTFilename(NSString *filename);
NSString *SKGetPVRCCZFilename(NSString *filename);

NSString *SKGetDevicePNGFilename(NSString *filename);
NSString *SKGetDeviceJPGFilename(NSString *filename);
NSString *SKGetPNGFilenameForRetina(NSString *f);
NSString *SKGetPNGFilenameForRetinaAndiPad(NSString *f);

NSString *SKFilename(NSString *f, NSString *e, NSString *s);

BOOL SKFileExistsInTexturePack(NSString *file, NSString *pack);
NSString *SKFileFromTexturePack(NSString *file, NSString *pack);

#define isIpadReturn(__ITEM__,__ELSE__) (isIpad() ? (__ITEM__) : (__ELSE__))
#define isIpadReturnNumber(__ITEM__) isIpadReturn((__ITEM__),0)
#define SKIntAsNumber(_int_) ([NSNumber numberWithInt:(_int_)])
#define SKFloatAsNumber(_float_) ([NSNumber numberWithFloat:(_float_)])

#if IS_Mac
/** Additions to NSValue to make it work the same on OS X as it does iOS */
@interface NSValue (SKKitAdditions)
/** Bridged to pointValue */
-(CGPoint) CGPointValue;
/** Bridged to rectValue */
-(CGRect) CGRectValue;
/** Bridged to valueWithRect:
 @param rect the rect
 */
+(NSValue *) valueWithCGRect:(CGRect)rect;
/** Bridged to valueWithPoint:
 @param point the point
 */
+(NSValue *) valueWithCGPoint:(CGPoint)point;
@end
#endif

/** Additions to all CCNode objects */
@interface CCNode (SKKitAdditions)
/** Make boundingBox a property instead of getter/setter methods only. */
@property(nonatomic,readonly) CGRect boundingBox;
@end