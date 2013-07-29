//
//  IANotLoggedInView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 7/26/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotLoggedInView.h"

@interface IANotLoggedInView ()

@end

@implementation IANotLoggedInView

- (id)initWithDelegate:(id<IANotLoggedInViewProtocol>)delegate
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
        _delegate = delegate;
    }
    return self;
}

@end