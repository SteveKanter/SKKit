//
//  SKGameCenterManager.h
//  AstroExpressiOS
//
//  Created by Steve Kanter on 4/5/11.
//  Copyright 2011 Steve Kanter. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !defined(SKKitForceDisableGameCenter) || !SKKitForceDisableGameCenter

/// Posted when game center connects
extern NSString *const SKGameCenterManagerGameCenterConnectedNotification;


#if IS_iOS
#import <GameKit/GameKit.h>
#import "SKKitDefines.h"

@interface SKGameCenterManager : SKSingleton <GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate ,UIAlertViewDelegate>

+(SKGameCenterManager *) sharedGameCenterManager;
-(BOOL) isAuthenticated;
-(void) authenticateWithBlock:(SKKitBlock)block;

-(void) showLeaderboard:(NSString *)board;
-(void) showAchievements;
-(void) reportScore:(int)scoreValue ontoLeaderboard:(NSString *)leaderboard;
-(void) doIfAuthenticated:(SKKitBlock)block;
-(void) doIfAuthenticatedElsePromptForAuthentication:(SKKitBlock)block;

-(void) doImmediatePromptForAuthentication;

@property (nonatomic, readwrite, strong) GKLocalPlayer *localPlayer;
@property (nonatomic, readwrite, copy) SKKitBlock holderBlock;
#elif IS_Mac

@interface SKGameCenterManager : NSObject {
	BOOL didImmediatePromptForAuthentication;
	SKKitBlock holderBlock;
	id localPlayer;
}
+(SKGameCenterManager *) sharedGameCenterManager;
-(BOOL) isAuthenticated;
-(void) authenticateWithBlock:(SKKitBlock)block;

-(void) showLeaderboard:(NSString *)board;
-(void) reportScore:(int)scoreValue ontoLeaderboard:(NSString *)leaderboard;
-(void) doIfAuthenticated:(SKKitBlock)block;
-(void) doIfAuthenticatedElsePromptForAuthentication:(SKKitBlock)block;

-(void) doImmediatePromptForAuthentication;

@property (nonatomic, readwrite, retain) id localPlayer;
@property (nonatomic, readwrite, copy) SKKitBlock holderBlock;
#endif
@end

#endif
