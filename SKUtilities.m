//
//  SKUtilities.m
//  OfficeAttacksLevelBuilder
//
//  Created by Steve Kanter on 12/15/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

#import "SKUtilities.h"

#import <CommonCrypto/CommonCrypto.h>

/// I take 0 credit for this.  Copied directly from stackoverflow.com/questions/217578/point-in-polygon-aka-hit-test
int pnpoly(int nvert, float *vertx, float *verty, float testx, float testy) {
	int i, j, c = 0;
	for (i = 0, j = nvert-1; i < nvert; j = i++) {
		if ( ((verty[i]>testy) != (verty[j]>testy)) &&
			(testx < (vertx[j]-vertx[i]) * (testy-verty[i]) / (verty[j]-verty[i]) + vertx[i]) )
			c = !c;
	}
	return c;
}


@implementation SKUtilities

SK_MAKE_SINGLETON(SKUtilities, sharedUtilities)

@synthesize isIpad;
@synthesize isRetina;
@synthesize is4InchDevice;

-(id) init {
	if( (self = [super init]) ) {
#ifdef UI_USER_INTERFACE_IDIOM
		isIpad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
#else
		isIpad = NO;
#endif
		isRetina = NO;
		
#if IS_iOS
		
		is4InchDevice = NO;
		
		if (([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) && ([[UIScreen mainScreen] scale] == 2.0))
			isRetina = YES;
		
		if([[UIScreen mainScreen] bounds].size.height == 568) {
			is4InchDevice = YES;
		}
#endif
	}
	return self;
}
+(BOOL) intersectsCircle:(SKCircle)circle andRect:(CGRect)rect {
	float circleDistance_x = abs(circle.location.x - rect.origin.x - rect.size.width/2);
	float circleDistance_y = abs(circle.location.y - rect.origin.y - rect.size.height/2);
	
	if (circleDistance_x > (rect.size.width/2 + circle.radius)) { return NO; }
	if (circleDistance_y > (rect.size.height/2 + circle.radius)) { return NO; }
	
	if (circleDistance_x <= (rect.size.width/2)) { return YES; } 
	if (circleDistance_y <= (rect.size.height/2)) { return YES; }
	
	float cornerDistance_sq = pow((circleDistance_x - rect.size.width/2),2) + pow((circleDistance_y - rect.size.height/2),2);
	
	return (cornerDistance_sq <= pow(circle.radius,2));
}

+(BOOL) intersectsEllipse:(SKEllipse)ellipse andRect:(CGRect)rect {
	// TODO: Add line-ellipse intersection for edge cases
	if (([self ellipse:ellipse containsPoint:CGPointMake(rect.origin.x, rect.origin.y)]) ||
		([self ellipse:ellipse containsPoint:CGPointMake(rect.origin.x+rect.size.width, rect.origin.y)]) ||
		([self ellipse:ellipse containsPoint:CGPointMake(rect.origin.x, rect.origin.y+rect.size.height)]) ||
		([self ellipse:ellipse containsPoint:CGPointMake(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height)]))
		return YES;
	return NO;
}

+(BOOL) ellipse:(SKEllipse)ellipse containsPoint:(CGPoint) point {
	// See http://mathforum.org/library/drmath/view/63045.html
	float origin_x = point.x - ellipse.location.x;
	float origin_y = point.y - ellipse.location.y;
	return ((((origin_x * origin_x) / (ellipse.radius.width * ellipse.radius.width)) +
			 ((origin_y * origin_y) / (ellipse.radius.height * ellipse.radius.height))) < 1.f);
}

+(BOOL) poly:(CGPoint *)poli numberOfPoints:(NSUInteger)numberOfPoints containsPoint:(CGPoint)point {
	float vertx[numberOfPoints + 1];
	float verty[numberOfPoints + 1];
	for(int i = 0; i < numberOfPoints + 1; i++) {
		int j = i;
		if(i == numberOfPoints) j = 0;
		vertx[i] = poli[j].x;
		verty[i] = poli[j].y;
	}
	return pnpoly((int)numberOfPoints + 1, vertx, verty, point.x, point.y);
}

+(float) dotProductOf:(CGPoint)point1 and:(CGPoint)point2 {
	return ((point1.x * point2.x) + (point1.y * point2.y));
}

+(float)distanceBetween:(CGPoint)point1 and:(CGPoint)point2 {
	return sqrt(pow((point2.x - point1.x),2) + pow((point2.y - point1.y),2));
}

+(float)distanceFrom:(CGPoint)point toLineSegmentStart:(CGPoint)start andEnd:(CGPoint)end {
	// See http://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
	// Return minimum distance between line segment start-end and point
	float lengthSquared = pow((end.x - start.x),2) + pow((end.y - start.y),2);
	if (lengthSquared == 0.f)
		return [self distanceBetween:point and:start];
	// Consider the line extending the segment, parameterized as start + t (end - start).
	// We find projection of point onto the line. 
	// It falls where t = [(point-start) . (end-start)] / |end-start|^2
	float t = [self dotProductOf:CGPointMake(point.x - start.x, point.y - start.y) and:CGPointMake(end.x - start.x, end.y - start.y)] / lengthSquared;
	if (t < 0.f)
		return [self distanceBetween:point and:start];
	else if (t > 1.f)
		return [self distanceBetween:point and:end];
	CGPoint projection = CGPointMake(start.x + (t * (end.x - start.x)), start.y + (t * (end.y - start.y)));
	return [self distanceBetween:point and:projection];
}

+(CGPoint *) _pointsForSegmentOfCircleWithRadius:(float)radius startAngle:(int)startAngle count:(int *)count {
	
	int segments = 10; // always one more than is defined here
	if(radius == 0.f) segments = 0;
	
	CGPoint *points = malloc(sizeof(CGPoint) * (segments + 1));
	
	for(int i = 0; i <= segments; i++) {
		float radians = CC_DEGREES_TO_RADIANS((i * (90.f / segments)) + startAngle);
		float x = radius * cosf(radians);
		float y = radius * sinf(radians);
		points[i] = CGPointMake(x, y);
	}
	
	*count = segments + 1;
	return points;
}

+(CGPoint *) roundedRectangleWithSize:(CGSize)size cornerRadiuses:(SKCornerRadiuses)radiuses count:(int *)count {
	
#define LOAD_CORNERS(_initials_, _startAngle_, _radiusIndex_, _radius_) \
	int _initials_ ## cornerCount = 0;\
	float _initials_ ## radius = _radius_;\
	CGPoint _initials_ ## center = CGPointMake((_radiusIndex_ == 1 || _radiusIndex_ == 2 ? _initials_ ## radius : size.width - _initials_ ## radius),\
												_radiusIndex_ == 1 || _radiusIndex_ == 0 ? size.height - _initials_ ## radius : _initials_ ## radius);\
	CGPoint *_initials_ ## points = [self _pointsForSegmentOfCircleWithRadius:_initials_ ## radius startAngle:_startAngle_ count:&_initials_ ## cornerCount];
	
#define FREE_CORNERS(_initials_) free(_initials_ ## points);
	
#define CLOSE_ENOUGH(_p1_, _p2_) (fabs(_p1_.x - _p2_.x) < 0.001f && fabs(_p1_.y - _p2_.y) < 0.001f)
	
#define ADD_POINT(_point_) if(!isnan(_point_.x) && !isnan(_point_.y) && !CLOSE_ENOUGH(previousPoint, _point_)) { NSLog(@"%i: %@", currentOffset+1, NSStringFromCGPoint(_point_)); points[currentOffset++] = previousPoint = _point_; }
	
#define ADD_CORNERS(_initials_) \
	for(int i = 0; i < _initials_ ## cornerCount; i++) {\
		 ADD_POINT(ccpAdd(_initials_ ## center, _initials_ ## points[i]));\
	}
	
	
	LOAD_CORNERS(TR, 0, 0, radiuses.topRight);
	LOAD_CORNERS(TL, 90, 1, radiuses.topLeft);
	LOAD_CORNERS(BL, 180, 2, radiuses.bottomLeft);
	LOAD_CORNERS(BR, 270, 3, radiuses.bottomRight);
	
	*count = ((TRcornerCount + TLcornerCount + BLcornerCount + BRcornerCount) + 8);
	CGPoint *points = malloc(sizeof(CGPoint) * *count);
	int currentOffset = -1;
	CGPoint previousPoint = CGPointMake(INT_MAX, INT_MAX);
	
	ADD_POINT(CGPointMake(0, size.height - TLradius));
	ADD_POINT(CGPointMake(0, BLradius));
	ADD_CORNERS(BL);
	ADD_POINT(CGPointMake(BLradius, 0));
	ADD_POINT(CGPointMake(size.width - BRradius, 0));
	ADD_CORNERS(BR);
	ADD_POINT(CGPointMake(size.width, BRradius));
	ADD_POINT(CGPointMake(size.width, size.height - TRradius));
	ADD_CORNERS(TR);
	ADD_POINT(CGPointMake(size.width - TRradius, size.height));
	ADD_POINT(CGPointMake(TLradius, size.height));
	ADD_CORNERS(TL);
	
	
	FREE_CORNERS(TR);
	FREE_CORNERS(TL);
	FREE_CORNERS(BL);
	FREE_CORNERS(BR);
	
	*count = currentOffset;
	
	return points;
	
}

// no sense rewriting the wheel / lazy / time crunched. www.musicalgeometry.com/?p=1197
+(NSArray *) splitString:(NSString*)str maxCharacters:(NSInteger)maxLength {
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *wordArray = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSInteger numberOfWords = [wordArray count];
    NSInteger index = 0;
    NSInteger lengthOfNextWord = 0;
    
	while (index < numberOfWords) {
		NSMutableString *line = [NSMutableString stringWithCapacity:1];
		while ((([line length] + lengthOfNextWord + 1) <= maxLength) && (index < numberOfWords)) {
	        lengthOfNextWord = [wordArray[index] length];
	        [line appendString:wordArray[index]];
	        index++;
			if (index < numberOfWords) {
				[line appendString:@" "];
			}
	    }
		[tempArray addObject:line];
	}
    return tempArray;
}

@end


@implementation NSObject (SKKitUtilitiesAdditions)

-(void) performSelector:(SEL)aSelector afterDelay:(NSTimeInterval)delay {
	[self performSelector:aSelector withObject:nil afterDelay:delay];
}

@end

#if COCOS2D_VERSION || FORCE_COCOCS2D

@implementation CCNode (SKKitUtilitiesAdditions)
-(CCAction *) runBlock:(SKKitBlock)block afterDelay:(NSTimeInterval)delay repeat:(int)repeatAmount {
	CCAction *action = nil;
	if(repeatAmount == 0) {
		action = [CCSequence actionOne:[CCDelayTime actionWithDuration:delay]
								   two:[CCCallBlock actionWithBlock:block]];
	} else if(repeatAmount == -1) {
		action = [CCRepeatForever actionWithAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:delay]
																	 two:[CCCallBlock actionWithBlock:block]]];
	} else {
		action = [CCRepeat actionWithAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:delay]
															  two:[CCCallBlock actionWithBlock:block]]
									  times:repeatAmount];
	}
	if(!action) return nil;
	[self runAction:action];
	return action;
}
-(CCAction *) runBlock:(SKKitBlock)block afterDelay:(NSTimeInterval)delay {
	return [self runBlock:block afterDelay:delay repeat:0];
}
-(int) highestZOrder {
	int highest = 0;
	for(CCNode *child in self.children) {
		highest = MAX(highest, (int)child.zOrder);
	}
	return highest;
}

