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

@end

@protocol InfinitStayAwakeProtocol <NSObject>

- (BOOL)stayAwakeManagerWantsActiveTransactions:(InfinitStayAwakeManager*)sender;

@end
