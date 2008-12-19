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

#import "PrefWindowController.h"
#import "LocationController.h"

@implementation PrefWindowController

- (id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
	return self;
}

- (void)windowDidLoad
{	
	[Table setDataSource:self];
}

- (id)tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	id result = @"";
	
	LocationValue *loc = [[[LocationController sharedInstance] allLocations] objectAtIndex:rowIndex];
	
	NSString *identifier = [aTableColumn identifier];
	
	if ([identifier isEqualToString:@"Location"])
	{
		NSString *strTitle = [loc getTitle];
		strTitle = [ strTitle copy];
		
		result = [strTitle autorelease];
	}
	else if ([identifier isEqualToString:@"Latitude"])
	{
		double dLat = [loc getLatValue];
		
		result = [NSNumber numberWithDouble:dLat];
	}
	else if ([identifier isEqualToString:@"Longitude"])
	{
		double dLong = [loc getLongValue];
		
		result = [NSNumber numberWithDouble:dLong];
	}
	else if ([identifier isEqualToString:@"TZ"])
	{
		NSString *strTimeZone = [loc getTimeZone];
		strTimeZone = [strTimeZone copy];
		
		result = [strTimeZone autorelease];
	}
	
	return result;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[[LocationController sharedInstance] allLocations] count];
}

- (IBAction)raiseAddWindow:(id)sender
{
	[Title setStringValue:@""];
	[Lat setStringValue:@""];
	[Long setStringValue:@""];
	[TimeZone setStringValue:@""];
	
	NSArray *tzItems = [NSTimeZone knownTimeZoneNames];
	
	[TimeZone addItemsWithObjectValues:tzItems];
	
	[NSApp beginSheet:addWindow modalForWindow:prefWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)endAddWindow:(id)sender
{
	[addWindow orderOut:sender];
	
	[NSApp endSheet:addWindow returnCode:1];
}

- (IBAction)cancelAddWindow:(id)sender
{
	[addWindow orderOut:sender];
	
	[NSApp endSheet:addWindow returnCode:0];	
}

- (IBAction)removeLocation:(id)sender
{
	NSEnumerator *enumerator = [Table selectedRowEnumerator];
	NSNumber *temp;
	if ((temp = [enumerator nextObject]) && temp != nil)
	{
		int row = [temp intValue];
		
		[[LocationController sharedInstance] removeLocationAtIndex:row];
		
		[Table reloadData];
	}	
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode)
	{
		NSString *title = [Title stringValue];
		
		double dLat = [Lat doubleValue];
		double dLong = [Long doubleValue];
		
		NSString *timezone = [TimeZone stringValue];
		
		[[LocationController sharedInstance] addLocation:title Lat:dLat Long:dLong TZ:timezone];
		
		[Table reloadData];
	}
}


@end
