//
//  IAConversationProgressBar.m
//  InfinitApplication
//
//  Created by Christopher Crone on 9/23/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IAConversationProgressBar.h"

#import <QuartzCore/QuartzCore.h>

@implementation IAConversationProgressBar
{
@private
    NSImage* _indeterminate_image;
    NSImageView* _indeterminate_view;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize doubleValue = _double_value;
@synthesize indeterminate = _indeterminate;
@synthesize time_remaining = _time_remaining;
@synthesize totalSize = _total_size;

- (id)initWithCoder:(NSCoder*)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _total_size = nil;
        _double_value = 0.0;
        _time_remaining = 0.0;
        _indeterminate_image = [IAFunctions imageNamed:@"loading-bar"];
        _indeterminate_view = nil;
    }
    return self;
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
    CGFloat border_thickness = 1.0;
    NSBezierPath* border_path = [NSBezierPath bezierPathWithRoundedRect:self.bounds
                                                                xRadius:5.0
                                                                yRadius:5.0];
    [IA_RGB_COLOUR(194.0, 208.0, 216.0) set];
    [border_path setLineWidth:border_thickness];
    [border_path stroke];
    
    if (_indeterminate)
        return;
    
    NSRect progress_rect = NSMakeRect(self.bounds.origin.x + border_thickness,
                                      self.bounds.origin.y + border_thickness,
                                      (NSWidth(self.bounds) / self.maxValue * self.doubleValue) -
                                           border_thickness,
                                      NSHeight(self.bounds) - 2.0 * border_thickness);
    NSBezierPath* progress_bar = [NSBezierPath bezierPathWithRect:progress_rect];
    [IA_RGB_COLOUR(221.0, 239.0, 244.0) set];
    [progress_bar fill];
    NSBezierPath* progress_line = [NSBezierPath bezierPathWithRect:
                                   NSMakeRect(progress_rect.origin.x + progress_rect.size.width,
                                              progress_rect.origin.y,
                                              1.0,
                                              progress_rect.size.height)];
    [IA_RGB_COLOUR(194.0, 208.0, 216.0) set];
    [progress_line fill];
    
    NSRect progress_mask_rect = NSMakeRect(self.bounds.origin.x + border_thickness,
                                           self.bounds.origin.y + border_thickness,
                                           NSWidth(self.bounds) - border_thickness,
                                           NSHeight(self.bounds) - 2.0 * border_thickness);
    
    NSBezierPath* progress_mask = [NSBezierPath bezierPathWithRoundedRect:progress_mask_rect
                                                                  xRadius:4.0
                                                                  yRadius:4.0];
    [progress_mask addClip];
    
    if (_total_size == nil || _total_size <= 0)
        return;
    
    NSDictionary* data_style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:10.0]
                                               paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                       colour:IA_RGB_COLOUR(150.0, 170.0, 184.0)
                                                       shadow:nil];
    NSUInteger bytes_transferred = floor(_double_value / self.maxValue * _total_size.doubleValue);
    NSString* file_size_progress = [NSString stringWithFormat:@"%@/%@",
                                    [IAFunctions fileSizeStringFrom:bytes_transferred],
                                    [IAFunctions fileSizeStringFrom:_total_size.unsignedIntegerValue]];
    NSAttributedString* file_size_str = [[NSAttributedString alloc] initWithString:file_size_progress
                                                                        attributes:data_style];
    NSPoint size_pt = NSMakePoint(self.bounds.origin.x + 8.0, self.bounds.origin.y + 4.0);
    [file_size_str drawAtPoint:size_pt];
    
    if (_time_remaining <= 0.0)
        return;
    
    NSDictionary* text_style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:9.0]
                                               paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                       colour:IA_RGB_COLOUR(150.0, 170.0, 184.0)
                                                       shadow:nil];
    
    NSString* time_remaining_str = [IAFunctions timeRemainingFrom:_time_remaining];
    
    NSAttributedString* time_str = [[NSAttributedString alloc] initWithString:time_remaining_str
                                                                   attributes:text_style];
    
    NSPoint time_pt = NSMakePoint(self.bounds.origin.x + NSWidth(self.bounds) - time_str.size.width - 7.0,
                                  self.bounds.origin.y + 3.0);
    [time_str drawAtPoint:time_pt];
}

//- General Functions ------------------------------------------------------------------------------

- (void)setTimeRemaining:(NSTimeInterval)time_remaining
{
    _time_remaining = time_remaining;
    [self setNeedsDisplay:YES];
}

- (void)setDoubleValue:(double)doubleValue
{
    _double_value = doubleValue;
    [self setNeedsDisplay:YES];
}

- (void)setTotalSize:(NSNumber*)totalSize
{
    _total_size = totalSize;
    [self setNeedsDisplay:YES];
}

- (void)setIndeterminate:(BOOL)flag
{
    _indeterminate = flag;
    if (_indeterminate)
    {
        CGFloat w_diff = NSWidth(self.bounds) - _indeterminate_image.size.width;
        CGFloat h_diff = NSHeight(self.bounds) - _indeterminate_image.size.height;
        // WORKAROUND: 10.7 positions the indeterminate gif too high
        NSRect centred_rect;
        if ([IAFunctions osxVersion] == INFINIT_OS_X_VERSION_10_7)
        {
            centred_rect = NSMakeRect(self.frame.origin.x + (w_diff / 2.0),
                                      self.frame.origin.y + (h_diff / 2.0) - 3.0,
                                      _indeterminate_image.size.width,
                                      _indeterminate_image.size.height);
        }
        else
        {
            centred_rect = NSMakeRect(self.frame.origin.x + (w_diff / 2.0),
                                      self.frame.origin.y + (h_diff / 2.0),
                                      _indeterminate_image.size.width,
                                      _indeterminate_image.size.height);
        }
        if (_indeterminate_view == nil)
        {
            _indeterminate_view = [[NSImageView alloc] initWithFrame:centred_rect];
        }
        [self.superview addSubview:_indeterminate_view];
        _indeterminate_view.image = _indeterminate_image;
        _indeterminate_view.animates = YES;
        [self setNeedsDisplay:YES];
    }
    else
    {
        [_indeterminate_view removeFromSuperview];
        _indeterminate_view = nil;
        [self setNeedsDisplay:YES];
    }
}

//- Animation --------------------------------------------------------------------------------------

+ (id)defaultAnimationForKey:(NSString*)key
{
    if ([key isEqualToString:@"doubleValue"])
        return [CABasicAnimation animation];
    else if ([key isEqualToString:@"time_remaining"])
        return [CABasicAnimation animation];
    
    return [super defaultAnimationForKey:key];
}

@end
