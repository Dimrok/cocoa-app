//
//  IAAdvancedSendViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 8/4/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAViewController.h"

#import "IAUserSearchViewController.h"

@protocol IAAdvancedSendViewProtocol;

@interface IAAdvancedSendViewController : IAViewController <NSTextFieldDelegate,
                                                            IAUserSearchViewProtocol>

@property (nonatomic, strong) NSButton* send_button;

@end


@protocol IAAdvancedSendViewProtocol <NSObject>

@end