// from www.cocos2d-iphone.org/forum/topic/20896

/*!
 Return the -boundingBox of another node, converted into this node's local
 coordinate space.
 */
-(CGRect) boundingBoxConvertedToNodeSpace:(CCNode *)other {
	// Get the bottomLeft and topRight corners of the other node's bounding box
	// in the other node's coordinate space.
	CGRect boundingBox = [other boundingBox];
	CGPoint bottomLeft = CGPointMake(boundingBox.origin.x, boundingBox.origin.y);
	CGPoint topRight = CGPointMake(boundingBox.origin.x + boundingBox.size.width, boundingBox.origin.y + boundingBox.size.height);
	
	// Convert bottomLeft and topRight to the global coordinate space.
	CGPoint worldSpaceBottomLeft = [other.parent convertToWorldSpace:bottomLeft];
	CGPoint worldSpaceTopRight = [other.parent convertToWorldSpace:topRight];
	
	// Convert worldSpaceBottomLeft and worldSpaceTopRight into this node's
	// local coordinate space.
	CGPoint nodeSpaceBottomLeft = [self.parent convertToNodeSpace:worldSpaceBottomLeft];
	CGPoint nodeSpaceTopRight = [self.parent convertToNodeSpace:worldSpaceTopRight];
	
	// Finally, construct the bounding box in this node's local coordinate space
	// and return it.
	float width = nodeSpaceTopRight.x - nodeSpaceBottomLeft.x;
	float height = nodeSpaceTopRight.y - nodeSpaceBottomLeft.y;
	return CGRectMake(nodeSpaceBottomLeft.x, nodeSpaceBottomLeft.y, width, height);
}

