//
//  SKKitDefines.h
//  OfficeAttacks
//
//  Created by Steve Kanter on 7/23/12.
//  Copyright (c) 2012 Steve Kanter. All rights reserved.
//

#ifndef OfficeAttacks_SKKitDefines_h
#define OfficeAttacks_SKKitDefines_h


#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_4_3
	#define SK_PROP_WEAK weak
	#define SK_VAR_WEAK __weak
#else
	#define SK_PROP_WEAK unsafe_unretained
	#define SK_VAR_WEAK __unsafe_unretained
#endif

#endif