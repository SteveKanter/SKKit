//
//  SKServerSignature.h
//  FriendlyBet
//
//	Created by Tim Park for the Office Attacks project
//  Modified for SKKit by Steve Kanter on 9/14/12
//
//	All rights go to Tim Park
//

#import <Foundation/Foundation.h>


@interface SKServerSignature : NSObject

+(int) generateRandomSeedNumber;
+(void) signWithParmsString:(NSString *)parmsString withSeedNumber:(int)number s:(NSString **)s t:(NSString **)t u:(int)u x:(NSString **)x y:(NSString **)y;

+(BOOL) validateSignature:(NSString *)x y:(NSString *)y s:(NSString *)s t:(NSString *)t timestampAllowance:(NSTimeInterval)timestampAllowance error:(NSError **)error;

@end