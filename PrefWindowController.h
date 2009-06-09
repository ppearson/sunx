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

#import <Cocoa/Cocoa.h>

@interface PrefWindowController : NSWindowController {

	NSUserDefaults * uDefaults;
    BOOL bHasLoaded;
    
    IBOutlet NSView * vGeneralView, * vPieView, * vGraphView, * vLocationsView;
	
	// General
	IBOutlet NSPopUpButton * fTwilightType;
	
	// Pie
	IBOutlet NSColorWell * fDayColourWell;
	IBOutlet NSColorWell * fNightColourWell;
	IBOutlet NSButton * fShowCurrentTimeCheck;
	IBOutlet NSColorWell * fCurrentTimeColourWell;
	IBOutlet NSButton * fShowTwilightCheck;
	IBOutlet NSColorWell * fTwilightColourWell;
	
	// Graph
	IBOutlet NSButton * fShowSunriseCheck;
	IBOutlet NSColorWell * fSunriseColourWell;
	IBOutlet NSButton * fShowSunsetCheck;
	IBOutlet NSColorWell * fSunsetColourWell;
	IBOutlet NSButton * fShowDayLengthCheck;
	IBOutlet NSColorWell * fDayLengthColourWell;
	IBOutlet NSButton * fShowCurrentTimeGCheck;
	IBOutlet NSColorWell * fCurrentTimeGColourWell;
	
	
	// Locations
	IBOutlet id Table;
	IBOutlet NSWindow *addWindow;
	IBOutlet NSWindow *prefWindow;
	IBOutlet id Long;
	IBOutlet id Lat;
	IBOutlet id Title;
	IBOutlet id TimeZone;
}

- (IBAction)raiseAddWindow:(id)sender;
- (IBAction)endAddWindow:(id)sender;
- (IBAction)cancelAddWindow:(id)sender;
- (IBAction)removeLocation:(id)sender;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)updateGeneralSettings:(id)sender;
- (void)updateGraphSettings:(id)sender;
- (void)updatePieSettings:(id)sender;
- (void)updateLocationsSettings:(id)sender;

@end
