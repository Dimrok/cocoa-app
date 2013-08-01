//
//  IANotLoggedInView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IANotLoggedInViewProtocol;

@interface IANotLoggedInView : NSViewController
{
@private
    id<IANotLoggedInViewProtocol> _delegate;
}

- (id)initWithDelegate:(id<IANotLoggedInViewProtocol>)delegate;

@end

@protocol IANotLoggedInViewProtocol <NSObject>
@end
