//
//  InfinitStayAwakeManager.h
//  InfinitApplication
//
//  Created by Christopher Crone on 18/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol InfinitStayAwakeProtocol;

@interface InfinitStayAwakeManager : NSObject

+ (InfinitStayAwakeManager*)setUpInstanceWithDelegate:(id<InfinitStayAwakeProtocol>)delegate;

+ (InfinitStayAwakeManager*)instance;

+ (BOOL)stayAwake;
+ (void)setStayAwake:(BOOL)stay_awake;

@end

@protocol InfinitStayAwakeProtocol <NSObject>

- (BOOL)stayAwakeManagerWantsActiveTransactions:(InfinitStayAwakeManager*)sender;

@end
