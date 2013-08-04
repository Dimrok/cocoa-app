//
//  IASearchResultsViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IASearchResultsViewController.h"

@interface IASearchResultsViewController ()

@end

@implementation IASearchResultsViewController
{
    id<IASearchResultsViewProtocol> _delegate;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IASearchResultsViewProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
    }
    
    return self;
}


- (NSString*)description
{
    return @"[SearchResultsViewController]";
}

//- General Functions ------------------------------------------------------------------------------

- (void)searchForString:(NSString*)str
{
    
}

@end
