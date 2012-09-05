//
//  SKUtilities.m
//  OfficeAttacksLevelBuilder
//
//  Created by Steve Kanter on 12/15/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

#import "SKUtilities.h"

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

-(id) init {
	if( (self = [super init]) ) {
#ifdef UI_USER_INTERFACE_IDIOM
		isIpad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
#else
		isIpad = NO;
#endif
		isRetina = NO;
		
#if IS_iOS
		if (([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) && ([[UIScreen mainScreen] scale] == 2.0))
			isRetina = YES;
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
	if (([self ellipse:ellipse containsPoint:ccp(rect.origin.x, rect.origin.y)]) ||
		([self ellipse:ellipse containsPoint:ccp(rect.origin.x+rect.size.width, rect.origin.y)]) ||
		([self ellipse:ellipse containsPoint:ccp(rect.origin.x, rect.origin.y+rect.size.height)]) ||
		([self ellipse:ellipse containsPoint:ccp(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height)]))
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
	float t = [self dotProductOf:ccp(point.x - start.x, point.y - start.y) and:ccp(end.x - start.x, end.y - start.y)] / lengthSquared;
	if (t < 0.f)
		return [self distanceBetween:point and:start];
	else if (t > 1.f)
		return [self distanceBetween:point and:end];
	CGPoint projection = ccp(start.x + (t * (end.x - start.x)), start.y + (t * (end.y - start.y)));
	return [self distanceBetween:point and:projection];
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
	        lengthOfNextWord = [[wordArray objectAtIndex:index] length];
	        [line appendString:[wordArray objectAtIndex:index]];
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
@end
