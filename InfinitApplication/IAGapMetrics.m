//
//  IAGapMetrics.m
//  InfinitApplication
//
//  Created by Christopher Crone on 5/31/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import "IAGapMetrics.h"
#import <Gap/gap.h>
#import <Gap/IAGapState.h>
#import <Gap/IAGapMetricsProtocol.h>

@implementation IAGapMetrics
{
@private
    gap_State* _state;
}

- (id)initWithState:(gap_State*)state
{
    if (self = [super init])
    {
        _state = state;
    }
    return self;
}

- (gap_Status)metrics_drop_favorite
{
    return gap_metrics_drop_favorite(_state);
}

- (gap_Status)metrics_drop_bar
{
    return gap_metrics_drop_bar(_state);
}

- (gap_Status)metrics_drop_user
{
    return gap_metrics_drop_user(_state);
}

- (gap_Status)metrics_click_self
{
    return gap_metrics_click_self(_state);
}

- (gap_Status)metrics_click_favorite
{
    return gap_metrics_click_favorite(_state);
}

- (gap_Status)metrics_click_searchbar
{
    return gap_metrics_click_searchbar(_state);
}

- (gap_Status)metrics_searchbar_focus
{
    return gap_metrics_searchbar_focus(_state);
}

- (gap_Status)metrics_transfer_favorite
{
    return gap_metrics_transfer_favorite(_state);
}

- (gap_Status)metrics_transfer_user
{
    return gap_metrics_transfer_user(_state);
}

- (gap_Status)metrics_transfer_email
{
    return gap_metrics_transfer_email(_state);
}

- (gap_Status)metrics_transfer_ghost
{
    return gap_metrics_transfer_ghost(_state);
}

- (gap_Status)metrics_panel_open:(NSString*)panel_id
{
    return gap_metrics_panel_open(_state, [panel_id UTF8String]);
}

- (gap_Status)metrics_panel_close:(NSString*)panel_id
{
    return gap_metrics_panel_close(_state, [panel_id UTF8String]);
}

- (gap_Status)metrics_panel_accept:(NSString*)panel_id
{
    return gap_metrics_panel_accept(_state, [panel_id UTF8String]);
}

- (gap_Status)metrics_panel_deny:(NSString*)panel_id
{
    return gap_metrics_panel_deny(_state, [panel_id UTF8String]);
}

- (gap_Status)metrics_panel_access:(NSString*)panel_id
{
    return gap_metrics_panel_access(_state, [panel_id UTF8String]);
}

- (gap_Status)metrics_panel_cancel:(NSString*)panel_id action_author:(NSString*)author
{
    return gap_metrics_panel_cancel(_state, [panel_id UTF8String], [author UTF8String]);
}

- (gap_Status)metrics_dropzone_open
{
    return gap_metrics_dropzone_open(_state);
}

- (gap_Status)metrics_dropzone_close
{
    return gap_metrics_dropzone_close(_state);
}

- (gap_Status)metrics_dropzone_removeitem
{
    return gap_metrics_dropzone_removeitem(_state);
}

- (gap_Status)metrics_dropzone_removeall
{
    return gap_metrics_dropzone_removeall(_state);
}

- (gap_Status)metrics_searchbar_share:(NSString*)method
{
    return gap_metrics_searchbar_share(_state, [method UTF8String]);
}

- (gap_Status)metrics_select_favorite:(NSString*)method
{
    return gap_metrics_select_favorite(_state, [method UTF8String]);
}

- (gap_Status)metrics_select_user:(NSString*)method
{
    return gap_metrics_select_user(_state, [method UTF8String]);
}

- (gap_Status)metrics_select_ghost:(NSString*)method
{
    return gap_metrics_select_ghost(_state, [method UTF8String]);
}

- (gap_Status)metrics_select_close:(NSString*)method
{
    return gap_metrics_select_close(_state, [method UTF8String]);
}

@end