/*!
 Return a CGRect computed as the union of this node's -boundingBox and those of
 this node's descendant nodes.
 */

-(CGRect) frameIgnoringSelf:(BOOL)ignoringSelf {
	
	NSMutableArray *stack = [NSMutableArray new];
	NSMutableArray *stackToEnd = [NSMutableArray new];
	
	CGRect selfBoundingBox = [self boundingBox];
	
	float leftmost = selfBoundingBox.origin.x;
	float rightmost = leftmost + selfBoundingBox.size.width;
	float lowest = selfBoundingBox.origin.y;
	float highest = lowest + selfBoundingBox.size.height;
	
	BOOL hasSetInitials = !ignoringSelf; // if we are ignoring self, then we have NOT set initials, so the first node we get, is initials
										 // if we AREN'T ignoring ourselves, the initial values are already set.
	
	for (CCNode *child in self.children) { [stack addObject:child]; }
	while ([stack count] > 0)
	{
		__strong CCNode *node = [stack lastObject];
		
		[stackToEnd addObject:node];
		[stack removeLastObject];
		
		if(!node.visible) continue;
		
		[node prepareForFrameOfSelf];
		
		CGRect bb = [self boundingBoxConvertedToNodeSpace:node];
		float nodeleftmost = bb.origin.x;
		float noderightmost = bb.origin.x + bb.size.width;
		float nodelowest = bb.origin.y;
		float nodehighest = bb.origin.y + bb.size.height;
		
		if(!hasSetInitials) {
			leftmost = nodeleftmost;
			rightmost = noderightmost;
			lowest = nodelowest;
			highest = nodehighest;
			
			hasSetInitials = YES;
		}
		
		leftmost = fmin(leftmost,nodeleftmost);
		rightmost = fmax(rightmost,noderightmost);
		lowest = fmin(lowest,nodelowest);
		highest = fmax(highest,nodehighest);
		for (CCNode *child in node.children)
		{
			[stack addObject:child];
		}
		
		
		node = nil;
	}
	
	for(CCNode *item in stackToEnd) {
		[item endFrameOfSelf];
	}
	
	float width = rightmost - leftmost;
	float height = highest - lowest;
	return CGRectMake(leftmost,lowest,width,height);
}

