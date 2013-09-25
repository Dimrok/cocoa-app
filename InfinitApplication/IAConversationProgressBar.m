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
    NSTimeInterval _last_time;
    double _transfer_rate;
    NSMutableArray* _data_points;
    
    NSImage* _indeterminate_image;
    NSImageView* _indeterminate_view;
}

//- Initialisation ---------------------------------------------------------------------------------

@synthesize doubleValue = _double_value;
@synthesize indeterminate = _indeterminate;
@synthesize totalSize = _total_size;

- (id)initWithCoder:(NSCoder*)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _total_size = nil;
        _double_value = 0.0;
        _transfer_rate = 0.0;
        _data_points = [NSMutableArray array];
        _last_time = [NSDate timeIntervalSinceReferenceDate];
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
    [IA_RGB_COLOUR(216.0, 237.0, 243.0) set];
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
    
    if (_total_size == nil)
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
    
    NSTimeInterval time_remaining = [self timeRemaining];
    
    if (time_remaining <= 0.0)
        return;
    
    NSDictionary* text_style = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:9.0]
                                               paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                       colour:IA_RGB_COLOUR(150.0, 170.0, 184.0)
                                                       shadow:nil];
    
    NSString* time_remaining_str = [IAFunctions timeRemainingFrom:time_remaining];
    
    NSAttributedString* time_str = [[NSAttributedString alloc] initWithString:time_remaining_str
                                                                   attributes:text_style];
    
    NSPoint time_pt = NSMakePoint(self.bounds.origin.x + NSWidth(self.bounds) - time_str.size.width - 7.0,
                                  self.bounds.origin.y + 3.0);
    [time_str drawAtPoint:time_pt];
}

//- General Functions ------------------------------------------------------------------------------

- (NSTimeInterval)timeRemaining
{
    double avg_rate = 0.0;
    for (NSNumber* rate in _data_points)
    {
        avg_rate += rate.doubleValue / _data_points.count;
    }
    double data_remaining = (self.maxValue - _double_value) * _total_size.doubleValue;
    if (avg_rate > 0.0)
        return (data_remaining / avg_rate);
    else
        return 0.0;
}

- (void)setDoubleValue:(double)doubleValue
{
    NSTimeInterval current_time = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval time_interval = current_time - _last_time;
    double rate = (doubleValue - _double_value) / self.maxValue * _total_size.doubleValue / time_interval;
    if (_data_points.count < 30)
    {
        [_data_points addObject:[NSNumber numberWithDouble:rate]];
    }
    else
    {
        [_data_points removeObjectAtIndex:0];
        [_data_points addObject:[NSNumber numberWithDouble:rate]];
    }
    if (doubleValue > _double_value)
        _double_value = doubleValue;
    _last_time = current_time;
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
    if (flag)
    {
        CGFloat w_diff = NSWidth(self.bounds) - _indeterminate_image.size.width;
        CGFloat h_diff = NSHeight(self.bounds) - _indeterminate_image.size.height;
        NSRect centred_rect = NSMakeRect(self.bounds.origin.x + (w_diff / 2.0),
                                         self.bounds.origin.y + (h_diff / 2.0),
                                         _indeterminate_image.size.width,
                                         _indeterminate_image.size.height);
        if (_indeterminate_view == nil)
        {
            _indeterminate_view = [[NSImageView alloc] initWithFrame:centred_rect];
        }
        [self.superview addSubview:_indeterminate_view];
        [_indeterminate_view setFrameOrigin:NSMakePoint(40.0, 15.0)];
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
    
    return [super defaultAnimationForKey:key];
}

@end
