//
//  SKPlatformUtilities.m
//  AstroExpressMac
//
//  Created by Steve Kanter on 1/9/11.
//  Copyright 2011 Steve Kanter. All rights reserved.
//

#import <Foundation/Foundation.h>

#if COCOS2D_ENABLED
#import "cocos2d.h"
#endif

NSString *SKFilename(NSString *f, NSString *e, NSString *s) {return [NSString stringWithFormat:@"%@%@.%@", f,s,e];}
BOOL SKFileExistsInTexturePack(NSString *file, NSString *pack) {
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if(pack) {
		NSString *path = [NSString stringWithFormat:@"TexturePacks/%@/%@", pack, file];
		NSString *testPath = path;
		if(![testPath isAbsolutePath]) {
			testPath = RESOURCEFILE(path);
		}
		if([fileManager fileExistsAtPath:testPath]) {
			return YES;
		}
	}
	return NO;
}
NSString *SKFileFromTexturePackDefault(NSString *file, NSString *pack, BOOL *resultedInDefault) {
	
	// Load the specified file from the specified texture pack, if possible, otherwise default to loading it from the Default texture pack
	// Passing in nil for the pack will default in using the default texture pack.
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if(pack) {
		NSString *path = [NSString stringWithFormat:@"TexturePacks/%@/%@", pack, file];
		NSString *testPath = path;
		if(![testPath isAbsolutePath]) {
			testPath = RESOURCEFILE(path);
		}
		if([fileManager fileExistsAtPath:testPath]) {
			resultedInDefault = NO;
			return path;
		}
	}
	*resultedInDefault = YES;
	return [NSString stringWithFormat:@"TexturePacks/Default/%@",file];
}
NSString *SKFileFromTexturePack(NSString *file, NSString *pack) {
	BOOL resultedInDefault;
	return SKFileFromTexturePackDefault(file, pack, &resultedInDefault);
}


#if COCOS2D_ENABLED

#if IS_iOS
#import <UIKit/UIKit.h>
#ifdef UI_USER_INTERFACE_IDIOM
BOOL isIpad() {return [[SKUtilities sharedUtilities] isIpad];}
#else
BOOL isIpad() {return NO;}
#endif
BOOL isRetina() {return [[SKUtilities sharedUtilities] isRetina];}
BOOL is4InchDevice() {return [[SKUtilities sharedUtilities] is4InchDevice];}


NSString* SKGetiPadExtension() {return (CC_CONTENT_SCALE_FACTOR() == 2 ? @"" : @"-hd");}
NSString* SKGetiPadDeviceExtension() {return (CC_CONTENT_SCALE_FACTOR() == 2 ? @"" : @"~iPad");}
NSString* SKGetRetinaExtension() {return (isIpad() ? @"-iPadHD" : @"-hd");}

