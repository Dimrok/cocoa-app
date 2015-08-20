//
//  InfinitQuotaManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 19/08/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InfinitQuotaManager : NSObject

+ (void)start;

+ (void)showWindowForSendToSelfLimit;
+ (void)showWindowForTransferSizeLimit;

@end
