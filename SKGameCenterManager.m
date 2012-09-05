//
//  SKGameCenterManager.m
//  AstroExpressiOS
//
//  Created by Steve Kanter on 4/5/11.
//  Copyright 2011 Steve Kanter. All rights reserved.
//

#import "SKGameCenterManager.h"
#import "RootViewController.h"

NSString *const SKGameCenterManagerGameCenterConnectedNotification = @"SKGameCenterManagerGameCenterConnectedNotification";

#if IS_iOS

@implementation SKGameCenterManager {
	BOOL _didImmediatePromptForAuthentication;
}
@synthesize rootViewController=_rootViewController;
@synthesize holderBlock=_holderBlock;
@synthesize localPlayer=_localPlayer;


SK_MAKE_SINGLETON(SKGameCenterManager, sharedGameCenterManager)

-(id) init {
	if( (self = [super init]) ) {
		_didImmediatePromptForAuthentication = NO;
		_holderBlock = nil;
		_localPlayer = [GKLocalPlayer localPlayer];
	}
	return self;
}

-(void) doImmediatePromptForAuthentication {
	if(_didImmediatePromptForAuthentication) return;
	_didImmediatePromptForAuthentication = YES;
	[self authenticateWithBlock:nil];
}
-(BOOL) isAuthenticated {
	return [self.localPlayer isAuthenticated];
}
-(void) authenticateWithBlock:(SKKitBlock)block {
	if(![self isAuthenticated]) {
//		NSLog(@"%i",[self isAuthenticated]);
		[self.localPlayer authenticateWithCompletionHandler:^(NSError *error) {
//			NSLog(@"%i %@ %@",[self isAuthenticated], [self.localPlayer alias], error);
			if(!error) {
				if(block) {
					block();
				}
				[[NSNotificationCenter defaultCenter] postNotificationName:SKGameCenterManagerGameCenterConnectedNotification object:nil];
			}
		}];
		return;
	}
	if(block) {
		block();
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:SKGameCenterManagerGameCenterConnectedNotification object:nil];
}
-(void) doIfAuthenticated:(SKKitBlock)block prompt:(BOOL)prompt {
	if(!_didImmediatePromptForAuthentication) {
		[self authenticateWithBlock:block];
		_didImmediatePromptForAuthentication = YES;
		return;
	}
	if(![self isAuthenticated]) {
		if(prompt) {
			self.holderBlock = block;
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not logged in"
															message:@"This requires you to be logged in to Game Center.  Would you like to login now?"
														   delegate:self
												  cancelButtonTitle:@"No"
												  otherButtonTitles:@"Yes", nil];
			[alert setTag:123];
			[alert show];
		}
		return;
	}
	if(block) {
		block();
	}
}
-(void) doIfAuthenticated:(SKKitBlock)block {
	[self doIfAuthenticated:block prompt:NO];
}
-(void) doIfAuthenticatedElsePromptForAuthentication:(SKKitBlock)block {
	[self doIfAuthenticated:block prompt:YES];
}
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(alertView.tag == 123) {
		if(buttonIndex != alertView.cancelButtonIndex) {
			[self authenticateWithBlock:self.holderBlock];
		}
	}
}
-(void) reportScore:(int)scoreValue ontoLeaderboard:(NSString *)leaderboard {
	NSLog(@"Score Reported: %i",scoreValue);
	[self doIfAuthenticated:^{
		GKScore *score = [[GKScore alloc] initWithCategory:leaderboard];
//		NSAssert(NO, @"Add leaderboard :)");
//		GKScore *score = [[GKScore alloc] initWithCategory:@""];
		score.value = scoreValue;
		[score reportScoreWithCompletionHandler:^(NSError *error) {
			NSLog(@"Score Reported Error: %@",error);
		}];
	}];
}
-(void) showLeaderboard:(NSString *)board {
	[self doIfAuthenticatedElsePromptForAuthentication:^{
		GKLeaderboardViewController *leaderboard = [[GKLeaderboardViewController alloc] init];
		leaderboard.category = board;
		leaderboard.leaderboardDelegate = self;
		leaderboard.timeScope = GKLeaderboardTimeScopeToday;
		[[self rootViewController] presentModalViewController:leaderboard animated:YES];
	}];
}
-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController {
	[[self rootViewController] dismissModalViewControllerAnimated:YES];
}
-(void) showAchievements {
	[self doIfAuthenticatedElsePromptForAuthentication:^{
		GKAchievementViewController *vc = [[GKAchievementViewController alloc] init];
		vc.achievementDelegate = self;
		[[self rootViewController] presentModalViewController:vc animated:YES];
	}];
}
-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController {
	[[self rootViewController] dismissModalViewControllerAnimated:YES];
}
-(void) dump {
	self.holderBlock = nil;
	self.localPlayer = nil;
	self.rootViewController = nil;
}
#elif IS_Mac

@implementation FakeRootViewController
-(void) addBannerAd {
	
}
-(void) removeBannerAd {
	
}
@end

@implementation SKGameCenterManager
@synthesize rootViewController, localPlayer, holderBlock;
MAKE_SINGLETON(SKGameCenterManager, sharedGameCenterManager)

-(id) init {
	if( (self = [super init]) ) {
		didImmediatePromptForAuthentication = NO;
		holderBlock = nil;
	}
	return self;
}

-(void) doImmediatePromptForAuthentication {
	
}
-(BOOL) isAuthenticated {
	return NO;
}
-(void) authenticateWithBlock:(SKKitBlock)block {
	
}
-(void) doIfAuthenticated:(SKKitBlock)block prompt:(BOOL)prompt {
	
}
-(void) doIfAuthenticated:(SKKitBlock)block {
	
}
-(void) doIfAuthenticatedElsePromptForAuthentication:(SKKitBlock)block {
	
}
-(void) showLeaderboard:(NSString *)board {
	
}
-(void) reportScore:(int)scoreValue ontoLeaderboard:(NSString *)leaderboard {
	
}
-(void) dump {
	self.holderBlock = nil;
	self.localPlayer = nil;
	self.rootViewController = nil;
}
#endif
@end
