//
//  SKCCLabelBMFont.h
//  OfficeAttacks
//
//  Created by Tim Park on 9/13/13.
//  Copyright (c) 2013 Arctic Empire. All rights reserved.
//

#if COCOS2D_ENABLED

@interface SKCCLabelBMFont : CCLabelBMFont

/** Set a maximum width for the label, so if the text changes and the size goes over, change the scale.
 @param maxWidth the maximum width the label should occupy. */
-(void) setMaxWidth:(float)maxWidth;

/** If the text is multi-line, change the width to the smallest value such that the height doesn't change.
 So there should be no cases of having only one word on the last line. (orphans) */
-(void) removeOrphans;

@end

#endif
