//
//  IAOnboardingViewController.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/27/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAOnboardingViewController.h"

@interface IAOnboardingMainView : IAMainView
@end

@implementation IAOnboardingMainView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* bg = [NSBezierPath bezierPathWithRect:self.bounds];
    [IA_GREY_COLOUR(248.0) set];
    [bg fill];
}

@end

@interface IAOnboardingViewController ()
@end

@implementation IAOnboardingViewController
{
@private
    id<IAOnboardingProtocol> _delegate;
    
    NSInteger _page;
    NSView* _position_view;
    
    NSMutableArray* _headings;
    NSMutableArray* _messages;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithDelegate:(id<IAOnboardingProtocol>)delegate
{
    if (self = [super initWithNibName:self.className bundle:nil])
    {
        _delegate = delegate;
        
        _page = 0;
        
        _headings = [NSMutableArray array];
        [_headings addObject:NSLocalizedString(@"Drag and Drop",
                                               @"Drag and Drop")];
        [_headings addObject:NSLocalizedString(@"Search and Send",
                                               @"Search and Send")];
        [_headings addObject:NSLocalizedString(@"Receive File",
                                               @"Receive File")];
        [_headings addObject:NSLocalizedString(@"Beta Reminder and Invites",
                                               @"Beta Reminder and Invites")];
        
        _messages = [NSMutableArray array];
        [_messages addObject:NSLocalizedString(@"Drag and drop files and folders on the icon above to send them. ",
                                               @"Drag and drop files and folders on the icon above to send them. ")];
        [_messages addObject:NSLocalizedString(@"You can then search for contacts on Infinit by name, or send directly to an email address.",
                                               @"You can then search for contacts on Infinit by name, or send directly to an email address.")];
        [_messages addObject:NSLocalizedString(@"The Infinit icon turns red for incoming transfers. Click the icon to choose to accept or decline transfers.",
                                               @"The Infinit icon turns red for incoming transfers. Click the icon to choose to accept or decline transfers.")];
        [_messages addObject:NSLocalizedString(@"You can send to 3 email addresses for now. If you have any issues, let us know by email or on Twitter.",
                                               @"You can send to 3 email addresses for now. If you have any issues, let us know by email or on Twitter.")];
    }
    return self;
}

//- General Functions ------------------------------------------------------------------------------

- (void)moveToPage:(NSInteger)page
{
    if (page < 0 || page > _headings.count)
        return;
    
    _page = page;
    
    if (_page == 0)
    {
        [self.back_button setHidden:YES];
        [self.skip_button setHidden:NO];
    }
    else
    {
        [self.back_button setHidden:NO];
        [self.skip_button setHidden:YES];
    }
    
    if (_page == _headings.count - 1)
        self.next_button.title = NSLocalizedString(@"Done", @"done");
    else
        self.next_button.title = NSLocalizedString(@"Next", @"next");
    
    if (_page == _headings.count)
    {
        [self.popover close];
        [_delegate smallOnboardingDoneOnboarding:self];
        return;
    }
    
    self.heading.stringValue = _headings[_page];
    self.message.stringValue = _messages[_page];
}

- (void)startOnboardingWithStatusBarItem:(NSStatusItem*)item
{
    _position_view = item.view;
    [self moveToPage:0];
}

- (void)skipOnboarding
{
    [self.popover close];
    [_delegate smallOnboardingDoneOnboarding:self];
}

- (void)hideOnboarding
{
    [self.popover close];
}

- (void)continueOnboarding
{
    [self moveToPage:_page];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)backClicked:(NSButton*)sender
{
    [self moveToPage:(_page - 1)];
}

- (IBAction)nextClicked:(NSButton*)sender
{
    [self moveToPage:(_page + 1)];
}

- (IBAction)skipClicked:(NSButton*)sender
{
    [self moveToPage:_messages.count];
}

@end