CGFloat SKScaleForPlatform(CGFloat num) {return isIpadReturn(num * 2, num);}
CGFloat SKScale(CGFloat num) {return SKScaleForPlatform(num);}
CGPoint SKCGPointMake(CGFloat x, CGFloat y) {return CGPointMake(SKScale(x),SKScale(y));}
CGRect SKCGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {return CGRectMake(SKScale(x),SKScale(y),SKScale(width),SKScale(height));}
CGSize SKCGSizeMake(CGFloat width, CGFloat height) {return CGSizeMake(SKScale(width), SKScale(height));}
NSString* SKGetFilenameOfFormat(NSString *f,NSString *e) {return isIpadReturn(SKFilename(f,e,SKGetiPadExtension()),SKFilename(f,e,@""));}
NSString* SKGetFilenameOfFormatNoiPadRetina(NSString *f,NSString *e) {return isIpadReturn(SKFilename(f,e,@"-hd"),SKFilename(f,e,@""));}
NSString* SKGetPNGFilename(NSString *filename) {return SKGetFilenameOfFormat(filename,@"png");}
NSString* SKGetJPGFilename(NSString *filename) {return SKGetFilenameOfFormat(filename,@"jpg");}
NSString* SKGetFNTFilename(NSString *filename) {return SKGetFilenameOfFormat(filename,@"fnt");}
NSString* SKGetPVRCCZFilename(NSString *filename) {return SKFilename(filename, @"pvr.ccz", @"");}
NSString* SKGetDeviceJPGFilename(NSString *filename) {return isIpadReturn(SKFilename(filename,@"jpg",SKGetiPadDeviceExtension()),SKGetJPGFilename(filename));}
NSString* SKGetDevicePNGFilename(NSString *filename) {return isIpadReturn(SKFilename(filename,@"png",SKGetiPadDeviceExtension()),SKGetPNGFilename(filename));}
NSString* SKGetPNGFilenameForRetina(NSString *f) {return (CC_CONTENT_SCALE_FACTOR() == 2 ? SKFilename(f,@"png",SKGetRetinaExtension()) : SKFilename(f,@"png",@""));}
NSString* SKGetPNGFilenameForRetinaAndiPad(NSString *f) {return isIpadReturn(SKFilename(f,@"png",SKGetiPadExtension()),SKGetPNGFilenameForRetina(f));}
CGPoint SKCGPointRegularfy(CGFloat x, CGFloat y) {return CGPointMake((x / 2), (y / 2));}
CGPoint SKCGPointFromString(NSString *pointString) {return CGPointFromString(pointString);}
CGRect SKCGRectFromString(NSString *rectString) {return CGRectFromString(rectString);}
CGSize SKCGSizeFromString(NSString *sizeString) {return CGSizeFromString(sizeString);}
NSString* SKNSStringFromCGPoint(CGPoint point) {return NSStringFromCGPoint(point);}
NSValue* SKGetNSValue(CGPoint point) {return [NSValue valueWithCGPoint:point];}
NSValue* SKGetNSValueSize(CGSize size) {return [NSValue valueWithCGSize:size];}
#else
#if IS_Mac
BOOL isIpad() {return NO;}
CGFloat SKScaleForPlatform(CGFloat num) {return num * 2.f;}
CGFloat SKScale(CGFloat num) {return SKScaleForPlatform(num);}
CGPoint SKCGPointMake(CGFloat x, CGFloat y) {return CGPointMake(SKScale(x), SKScale(y));}
CGPoint SKCGPointRegularfy(CGFloat x, CGFloat y) {return CGPointMake((x / 2), (y / 2));}
CGRect SKCGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {return CGRectMake((x*2),(y*2),(width*2),(height*2));}
CGSize SKCGSizeMake(CGFloat width, CGFloat height) {return CGSizeMake(width*2, height*2);}
CGPoint SKCGPointFromString(NSString *pointString) {return NSPointToCGPoint(NSPointFromString(pointString));}
NSString* SKNSStringFromCGPoint(CGPoint point) {return NSStringFromPoint(NSMakePoint(point.x, point.y)); }
NSString* SKGetDevicePNGFilename(NSString *filename) {return SKGetPNGFilename(filename);}
NSString* SKGetDeviceJPGFilename(NSString *filename) {return SKGetJPGFilename(filename);}
NSString* SKGetPNGFilenameForRetina(NSString *f) {return SKGetPNGFilename(f);}
NSString* SKGetPNGFilenameForRetinaAndiPad(NSString *f) {return SKGetPNGFilenameForRetina(f);}
NSString* SKGetFilenameOfFormat(NSString *filename,NSString *extension) {return SKFilename(filename,extension,@"-hd");}
NSString* SKGetPNGFilename(NSString *filename) {return SKGetFilenameOfFormat(filename,@"png");}
NSString* SKGetJPGFilename(NSString *filename) {return SKGetFilenameOfFormat(filename,@"jpg");}
NSString* SKGetFNTFilename(NSString *filename) {return SKGetFilenameOfFormat(filename,@"fnt");}
NSString* SKGetPVRCCZFilename(NSString *filename) {return SKGetFilenameOfFormat(filename,@"pvr.ccz");}
NSValue* SKGetNSValue(CGPoint point) {return [NSValue valueWithPoint:NSMakePoint(point.x, point.y)];}
NSValue* SKGetNSValueSize(CGSize size) {return [NSValue valueWithSize:NSMakeSize(size.width, size.height)];}
CGRect SKCGRectFromString(NSString *rectString) {return NSRectToCGRect(NSRectFromString(rectString));}
CGSize SKCGSizeFromString(NSString *sizeString) {return NSSizeToCGSize(NSSizeFromString(sizeString));}

@implementation NSValue (SKKitAdditions)
-(CGPoint) CGPointValue {
	NSPoint point = [self pointValue]; 
	return CGPointMake(point.x, point.y);
}
-(CGRect) CGRectValue {
	NSRect rect = [self rectValue];
	return CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}
+(NSValue *) valueWithCGRect:(CGRect)rect {
	return [self valueWithRect:NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
}
+(NSValue *) valueWithCGPoint:(CGPoint)point {
	return [self valueWithPoint:NSMakePoint(point.x, point.y)];
}
@end

#endif
#endif
#endif