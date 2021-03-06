//
//  InfinitConversationPersonView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 17/03/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "InfinitSizedTextField.h"

@protocol InfinitConversationPersonViewProtocol;

@interface InfinitConversationPersonView : NSView

@property (nonatomic, weak) IBOutlet InfinitSizedTextField* fullname;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* fullname_width;
@property (nonatomic, weak) IBOutlet NSImageView* online_status;

- (void)setDelegate:(id<InfinitConversationPersonViewProtocol>)delegate;

@end


@protocol InfinitConversationPersonViewProtocol <NSObject>

- (void)conversationPersonViewGotClick:(InfinitConversationPersonView*)sender;

@end