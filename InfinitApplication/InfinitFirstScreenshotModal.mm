//
//  InfinitFirstScreenshotModal.m
//  InfinitApplication
//
//  Created by Christopher Crone on 30/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitFirstScreenshotModal.h"

#undef check
#import <elle/log.hh>

#import "InfinitFeatureManager.h"

ELLE_LOG_COMPONENT("OSX.ScreenshotModal");

@interface InfinitFirstScreenshotModal ()

@property (nonatomic, weak) IBOutlet NSTextField* information;
@property (nonatomic, weak) IBOutlet NSButton* affirmative;
@property (nonatomic, weak) IBOutlet NSButton* negative;

@end

@implementation InfinitFirstScreenshotModal

#pragma mark - Init

- (id)init
{
  if (self = [super initWithWindowNibName:self.className])
  {
    self.window.level = NSFloatingWindowLevel;
  }
  return self;
}

- (void)windowDidLoad
{
  [self.window center];
  [super windowDidLoad];

  NSFont* instruction_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                        traits:NSUnboldFontMask
                                                                        weight:1
                                                                          size:16.0];
  NSMutableParagraphStyle* information_para =
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  information_para.alignment = NSLeftTextAlignment;
  information_para.lineSpacing = 8.0;
  NSDictionary* information_attrs = [IAFunctions textStyleWithFont:instruction_font
                                                    paragraphStyle:information_para
                                                            colour:IA_GREY_COLOUR(96)
                                                            shadow:nil];
  NSString* info_text =
    NSLocalizedString(@"Whenever you take a screenshot, we'll upload it and copy a\nlink to your\
clipboard so you can share it in a message, an\nemail or a tweet.", nil);
  self.information.attributedStringValue =
    [[NSAttributedString alloc] initWithString:info_text attributes:information_attrs];

  self.affirmative.title = @"Help me share my screenshots!";
  self.negative.title = NSLocalizedString(@"No, thanks", nil);
}

- (void)close
{
  if (self.window == nil)
    return;
  [self.window close];
}

#pragma mark - Button Handling

- (IBAction)yesClicked:(id)sender
{
  [NSApp stopModalWithCode:INFINIT_UPLOAD_SCREENSHOTS];
}

- (IBAction)noClicked:(id)sender
{
  [NSApp stopModalWithCode:INFINIT_NO_UPLOAD_SCREENSHOTS];
}

@end
