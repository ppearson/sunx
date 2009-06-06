//
//  PrefWindow.m
//  SunX
//
//  Created by Peter Pearson on 04/06/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PrefWindow.h"


@implementation PrefWindow

- (void) keyDown: (NSEvent *) event
{
    if ([event keyCode] == 53) // esc key
        [self close];
    else
        [super keyDown: event];
}

- (void) close
{
    [self makeFirstResponder: nil]; // essentially saves pref changes on window close
    [super close];
}


@end
