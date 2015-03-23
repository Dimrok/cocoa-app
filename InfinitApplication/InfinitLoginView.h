//
//  InfinitLoginView.h
//  InfinitApplication
//
//  Created by Christopher Crone on 19/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IAViewController.h"

typedef NS_ENUM(NSUInteger, InfinitLoginSelector)
{
  InfinitLoginSelectorLeft,
  InfinitLoginSelectorRight,
};

@interface InfinitLoginView : IAMainView

@property (nonatomic, readwrite) InfinitLoginSelector selector;

@end
