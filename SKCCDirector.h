//
//  SKCCDirector.h
//  FriendlyBet
//
//  Created by Steve Kanter on 9/5/12.
//
//

#import "CCDirectorIOS.h"

/// A subclass of CCDirectorDisplayLink for now to override -[CCDirector startAnimation] this way we can animate while dragging a UIScrollView, as well as hold a reference to the rootViewController
@interface SKCCDirector : CCDirectorDisplayLink

@property(nonatomic, readwrite, SK_PROP_WEAK) id rootViewController;

@end