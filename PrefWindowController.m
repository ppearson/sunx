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

#define TOOLBAR_GENERAL     @"TOOLBAR_GENERAL"
#define TOOLBAR_PIE			@"TOOLBAR_PIE"
#define TOOLBAR_GRAPH		@"TOOLBAR_GRAPH"
#define TOOLBAR_LOCATIONS   @"TOOLBAR_LOCATIONS"

@interface PrefWindowController (Private)

- (void) setPrefView: (id) sender;

@end


@implementation PrefWindowController

- (id)init
{
	if (self = [super initWithWindowNibName:@"Preferences"])
	{
		uDefaults = [NSUserDefaults standardUserDefaults];
	}
	return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) awakeFromNib
{
    bHasLoaded = YES;
    
    NSToolbar * toolbar = [[NSToolbar alloc] initWithIdentifier: @"Preferences Toolbar"];
    [toolbar setDelegate: (id)self];
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode: NSToolbarSizeModeRegular];
    [toolbar setSelectedItemIdentifier: TOOLBAR_GENERAL];
    [[self window] setToolbar: toolbar];
    [toolbar release];
    
    [self setPrefView: nil];
	
	[fTwilightType removeAllItems];
	[fTwilightType addItemWithTitle:@"Civil"];
	[fTwilightType addItemWithTitle:@"Nautical"];
	
	[fTwilightType selectItemAtIndex:[uDefaults integerForKey: @"GeneralTwilightType"]];
}

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar itemForItemIdentifier: (NSString *) ident willBeInsertedIntoToolbar: (BOOL) flag
{
    NSToolbarItem * item = [[NSToolbarItem alloc] initWithItemIdentifier: ident];
	
    if ([ident isEqualToString: TOOLBAR_GENERAL])
    {
        [item setLabel: @"General"];
        [item setImage: [NSImage imageNamed: @"General.png"]];
        [item setTarget: self];
        [item setAction: @selector(setPrefView:)];
        [item setAutovalidates: NO];
    }
    else if ([ident isEqualToString: TOOLBAR_PIE])
    {
        [item setLabel: @"Pie"];
        [item setImage: [NSImage imageNamed: @"Pie.png"]];
        [item setTarget: self];
        [item setAction: @selector(setPrefView:)];
        [item setAutovalidates: NO];
    }
    else if ([ident isEqualToString: TOOLBAR_GRAPH])
    {
        [item setLabel: @"Graph"];
        [item setImage: [NSImage imageNamed: @"Graph.png"]];
        [item setTarget: self];
        [item setAction: @selector(setPrefView:)];
        [item setAutovalidates: NO];
    }
    else if ([ident isEqualToString: TOOLBAR_LOCATIONS])
    {
        [item setLabel: @"Locations"];
        [item setImage: [NSImage imageNamed: @"Locations.png"]];
        [item setTarget: self];
        [item setAction: @selector(setPrefView:)];
        [item setAutovalidates: NO];
    }
	else
    {
        [item release];
        return nil;
    }
	
    return [item autorelease];
}

- (NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar
{
    return [self toolbarDefaultItemIdentifiers: toolbar];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [self toolbarAllowedItemIdentifiers: toolbar];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects: TOOLBAR_GENERAL, TOOLBAR_PIE, TOOLBAR_GRAPH, TOOLBAR_LOCATIONS, nil];
}

- (void)windowDidLoad
{	
	[Table setDataSource:(id)self];
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
	NSArray *sortedTimeZones = [tzItems sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	
	[TimeZone addItemsWithObjectValues:sortedTimeZones];
	
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
    int row = [Table selectedRow];
    
    if (row != -1)
    {
        [[LocationController sharedInstance] removeLocationAtIndex:row];
        
        [Table reloadData];
        [self updateLocationsSettings:self];
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
		[self updateLocationsSettings:self];
	}
}

- (void)updateGeneralSettings:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"GeneralSettingsUpdate" object:self];
}

- (void)updateGraphSettings:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"GraphSettingsUpdate" object:self];
}

- (void)updatePieSettings:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"PieSettingsUpdate" object:self];
}

- (void)updateLocationsSettings:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"LocationsSettingsUpdate" object:self];
}

@end

@implementation PrefWindowController (Private)

- (void) setPrefView: (id) sender
{
    NSString * identifier;
    if (sender)
    {
        identifier = [sender itemIdentifier];
        [[NSUserDefaults standardUserDefaults] setObject: identifier forKey: @"SelectedPrefView"];
    }
    else
        identifier = [[NSUserDefaults standardUserDefaults] stringForKey: @"SelectedPrefView"];
    
    NSView * view;
    if ([identifier isEqualToString: TOOLBAR_PIE])
        view = vPieView;
    else if ([identifier isEqualToString: TOOLBAR_GRAPH])
        view = vGraphView;
    else if ([identifier isEqualToString: TOOLBAR_LOCATIONS])
        view = vLocationsView;
	else
    {
        identifier = TOOLBAR_GENERAL; // general view is the default selected
        view = vGeneralView;
    }
    
    [[[self window] toolbar] setSelectedItemIdentifier: identifier];
    
    NSWindow * window = [self window];
    if ([window contentView] == view)
        return;
    
    NSRect windowRect = [window frame];
    float difference = ([view frame].size.height - [[window contentView] frame].size.height) * [window backingScaleFactor];
    windowRect.origin.y -= difference;
    windowRect.size.height += difference;
    
    [view setHidden: YES];
    [window setContentView: view];
    [window setFrame: windowRect display: YES animate: YES];
    [view setHidden: NO];
    
    //set title label
    if (sender)
        [window setTitle: [sender label]];
    else
    {
        NSToolbar * toolbar = [window toolbar];
        NSString * itemIdentifier = [toolbar selectedItemIdentifier];
		int items = [[toolbar items] count];
		int i = 0;
        for (i = 0; i < items; i++)
		{
			NSToolbarItem * item = [[toolbar items] objectAtIndex:i];
            if ([[item itemIdentifier] isEqualToString: itemIdentifier])
            {
                [window setTitle: [item label]];
                break;
            }
		}
    }
}


@end
