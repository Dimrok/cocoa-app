//
//  IAAdvancedSendViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAAdvancedSendViewController.h"

@interface IAAdvancedSendViewController ()

@end

@implementation IAAdvancedSendViewController
{
    id<IAAdvancedSendViewProtocol> _delegate;
    
    IAUserSearchViewController* _user_search_controller;
    
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAAdvancedSendViewProtocol>)delegate
{
    if (self = [super initWithNibName:[self className] bundle:nil])
    {
        _delegate = delegate;
        _user_search_controller = [[IAUserSearchViewController alloc] initWithDelegate:self];
    }
    return self;
}

- (NSString*)description
{
    return @"[AdvancedSendView]";
}

@end
