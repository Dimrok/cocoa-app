//
//  IANotificationListCellView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 8/9/13.
//  Copyright (c) 2013 Infinit. All rights reserved.
//

#import "IANotificationListCellView.h"

#import "IAAvatarManager.h"

@implementation IANotificationListCellView

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
    }
    
    return self;
}

- (NSString*)description
{
    return @"[NotificationListCell]";
}

//- Setup Cell -------------------------------------------------------------------------------------

- (void)setUserFullName:(NSString*)fullname
{
    NSDictionary* attrs = [IAFunctions textStyleWithFont:[NSFont boldSystemFontOfSize:12.0]
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:TH_RGBCOLOR(29.0, 29.0, 29.0)
                                                  shadow:nil];
    self.user_full_name.attributedStringValue = [[NSAttributedString alloc] initWithString:fullname
                                                                                attributes:attrs];
}

- (void)setFileName:(NSString*)file_name
{
    NSDictionary* attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:11.0]
                                          paragraphStyle:[NSParagraphStyle defaultParagraphStyle]
                                                  colour:TH_RGBCOLOR(153.0, 153.0, 153.0)
                                                  shadow:nil];
    NSString* res = file_name;
    NSInteger str_len = 25;
    if (res.length > str_len)
    {
        NSString* file_extension = [file_name pathExtension];
        NSString* temp = [[file_name stringByDeletingPathExtension]
                          substringToIndex:(str_len - file_extension.length)];
        res = [temp stringByAppendingFormat:@"...%@", file_extension];
    }
    self.file_name.attributedStringValue = [[NSAttributedString alloc] initWithString:res
                                                                           attributes:attrs];
}

- (BOOL)isToday:(NSDate*)date
{
    NSDate* today = [NSDate date];
    NSInteger components = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
    NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* today_components = [gregorian components:components
                                                      fromDate:today];
    NSDateComponents* date_components = [gregorian components:components
                                                     fromDate:date];
    if ([date_components isEqual:today_components])
        return YES;
    else
        return NO;
}

- (void)setLastActionTime:(NSTimeInterval)timestamp
{
    NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSRightTextAlignment;
    NSDictionary* attrs = [IAFunctions textStyleWithFont:[NSFont systemFontOfSize:10.0]
                                          paragraphStyle:para
                                                  colour:TH_RGBCOLOR(206.0, 206.0, 206.0)
                                                  shadow:nil];
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale currentLocale];
    
    if ([self isToday:date])
        formatter.timeStyle = NSDateFormatterShortStyle;
    else
        formatter.dateStyle = NSDateFormatterShortStyle;
    
    self.time_since_change.attributedStringValue = [[NSAttributedString alloc]
                                                    initWithString:[formatter stringFromDate:date]
                                                        attributes:attrs];
}

- (void)setAvatarForUser:(IAUser*)user
{
    NSImage* avatar = [IAFunctions makeRoundAvatar:[IAAvatarManager getAvatarForUser:user
                                                                     andLoadIfNeeded:YES]
                                          ofDiameter:48.0
                                   withWhiteBorder:YES];
    [self.avatar setWantsLayer:YES];
    self.avatar.layer.shadowOffset = NSZeroSize;
    self.avatar.layer.shadowRadius = 1.0;
    self.avatar.layer.shadowOpacity = 0.25;
    self.avatar.image = avatar;
}

- (void)setupCellWithTransaction:(IATransaction*)transaction
{
    if (transaction.from_me)
    {
        [self setUserFullName:transaction.recipient_fullname];
        [self setAvatarForUser:[IAUser userWithId:transaction.recipient_id]];
    }
    else
    {
        [self setUserFullName:transaction.sender_fullname];
        [self setAvatarForUser:[IAUser userWithId:transaction.sender_id]];
    }
    [self setFileName:transaction.first_filename];
    [self setLastActionTime:transaction.timestamp];
}

@end
