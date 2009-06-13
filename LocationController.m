/* 
 * SunX:  A Sunrise/Sunset calculator for OS X.
 * Copyright (C) 2005-2007 Peter Pearson
 * You can view the complete license in the Licence.txt file in the root
 * of the source tree.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

#import "LocationController.h"

@implementation LocationController

static LocationController *sharedInstance = nil;
+ (LocationController *)sharedInstance
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init
{
    if (sharedInstance)
	{
        [self release];
	}
	else if (self = [super init])
	{
        sharedInstance = self;
        aLocations = [[NSMutableArray alloc] init];
    }
    return sharedInstance;
}

- (void)dealloc
{
    [aLocations release];
    [super dealloc];
}

- (NSArray *)allLocations
{
    return aLocations;
}

- (LocationValue *)locationWithTitle:(NSString *)title
{
    if ([self indexOfLocationWithTitle:title] == -1)
    {
        return nil;
    }
    else
	{
        return [aLocations objectAtIndex:[self indexOfLocationWithTitle:title]];
    }
}

- (LocationValue *)locationAtIndex:(int)index
{
    if (index >= 0 && index < [aLocations count])
    {
        return [aLocations objectAtIndex:index];
    }
	else
	{
        return nil;
    }
}

- (int)indexOfLocationWithTitle:(NSString *)title
{
    int i;
    for (i = 0; i < [aLocations count]; i++)
    {
        if ([title isEqualToString:[[aLocations objectAtIndex:i] getTitle]])
        {
            return i;
        }
    }

    return -1;
}

- (void)removeLocationAtIndex:(int)index
{
    LocationValue *remove = [aLocations objectAtIndex:index];
    
	[aLocations removeObject:remove];
}

- (void)addLocation:(NSString *)title Lat:(double)dLat Long:(double)dLong TZ:(NSString *)timezone
{
	LocationValue *loc1 = [[LocationValue alloc] autorelease];
	
	title = [title copy];
	[loc1 setTitle:title];
	[loc1 setLongValue:dLong];
	[loc1 setLatValue:dLat];
	
	timezone = [timezone copy];
	[loc1 setTimeZone:timezone];
				
	[aLocations addObject:loc1];
}


@end
