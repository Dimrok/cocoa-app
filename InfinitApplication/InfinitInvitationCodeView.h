//
//  InfinitInvitationCodeView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 23/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IAViewController.h"

typedef NS_ENUM(NSUInteger, InfinitInvitationCodeMode)
{
  InfinitInvitationCodeModeRegister,
  InfinitInvitationCodeModeSettings,
};

@protocol InfinitInvitationCodeViewProtocol;

@interface InfinitInvitationCodeView : IAViewController

@property (nonatomic, readonly) InfinitInvitationCodeMode mode;

- (instancetype)initWithDelegate:(id<InfinitInvitationCodeViewProtocol>)delegate
                            mode:(InfinitInvitationCodeMode)mode;

@end

@protocol InfinitInvitationCodeViewProtocol <NSObject>

- (void)invitationCodeViewDone:(InfinitInvitationCodeView*)sender;

@end
