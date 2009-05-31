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

#import "AppController.h"
#import "PrefWindowController.h"
#import "LocationController.h"

@implementation AppController

static AppController *sharedInstance = nil;
+ (AppController *)sharedInstance
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
    }
    return sharedInstance;
}

- (IBAction)openPreferencesWindow:(id)sender
{
	if (!prefWindowController)
	{
		prefWindowController = [[PrefWindowController alloc] init];
	}
	
	[prefWindowController showWindow:self];
}

- (void)dealloc
{
	[prefWindowController release];
	[super dealloc];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app
{
	[self writePreferences];
	return NSTerminateNow;
}

- (void)writePreferences
{
	NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
	
	NSMutableArray *tempLocs;
	tempLocs = [NSMutableArray array];
	
	NSArray *locations = [[LocationController sharedInstance] allLocations];
	
	int i = 0;
	for (i =  0; i < [locations count]; i++)
	{
		LocationValue *loc = [locations objectAtIndex:i];
		NSString *strTitle = [loc getTitle];
		strTitle = [strTitle copy];
		double dLat = [loc getLatValue];
		double dLong = [loc getLongValue];
		
		NSNumber *Lat;
		Lat = [NSNumber numberWithDouble: dLat];
		NSNumber *Long;
		Long = [NSNumber numberWithDouble: dLong];
		
		NSString *strTimeZone = [loc getTimeZone];
		strTimeZone = [strTimeZone copy];
		
		NSDictionary *tempValue = [NSDictionary dictionaryWithObjectsAndKeys:strTitle, @"title", Lat, @"lat", Long, @"long", strTimeZone, @"tz", nil];
		
		[tempLocs addObject:tempValue];
	}
	
    [prefs setObject:tempLocs forKey:@"Locations"];
	
	NSNumber *graphDays;
	graphDays = [NSNumber numberWithInt:m_GraphDays];
	
	[prefs setObject:graphDays forKey:@"GraphDays"];
	
	NSNumber *locationTime;
	locationTime = [NSNumber numberWithBool:m_UseLocationTime];
	
	[prefs setObject:locationTime forKey:@"LocationTime"];	
    
	if ([prefs writeToFile:[@"~/Library/Preferences/SunX.plist" stringByExpandingTildeInPath] atomically: TRUE] == NO)
	{
	
	}
}

- (void)loadPreferences
{
	NSDictionary *prefs;
    
    prefs = [NSDictionary dictionaryWithContentsOfFile: [@"~/Library/Preferences/SunX.plist" stringByExpandingTildeInPath]];
	
    if (prefs)
	{
		NSNumber *graphDays;
		graphDays = [prefs objectForKey:@"GraphDays"];
		if (graphDays)
		{
			m_GraphDays = [graphDays intValue];
		}
		else
		{
			m_GraphDays = 90;
		}
		
		NSNumber *locationTime;
		locationTime = [prefs objectForKey:@"LocationTime"];
		if (locationTime)
		{
			m_UseLocationTime = [locationTime boolValue];
		}
		else
		{
			m_UseLocationTime = true;
		}
		
		NSArray *tempLocs;
		tempLocs = [[prefs objectForKey:@"Locations"] retain];
		
		int i = 0;
		for (i = 0; i < [tempLocs count]; i++)
		{
			NSDictionary *loc = [tempLocs objectAtIndex:i];
			NSString *strTitle = [loc objectForKey:@"title"];
			double dLat = [[loc objectForKey:@"lat"] doubleValue];
			double dLong = [[loc objectForKey:@"long"] doubleValue];
			NSString *strTimeZone = [loc objectForKey:@"tz"];
			
			[[LocationController sharedInstance] addLocation:strTitle Lat:dLat Long:dLong TZ:strTimeZone];
		}
    }
	else
	{
		[[LocationController sharedInstance] addLocation:@"Poole" Lat:50.78 Long:-1.85 TZ:@"Europe/London"];
		[[LocationController sharedInstance] addLocation:@"London" Lat:51.52 Long:-0.1 TZ:@"Europe/London"];
		[[LocationController sharedInstance] addLocation:@"Paris" Lat:48.72 Long:2.38 TZ:@"Europe/Paris"];
		[[LocationController sharedInstance] addLocation:@"Berlin" Lat:52.52 Long:13.42 TZ:@"Europe/Berlin"];
		[[LocationController sharedInstance] addLocation:@"Madrid" Lat:40.5 Long:-3.58 TZ:@"Europe/Madrid"];
		[[LocationController sharedInstance] addLocation:@"Rome" Lat:41.8 Long:12.23 TZ:@"Europe/Rome"];
		[[LocationController sharedInstance] addLocation:@"Oslo" Lat:59.95 Long:10.72 TZ:@"Europe/Oslo"];
		[[LocationController sharedInstance] addLocation:@"New York" Lat:40.7 Long:-74.17 TZ:@"America/New_York"];
		[[LocationController sharedInstance] addLocation:@"Los Angeles" Lat:33.93 Long:-118.4 TZ:@"America/Los_Angeles"];
		[[LocationController sharedInstance] addLocation:@"Toronto" Lat:43.67 Long:-79.6 TZ:@"America/Toronto"];
		[[LocationController sharedInstance] addLocation:@"Sydney" Lat:-33.95 Long:151.18 TZ:@"Australia/Sydney"];
		[[LocationController sharedInstance] addLocation:@"Hong Kong" Lat:22.32 Long:113.92 TZ:@"Asia/Hong_Kong"];
		[[LocationController sharedInstance] addLocation:@"Cairo" Lat:30.13 Long:31.4 TZ:@"Africa/Cairo"];
		[[LocationController sharedInstance] addLocation:@"Nairobi" Lat:-0.27 Long:36.1 TZ:@"Africa/Nairobi"];
    }	
}

- (int)getGraphDays
{
	return m_GraphDays;
}

- (void)setGraphDays:(int)days
{
	m_GraphDays = days;
}

- (bool)getUseLocationTime;
{
	return m_UseLocationTime;
}

- (void)setUseLocationTime:(bool)locationTime
{
	m_UseLocationTime = locationTime;
}

@end
