//
//  InfinitLoginViewController.h
//  InfinitApplication
//
//  Created by Christopher Crone on 31/10/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAHoverButton.h"
#import "IAViewController.h"

typedef NS_ENUM(NSUInteger, InfinitLoginViewMode)
{
  InfinitLoginViewModeRegister,
  InfinitLoginViewModeLogin,
  InfinitLoginViewModeLoginCredentials,
};

@class InfinitLoginView;

@protocol InfinitLoginViewControllerProtocol;

@interface InfinitLoginViewController : IAViewController

@property (nonatomic, readwrite) InfinitLoginViewMode mode;

- (id)initWithDelegate:(id<InfinitLoginViewControllerProtocol>)delegate
              withMode:(InfinitLoginViewMode)mode;

- (void)showWithError:(NSString*)error
             username:(NSString*)username
          andPassword:(NSString*)password;

@end

@protocol InfinitLoginViewControllerProtocol <NSObject>

- (void)loginViewDoneLogin:(InfinitLoginViewController*)sender;
- (void)loginViewDoneRegister:(InfinitLoginViewController*)sender;

- (void)loginViewWantsClose:(InfinitLoginViewController*)sender;

- (void)loginViewWantsCloseAndQuit:(InfinitLoginViewController*)sender;

- (void)loginViewWantsReportProblem:(InfinitLoginViewController*)sender;

- (void)loginViewWantsCheckForUpdate:(InfinitLoginViewController*)sender;

@end
