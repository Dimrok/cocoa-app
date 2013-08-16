//
//  IAConversationCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/15/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationCellView.h"

//- Conversation Bubble View -----------------------------------------------------------------------

@interface IAConversationBubbleView : NSView
@end

@implementation IAConversationBubbleView

- (void)drawRect:(NSRect)dirtyRect
{
    // Grey border
    NSBezierPath* grey_border = [NSBezierPath bezierPathWithRect:self.frame];
    [IA_GREY_COLOUR(212.0) set];
    [grey_border stroke];
    
    // White background
    NSBezierPath* white_bg = [NSBezierPath bezierPathWithRect:
                              NSMakeRect(1.0,
                                         1.0,
                                         self.frame.size.width - 1.0,
                                         self.frame.size.height - 1.0)];
    [IA_GREY_COLOUR(255.0) set];
    [white_bg fill];
}

@end

//- Conversation Cell View -------------------------------------------------------------------------

@implementation IAConversationCellView

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath* grey_bg = [NSBezierPath bezierPathWithRect:self.frame];
    [IA_GREY_COLOUR(246.0) set];
    [grey_bg fill];
}

//- Drawing Functions ------------------------------------------------------------------------------

- (void)setupCellWithTransaction:(IATransaction*)transaction
{
    NSMutableParagraphStyle* date_para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    date_para.alignment = NSCenterTextAlignment;
    NSDictionary* date_attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                               paragraphStyle:date_para
                                                       colour:IA_GREY_COLOUR(206.0)
                                                       shadow:nil];
    NSString* date_str = [IAFunctions relativeDateOf:transaction.timestamp];
    self.date.attributedStringValue = [[NSAttributedString alloc] initWithString:date_str
                                                                      attributes:date_attrs];
    
    NSDictionary* files_name_attrs = [IAFunctions
                                         textStyleWithFont:[NSFont systemFontOfSize:12.0]
                                            paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                    colour:IA_GREY_COLOUR(46.0)
                                                    shadow:nil];
    NSString* files_str;
    if (transaction.files_count > 1)
    {
        files_str = [NSString stringWithFormat:@"%ld %@", transaction.files_count,
                                                          NSLocalizedString(@"files", @"files")];
    }
    else
    {
        self.files_icon.image = [[NSWorkspace sharedWorkspace]
                                 iconForFileType:[transaction.first_filename pathExtension]];
        files_str = transaction.first_filename;
    }
    self.files_label.attributedStringValue = [[NSAttributedString alloc]
                                                        initWithString:files_str
                                                            attributes:files_name_attrs];
}

//- Button Handling --------------------------------------------------------------------------------

- (IBAction)messageButtonClicked:(NSButton*)sender
{
    
}

- (IBAction)expandFilesClicked:(NSButton*)sender
{
    
}

@end
