//
//  SKCCLabelBMFont.m
//  OfficeAttacks
//
//  Created by Tim Park on 9/13/13.
//  Copyright (c) 2013 Arctic Empire. All rights reserved.
//

#if COCOS2D_VERSION || FORCE_COCOCS2D

#import "SKCCLabelBMFont.h"

@implementation SKCCLabelBMFont {
	int _maxWidth;
}

-(id) init {
	if (self = [super init]) {
		_maxWidth = -1;
	}
	return self;
}

-(void) setScaleForMaxWidth {
	if (_maxWidth < 0)
		return;
	float width = self.contentSize.width;
	if (width > _maxWidth)
		self.scale = _maxWidth / width;
	else
		self.scale = 1.f;
}

-(void) setString:(NSString*)newString {
	[super setString:newString];
	[self setScaleForMaxWidth];
}

-(void) setMaxWidth:(float)maxWidth {
	_maxWidth = maxWidth;
	[self setScaleForMaxWidth];
}

-(void) removeOrphans {
	float height = self.contentSize.height;
	float width = self.contentSize.width;
	if ((height < 4) || (width < 4))
		return;
	
	// If height change after small width change, was probably one line high.
	self.width = width - 1;
	if (self.contentSize.height != height) {
		self.width = width + 4;
		return;
	}
	
	// Binary search to find width for label that won't cause change in height.
	// (Remove one-word-on-last-line syndrome)
	float diff = width / 2.f;
	float testwidth = width - diff;
	while (diff > 1.f) {
		diff /= 2.f;
		self.width = testwidth;
		if (self.contentSize.height != height)
			testwidth += diff;
		else
			testwidth -= diff;
	}
	self.width = testwidth + 1.f;
}

@end

#endif
