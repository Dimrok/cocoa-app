//
//  InfinitInvitationCodeView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 23/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitInvitationCodeView.h"

#import "InfinitInvitationButtonCell.h"

#import <Gap/InfinitColor.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitStateResult.h>

@interface InfinitInvitationCodeView () <NSTextFieldDelegate>

@property (nonatomic, weak) id<InfinitInvitationCodeViewProtocol> delegate;

@property (nonatomic, weak) IBOutlet NSProgressIndicator* activity_indicator;
@property (nonatomic, weak) IBOutlet NSTextField* code_field;
@property (nonatomic, weak) IBOutlet NSTextField* error_label;
@property (nonatomic, weak) IBOutlet NSButton* next_button;
@property (nonatomic, weak) IBOutlet NSButton* skip_button;

@end

@implementation InfinitInvitationCodeView

#pragma mark - Init

- (instancetype)initWithDelegate:(id<InfinitInvitationCodeViewProtocol>)delegate
                            mode:(InfinitInvitationCodeMode)mode
{
  if (self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil])
  {
    _delegate = delegate;
    _mode = mode;
  }
  return self;
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  [self.next_button.cell setLeft:NO];
  [self.skip_button.cell setLeft:YES];
  self.skip_button.toolTip = nil;
  self.next_button.toolTip = nil;
  NSDictionary* attrs = @{NSFontAttributeName: [NSFont fontWithName:@"Monaco" size:36.0f],
                          NSForegroundColorAttributeName: [NSColor blueColor],
                          NSKernAttributeName: @13.0f};
  self.code_field.attributedStringValue = [[NSAttributedString alloc] initWithString:@"" attributes:attrs];
  if (self.mode == InfinitInvitationCodeModeRegister)
    self.skip_button.title = NSLocalizedString(@"SKIP", nil);
  else
    self.skip_button.title = NSLocalizedString(@"CANCEL", nil);
}

#pragma mark - General

- (void)checkCode
{
  if (self.code_field.stringValue.length != 5)
    return;
  self.error_label.hidden = YES;
  self.code_field.enabled = NO;
  self.next_button.enabled = NO;
  self.skip_button.enabled = NO;
  [self.activity_indicator startAnimation:nil];
  [[InfinitStateManager sharedInstance] useGhostCode:self.code_field.stringValue
                                     performSelector:@selector(codeCallback:)
                                            onObject:self];
}

- (void)codeCallback:(InfinitStateResult*)result
{
  [self.activity_indicator stopAnimation:nil];
  if (result.success || result.status == gap_ghost_code_already_used)
  {
    [_delegate invitationCodeViewDone:self];
  }
  else
  {
    self.error_label.stringValue = NSLocalizedString(@"Invalid code.", nil);
    self.error_label.hidden = NO;
  }
  self.code_field.enabled = YES;
  self.next_button.enabled = YES;
  self.skip_button.enabled = YES;
}

#pragma mark - Textfield Delegate

- (void)controlTextDidChange:(NSNotification*)notification
{
  if (self.code_field.stringValue.length == 5)
  {
    self.next_button.enabled = YES;
  }
  else if (self.code_field.stringValue.length < 5)
  {
    self.next_button.enabled = NO;
  }
  else
  {
    self.code_field.stringValue = [self.code_field.stringValue substringToIndex:5];
  }
}

#pragma mark - Button handling

- (IBAction)nextClicked:(id)sender
{
  [self checkCode];
}

- (IBAction)skipClicked:(id)sender
{
  [_delegate invitationCodeViewDone:self];
}

@end
