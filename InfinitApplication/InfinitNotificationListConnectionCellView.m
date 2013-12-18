//
//  InfinitNotificationListConnectionCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 17/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitNotificationListConnectionCellView.h"

@implementation InfinitNotificationListConnectionCellView
{
    NSDictionary* _link_attrs;
    NSDictionary* _link_hover_attrs;
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)setUpCell
{
    [self.loading_icon setAnimates:YES];
    if (_link_attrs == nil)
    {
        NSFont* link_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                       traits:NSUnboldFontMask
                                                                       weight:0
                                                                         size:11.0];
        _link_attrs = [IAFunctions textStyleWithFont:link_font
                                      paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                              colour:IA_RGB_COLOUR(103.0, 181.0, 214.0)
                                              shadow:nil];
        
        _link_hover_attrs = [IAFunctions textStyleWithFont:link_font
                                            paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                    colour:IA_RGB_COLOUR(11.0, 117.0, 162)
                                                    shadow:nil];
    }
    NSString* problem = NSLocalizedString(@"Problem?", nil);
    self.problem_button.attributedTitle = [[NSAttributedString alloc] initWithString:problem
                                                                          attributes:_link_attrs];
    [self.problem_button setNormalTextAttributes:_link_attrs];
    [self.problem_button setHoverTextAttributes:_link_hover_attrs];
    [self.problem_button setToolTip:NSLocalizedString(@"Click to tell us!", @"click to tell us")];
}

- (void)setHeaderStr:(NSString*)str
{
    NSFont* header_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                     traits:NSUnboldFontMask
                                                                     weight:7
                                                                       size:13.0];
    NSDictionary* attrs = [IAFunctions textStyleWithFont:header_font
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:IA_GREY_COLOUR(29.0)
                                                  shadow:nil];
    self.no_connection.attributedStringValue = [[NSAttributedString alloc] initWithString:str
                                                                                attributes:attrs];
}

- (void)setMessageStr:(NSString*)str
{
    NSFont* msg_font = [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica"
                                                                  traits:NSUnboldFontMask
                                                                  weight:0
                                                                    size:11.5];
    NSDictionary* attrs = [IAFunctions textStyleWithFont:msg_font
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:IA_GREY_COLOUR(153.0)
                                                  shadow:nil];
    self.message.attributedStringValue = [[NSAttributedString alloc] initWithString:str
                                                                         attributes:attrs];
}

- (IBAction)onProblemClick:(NSButton*)sender
{
    [[NSWorkspace sharedWorkspace]
        openURL:[NSURL URLWithString:@"mailto:support@infinit.io?Subject=Connection%20Problem"]];
}

@end
