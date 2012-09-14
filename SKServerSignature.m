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



// See mobiledevelopertips.com/core-services/create-md5-hash-from-nsstring-nsdata-or-file.html
@interface NSString(MD5)
- (NSString *)MD5;
@end

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
-(NSString *) md5string {
	NSMutableString *output = [NSMutableString stringWithCapacity:32];
	for (int i = 0; i < 32; i++)
		[output appendFormat:@"%01x", arc4random() % 16];
	return output;
}

-(NSString *) salt:(long long)num add:(int)add {
	char string[33];
	string[32] = 0;
	string[31] = '~';
	num %= 26;
	string[29] = '/';
	for (int i = 0; i < 32-4; i++) {
		num = (num + add) % 26;
		add += 3;
		if ((i % 2) == 0)
			string[i] = num + 'A';
		else
			string[i] = num + 'a';
	}
	string[30] = '[';
	num--;
	string[28] = '@';
	return [[NSString alloc] initWithUTF8String:string];
}

@end