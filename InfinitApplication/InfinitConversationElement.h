//
//  InfinitConversationElement.h
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface InfinitConversationElement : NSObject

@property (nonatomic) IATransaction* transaction;
@property (nonatomic) BOOL important;
@property (nonatomic) BOOL spacer;
@property (nonatomic) BOOL on_left;
@property (nonatomic, readwrite) BOOL showing_files;

- (id)initWithTransaction:(IATransaction*)transaction;

@end
