//
//  SKServerSignature.m
//  FriendlyBet
//
//	Created by Tim Park for the Office Attacks project
//  Modified for SKKit by Steve Kanter on 9/14/12
//
//	All rights go to Tim Park
//

#import "SKServerSignature.h"
#import <CommonCrypto/CommonDigest.h>


#if !defined(__SKServerSignatureOutputSuffixChar1) ||\
	!defined(__SKServerSignatureOutputSuffixChar2) ||\
	!defined(__SKServerSignatureOutputSuffixChar3) ||\
	!defined(__SKServerSignatureOutputSuffixChar4) ||\
	!defined(__SKServerSignatureOutputSeedMD5Range) ||\
													\
	!defined(__SKServerSignatureInputSuffixChar1) ||\
	!defined(__SKServerSignatureInputSuffixChar2) ||\
	!defined(__SKServerSignatureInputSuffixChar3) ||\
	!defined(__SKServerSignatureInputSuffixChar4) ||\
	!defined(__SKServerSignatureInputSeedMD5Range)

#error You need to define SKServerSignature's suffix chars *BEFORE* importing SKKit.h.  See SKServerSignature.m

#define __SKServerSignatureOutputSuffixChar1 '.'
#define __SKServerSignatureOutputSuffixChar2 '.'
#define __SKServerSignatureOutputSuffixChar3 '.'
#define __SKServerSignatureOutputSuffixChar4 '.'
#define __SKServerSignatureOutputSeedMD5Range NSMakeRange(0, 1)

#define __SKServerSignatureInputSuffixChar1 '.'
#define __SKServerSignatureInputSuffixChar2 '.'
#define __SKServerSignatureInputSuffixChar3 '.'
#define __SKServerSignatureInputSuffixChar4 '.'
#define __SKServerSignatureInputSeedMD5Range NSMakeRange(0, 1)

#endif


@implementation SKServerSignature



// Description of hashing to prevent unauthorized server operations:
// Create a random string that looks like an md5sum and prepend it to the regular parameters as "y".
// Create a salt from the player or fromPlayer or player1 (or item if they don't exist):
// 28 characters, followed by @/[~.
// The 28 characters are created by modding the number above by 26, and adding
// an amount that changes every time (seeded with ((7th to 11th digits of y) mod 25) + 1,
// then adding 3 every iteration), and alternating capital and lowercase letters.
// Prepend the salt to the parameters as "x" and md5sum the result five times.
// Replace the x parameter with the new hash as "x" and send.
+(NSString *) md5string {
	NSMutableString *output = [NSMutableString stringWithCapacity:32];
	for (int i = 0; i < 32; i++)
		[output appendFormat:@"%01x", arc4random() % 16];
	return output;
}

#define __SALT(_1_, _2_, _3_, _4_)\
									char string[33];										\
									string[32] = 0;											\
									string[31] = _4_;										\
									num %= 26;												\
									string[29] = _2_;										\
									for (int i = 0; i < 32-4; i++) {						\
										num = (num + add) % 26;								\
										add += 3;											\
										if ((i % 2) == 0)									\
											string[i] = num + 'A';							\
										else												\
											string[i] = num + 'a';							\
									}														\
									string[30] = _3_;										\
									num--;													\
									string[28] = _1_;										\
									return [[NSString alloc] initWithUTF8String:string];	\


+(NSString *) inputSalt:(int)num add:(int)add {
	__SALT(__SKServerSignatureInputSuffixChar1, __SKServerSignatureInputSuffixChar2, __SKServerSignatureInputSuffixChar3, __SKServerSignatureInputSuffixChar4)
}

+(NSString *) outputSalt:(int)num add:(int)add {
	__SALT(__SKServerSignatureOutputSuffixChar1, __SKServerSignatureOutputSuffixChar2, __SKServerSignatureOutputSuffixChar3, __SKServerSignatureOutputSuffixChar4)
}

+(int) generateRandomSeedNumber {

	return RANDOM_INT(0, INT_MAX - 1);
}

+(void) signWithParmsString:(NSString *)parmsString withSeedNumber:(int)number s:(NSString **)s t:(NSString **)t u:(int)u x:(NSString **)x y:(NSString **)y {
	
	*y = [self md5string];
	*t = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
	
	unsigned int add = 0;
	[[NSScanner scannerWithString:[*y substringWithRange:__SKServerSignatureOutputSeedMD5Range]] scanHexInt:&add];
	
	add = (add % 25) + 1;
		
	parmsString = [NSString stringWithFormat:@"&y=%@", *y];
	
	*x = [[[[[[NSString stringWithFormat:@"x=%@&t=%@&u=%i%@", [self outputSalt:number add:add], *t, u, parmsString] MD5] MD5] MD5] MD5] MD5];
	
	*s = [NSString stringWithFormat:@"%i", number];
	
}


+(BOOL) validateSignature:(NSString *)orgX y:(NSString *)y s:(NSString *)s t:(NSString *)t timestampAllowance:(NSTimeInterval)timestampAllowance error:(NSError *__autoreleasing *)error {
	
	if([orgX length] != 32 || [y length] != 32) {
		return NO;
	}
	
	if([s isKindOfClass:[NSNumber class]]) {
		if([s intValue] == 0) {
			return NO;
		}
	} else if([s isKindOfClass:[NSString class]]) {
			
		if([s intValue] == 0 || [s length] != [[NSString stringWithFormat:@"%i", [s intValue]] length]) {
			return NO;
		}
	} else {
		return NO;
	}
	
	if(timestampAllowance != -1 && fabsf([[NSDate date] timeIntervalSince1970] - [t floatValue]) > timestampAllowance) {
		return NO;
	}
	
	
	int seedNumber = [s intValue] % 26;
	unsigned int add = 0;
	[[NSScanner scannerWithString:[y substringWithRange:__SKServerSignatureInputSeedMD5Range]] scanHexInt:&add];
	
	add = (add % 25) + 1;
	
	NSString *x = [self inputSalt:seedNumber add:add];
	
	
	NSString *parmsString = [NSString stringWithFormat:@"&y=%@", y];
	x = [NSString stringWithFormat:@"x=%@&t=%@%@", x, t, parmsString];
	
	
	x = [[[[[x MD5] MD5] MD5] MD5] MD5];
	
	if(![orgX isEqualToString:x]) {
		return NO;
	}
	
	return YES;
}

@end

