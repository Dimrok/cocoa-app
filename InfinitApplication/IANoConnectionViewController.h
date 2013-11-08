//
//  IANoConnectionViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 9/2/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAViewController.h"

@protocol IANoConnectionViewProtocol;

@interface IANoConnectionViewController : IAViewController

@property (nonatomic, strong) IBOutlet NSTextField* no_connection_message;

- (id)initWithDelegate:(id<IANoConnectionViewProtocol>)delegate;

@end

@protocol IANoConnectionViewProtocol <NSObject>

- (void)noConnectionViewWantsBack:(IANoConnectionViewController*)sender;

@end