-(void) prepareForFrameOfSelf {
	// no default implementation
}
-(void) endFrameOfSelf {
	// no default implementation
}

-(CGRect) frame {
	
	return [self frameIgnoringSelf:NO];
}



-(void) _setInput:(BOOL)enabled onChildrenOf:(CCNode <SKKitInput>*)parent {
	if([parent conformsToProtocol:@protocol(SKKitInput)]) {
		parent.inputEnabled = enabled;
	}
	if([parent children] && [[parent children] count] > 0) {
		for(CCNode *child in [parent children]) {
			[self _setInput:enabled onChildrenOf:(id<SKKitInput>)child];
		}
	}
}

-(void) disableInputOnSelfAndChildren {
	[self _setInput:NO onChildrenOf:(id<SKKitInput>)self];
}
-(void) enableInputOnSelfAndChildren {
	[self _setInput:YES onChildrenOf:(id<SKKitInput>)self];
}

@end


#endif

@implementation NSString(MD5)
-(NSString*) MD5 {
	// Create pointer to the string as UTF8
	const char *ptr = [self UTF8String];
	
	// Create byte array of unsigned chars
	unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
	
	// Create 16 byte MD5 hash value, store in buffer
	CC_MD5(ptr, strlen(ptr), md5Buffer);
	
	// Convert MD5 value in the buffer to NSString of hex values
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x",md5Buffer[i]];
	
	return output;
}
@end
// END NSString MD5 Category