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

ELLE_LOG_COMPONENT("OSX.ScreenshotModal");

@interface InfinitFirstScreenshotModal ()
@end

@implementation InfinitFirstScreenshotModal

//- Initialisation ---------------------------------------------------------------------------------

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

  NSFont* instruction_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica Neue"
                                                                        traits:NSUnboldFontMask
                                                                        weight:3
                                                                          size:18.0];
  NSMutableParagraphStyle* information_para =
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  information_para.alignment = NSCenterTextAlignment;
  information_para.lineSpacing = 8.0;
  NSDictionary* information_attrs = [IAFunctions textStyleWithFont:instruction_font
                                                    paragraphStyle:information_para
                                                            colour:IA_RGB_COLOUR(60, 60, 60)
                                                            shadow:nil];
  NSString* info_text =
    NSLocalizedString(@"Whenever you take a screenshot, we'll upload it and copy a link to your\n\
clipboard so you can share it in a message, an email or a tweet.", nil);
  self.information.attributedStringValue =
    [[NSAttributedString alloc] initWithString:info_text attributes:information_attrs];

  self.affirmative.title = NSLocalizedString(@"Help me share my screenshots!", nil);
  self.negative.title = NSLocalizedString(@"No thanks", nil);
}

//- Close ------------------------------------------------------------------------------------------

- (void)close
{
  if (self.window == nil)
    return;
  [self.window close];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)yesClicked:(id)sender
{
  [NSApp stopModalWithCode:INFINIT_UPLOAD_SCREENSHOTS];
}

- (IBAction)noClicked:(id)sender
{
  [NSApp stopModalWithCode:INFINIT_NO_UPLOAD_SCREENSHOTS];
}

@end
