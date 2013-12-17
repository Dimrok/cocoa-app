//
//  InfinitNotificationListConnectionCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 17/12/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "InfinitNotificationListConnectionCellView.h"

@implementation InfinitNotificationListConnectionCellView

- (BOOL)isOpaque
{
    return NO;
}

- (void)awakeFromNib
{
    [self.loading_icon setAnimates:YES];
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

@end
