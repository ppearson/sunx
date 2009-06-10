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

#import "MySun.h"
#include <math.h>
#import "LocationValue.h"
#import "LocationController.h"
#include "GraphView.h"

@implementation MySun

const double dMinutesInDay = 60.0 * 24.0;

- (id) init
{
    if ((self = [super init]))
    {        
        [NSApp setDelegate: self];
        
        prefController = [[PrefWindowController alloc] init];
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(handleSettingsChange:) name:@"GeneralSettingsUpdate" object:nil];
		[nc addObserver:self selector:@selector(handleLocationsChange:) name:@"LocationsSettingsUpdate" object:nil];
    }
    return self;
}

+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	// General
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"GeneralTwilightType"];
	[defaultValues setObject:[NSNumber numberWithInt:180] forKey:@"GraphDays"];
	[defaultValues setObject:[NSNumber numberWithInt:1] forKey:@"TimeType"];
	
	//  Pie
	NSData *colourData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor yellowColor]];
	[defaultValues setObject:colourData forKey:@"PieDayColour"];
	
	colourData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor blueColor]];
	[defaultValues setObject:colourData forKey:@"PieNightColour"];
	
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"PieShowCurrentTime"];
	colourData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor redColor]];
	[defaultValues setObject:colourData forKey:@"PieCurrentTimeColour"];
	
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"PieShowTwilight"];
	colourData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor orangeColor]];
	[defaultValues setObject:colourData forKey:@"PieTwilightColour"];
	
	// Graph
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"GraphShowSunrise"];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"GraphShowSunset"];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:@"GraphShowDayLength"];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"GraphShowCurrentTime"];
	
	colourData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor blueColor]];
	[defaultValues setObject:colourData forKey:@"GraphSunriseColour"];
	
	colourData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor yellowColor]];
	[defaultValues setObject:colourData forKey:@"GraphSunsetColour"];
	
	colourData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor redColor]];
	[defaultValues setObject:colourData forKey:@"GraphDayLengthColour"];
	
	colourData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor greenColor]];
	[defaultValues setObject:colourData forKey:@"GraphCurrentTimeColour"];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (void)awakeFromNib
{
	NSDate *today = [NSDate date];
	
	[Date1 setDateValue:today];
	
	[self loadPreferences];
	
	[TargetTime removeAllItems];
	[TargetTime addItemWithTitle:@"System Time"];
	[TargetTime addItemWithTitle:@"Location Time"];
	
	[TargetTime selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"TimeType"]];
	
	[drawer open];
	[Table setDelegate:self];
	
	[Table setDataSource:self];
	
	[Table reloadData];
	
	[Table selectRow:0 byExtendingSelection:FALSE];
	
	[self Calculate:self];
}

- (void)dealloc
{
	[prefController release];
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	
	[super dealloc];
}

- (id)tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	id result = @"";
	
	LocationValue *loc = [[[LocationController sharedInstance] allLocations] objectAtIndex:rowIndex];

	NSString *strTitle = [loc getTitle];
	strTitle = [strTitle copy];
		
	result = [strTitle autorelease];
	return result;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[[LocationController sharedInstance] allLocations] count];
}

- (IBAction)Calculate:(id)sender
{
	int nSel = [Table selectedRow];
	
	if (nSel < 0)
	{
		return;
	}
	
	LocationValue *loc = [[[LocationController sharedInstance] allLocations] objectAtIndex:nSel];
	
	double dLat = [loc getLatValue];
	double dLong = [loc getLongValue];
	
	int nSelTime = [TargetTime indexOfSelectedItem];
	
	NSString *strTimeZone;
	
	if (nSelTime == 0)
	{
		strTimeZone = [[NSTimeZone localTimeZone] name];
		[self setUseLocationTime:false];
	}
	else
	{
		strTimeZone = [loc getTimeZone];
		[self setUseLocationTime:true];
	}
	
	[self setTwilightType];
	
	NSDate *SelDate = [Date1 dateValue];
	NSCalendarDate *CalDate = [SelDate dateWithCalendarFormat:0 timeZone:0];
	
	int nYear = [CalDate yearOfCommonEra];
	int nMonth = [CalDate monthOfYear];
	int nDay = [CalDate dayOfMonth];
	
	NSString * strSunrise1;
	NSString * strSunset1;
	NSString * strDawn1;
	NSString * strDusk1;
	
	double dSunrise = [self CalcSun:nYear Month:nMonth Day:nDay Long:dLong Lat:dLat TZ:strTimeZone Sunrise:true Twilight:false Text:&strSunrise1];
	double dSunset = [self CalcSun:nYear Month:nMonth Day:nDay Long:dLong Lat:dLat TZ:strTimeZone Sunrise:false Twilight:false Text:&strSunset1];
	double dDawn = [self CalcSun:nYear Month:nMonth Day:nDay Long:dLong Lat:dLat TZ:strTimeZone Sunrise:true Twilight:true Text:&strDawn1];
	double dDusk = [self CalcSun:nYear Month:nMonth Day:nDay Long:dLong Lat:dLat TZ:strTimeZone Sunrise:false Twilight:true Text:&strDusk1];
	
	[AngleView setSunriseAngle:dSunrise];
	[AngleView setSunsetAngle:dSunset];
	[AngleView setDawnAngle:dDawn];
	[AngleView setDuskAngle:dDusk];
	
	[dawn setStringValue:strDawn1];
	[sunrise setStringValue:strSunrise1];
	[sunset setStringValue:strSunset1];
	[dusk setStringValue:strDusk1];
	
	// calculate current time position angle
	NSDate *today = [NSDate date];
	NSCalendarDate *CalDateToday = [today dateWithCalendarFormat:0 timeZone:[NSTimeZone timeZoneWithName:strTimeZone]];
	
	double dTimeGMT = [CalDateToday hourOfDay] * 60;
	dTimeGMT += [CalDateToday minuteOfHour];
	
	double dNowAngle = (1.0 / (dMinutesInDay / (dTimeGMT))) * 360.0;
	
	[AngleView setCurrentAngle:dNowAngle];
	[GraphView1 setCurrentAngle:dNowAngle];
	
	// calculate day length
	double dDay = dSunset - dSunrise;
	
	double dPerc = (dDay / 360.0);
	
	int nMinutesOfDaylight = dMinutesInDay * dPerc;
	
	int nHours = nMinutesOfDaylight / 60;
	int nMins = nMinutesOfDaylight % 60;
	
	NSString *strDayLength = @"";
	strDayLength = [NSString stringWithFormat:@"%ih %im", nHours, nMins];
	
	[dayLength setStringValue:strDayLength];
	
	[AngleView setNeedsDisplay:YES];
	
	[self UpdateDuration:self];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self Calculate:self];
}

- (IBAction)UpdateDuration:(id)sender
{
	NSDate *SelDate = [Date1 dateValue];
	NSCalendarDate *CalDate = [SelDate dateWithCalendarFormat:0 timeZone:0];
	
	int nSel = [Table selectedRow];
	
	if (nSel < 0)
	{
		return;
	}
	
	LocationValue *loc = [[[LocationController sharedInstance] allLocations] objectAtIndex:nSel];
	
	double dLat = [loc getLatValue];
	double dLong = [loc getLongValue];
	
	int nSelTime = [TargetTime indexOfSelectedItem];
	NSString *strTimeZone;
	
	if (nSelTime == 0)
	{
		strTimeZone = [[NSTimeZone localTimeZone] name];
		[self setUseLocationTime:false];
	}
	else
	{
		strTimeZone = [loc getTimeZone];
		[self setUseLocationTime:true];
	}
	
	int nNumDaysFuture = [Duration1 intValue];
	
	[self setGraphDays:nNumDaysFuture];
	
	[GraphView1 Reset:nNumDaysFuture];
	
	NSCalendarDate *nextDate = CalDate;
	
	int i = 0;
	
	for (i = 0; i < nNumDaysFuture; i++)
	{		
		nextDate = [CalDate dateByAddingYears:0 months:0 days:i hours:0 minutes:0 seconds:0];
		
		double dSunrise = [self CalcSunTimeAngle:nextDate Long:dLong Lat:dLat TZ:strTimeZone Sunrise:true Twilight:false];
		double dSunset = [self CalcSunTimeAngle:nextDate Long:dLong Lat:dLat TZ:strTimeZone Sunrise:false Twilight:false];
		
		GraphValue *value1 = [[GraphValue alloc] autorelease];
		[value1 setYValue:dSunrise];
		
		int nTag = -1;
		// find out if first day of month
		if ([nextDate dayOfMonth] == 1)
		{
			NSString *strMonthName = [nextDate descriptionWithCalendarFormat:@"%b" timeZone:[NSTimeZone localTimeZone] locale:nil];
			nTag = [GraphView1 addTag:strMonthName];
		}
		
		[value1 setXTag:nTag];
		
		[GraphView1 addSunriseValue:value1];
		
		GraphValue *value2 = [[GraphValue alloc] autorelease];
		[value2 setYValue:dSunset];
		
		[GraphView1 addSunsetValue:value2];
		
		double dDay = dSunset - dSunrise;
		
		double dPerc = (dDay / 360.0);
		
		GraphValue *value3 = [[GraphValue alloc] autorelease];
		[value3 setYValue:dPerc];
		
		[GraphView1 addDaylengthValue:value3];
	}
	
	[GraphView1 setNeedsDisplay:YES];
}

- (double) CalcSun:(int) nYear Month:(int) nMonth Day:(int) nDay Long:(double)dLong Lat:(double)dLat TZ:(NSString*)timezone
		   Sunrise:(bool)bSunrise Twilight:(bool)bTwilight Text:(NSString**)strText
{
	NSCalendarDate *newDate = [[[NSCalendarDate alloc] initWithYear:nYear month:nMonth day:nDay hour:0 minute:0 second:0 
														   timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]] autorelease];
	
	int nJulianDay = [newDate dayOfYear] + 1;
	
	double dGamma = [self CalcGamma:nJulianDay];
	double dEqTime = [self CalcEqOfTime:dGamma];
	double dSolarDec = [self CalcSolarDec:dGamma];
	
	double dHourAngle = [self CalcHourAngle:dLat SolarDec:dSolarDec Sunrise:bSunrise Twilight:bTwilight];
	double dDelta = -dLong - RadToDeg(dHourAngle);
	double dTimeDiff = 4.0 * dDelta;
	double dTimeGMT = 720.0 + dTimeDiff - dEqTime;
	
	double dGammaSunrise = [self CalcGamma2:nJulianDay Hour:(int)(dTimeGMT / 60)];
	dEqTime = [self CalcEqOfTime:dGammaSunrise];
	dSolarDec = [self CalcSolarDec:dGammaSunrise];
	
	NSTimeZone *pZone = [NSTimeZone timeZoneWithName:timezone];
	int nDiffSecs = [pZone secondsFromGMT];
	int nMinutes = nDiffSecs / 60;
	
	double dSunAngle = (1.0 / (dMinutesInDay / (dTimeGMT + nMinutes))) * 360.0;
   	
	NSCalendarDate *SunriseTime = [newDate dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 seconds:(dTimeGMT * 60)];
	
	NSString *DateString = @"";
	
	DateString = [SunriseTime descriptionWithCalendarFormat:@"%H:%M" timeZone:[NSTimeZone timeZoneWithName:timezone] locale:nil];
	
	*strText = DateString;
	
	return dSunAngle;
}

- (double) CalcSunTimeAngle:(NSCalendarDate*) Date Long:(double)dLong Lat:(double)dLat TZ:(NSString*)timezone Sunrise:(bool)bSunrise Twilight:(bool)bTwilight
{
	int nDay = [Date dayOfYear] + 1;
	
	double dGamma = [self CalcGamma:nDay];
	double dEqTime = [self CalcEqOfTime:dGamma];
	double dSolarDec = [self CalcSolarDec:dGamma];
	
	double dHourAngle = [self CalcHourAngle:dLat SolarDec:dSolarDec Sunrise:bSunrise Twilight:bTwilight];
	double dDelta = -dLong - RadToDeg(dHourAngle);
	double dTimeDiff = 4.0 * dDelta;
	double dTimeGMT = 720.0 + dTimeDiff - dEqTime;
	
	double dGammaSunrise = [self CalcGamma2:nDay Hour:(int)(dTimeGMT / 60)];
	dEqTime = [self CalcEqOfTime:dGammaSunrise];
	dSolarDec = [self CalcSolarDec:dGammaSunrise];

	NSTimeZone *pZone = [NSTimeZone timeZoneWithName:timezone];
	int nDiffSecs = [pZone secondsFromGMTForDate:Date];
	int nMinutes = nDiffSecs / 60;
	
	double dSunriseAngle = (1.0 / (dMinutesInDay / (dTimeGMT + nMinutes))) * 360.0;
	
	return dSunriseAngle;
}

double RadToDeg(double dAngle)
{
	double dNewAngle = 180.0 * dAngle / 3.1415926535;
		
	return dNewAngle;
}

double DegToRad(double dAngle)
{
	double dNewAngle = 3.1415926535 * dAngle / 180.0;
		
	return dNewAngle;
}

- (double) CalcGamma:(int)nJulianDay
{
	double dGamma = (2.0 * 3.1415926535 / 365.0) * (nJulianDay - 1);
		
	return dGamma;
}

- (double) CalcGamma2:(int)nJulianDay Hour:(int) nHour
{
	double dGamma2 = (2.0 * 3.1415926535 / 365.0) * (nJulianDay - 1 + (nHour / 24.0));
		
	return dGamma2;
}

- (double) CalcEqOfTime:(double) dGamma
{
	double dCalcEqOfTime = (229.18 * (0.000075 + 0.001868 * cos(dGamma) - 
				0.032077 * sin(dGamma) - 0.014615 * cos(2 * dGamma) - 0.040849 * sin(2 * dGamma)));
		
	return dCalcEqOfTime;
}

- (double) CalcSolarDec:(double) dGamma
{
	double dCalcSolarDec = (0.006918 - 0.399912 * cos(dGamma) + 0.070257 * 
				sin(dGamma) - 0.006758 * cos(2.0 * dGamma) + 0.000907 * sin(2.0 * dGamma));
		
	return dCalcSolarDec;
}

- (double) CalcHourAngle:(double) dLat SolarDec: (double) dSolarDec Sunrise:(bool) bSunrise Twilight:(bool) bTwilight
{
	double dLatRad = DegToRad(dLat);
	
	double dZenith = 90.833333;
	
	if (bTwilight)
	{
		dZenith = m_dTwilightZenith;
	}
	
	if (bSunrise)
	{
		return (acos(cos(DegToRad(dZenith)) / (cos(dLatRad) * cos(dSolarDec)) - tan(dLatRad) * tan(dSolarDec)));
	}
	else
	{
		return -(acos(cos(DegToRad(dZenith)) / (cos(dLatRad) * cos(dSolarDec)) - tan(dLatRad) * tan(dSolarDec)));
	}
}

- (double) CalcDayLength:(double) dHourAngle
{
	return (2.0 * abs(RadToDeg(dHourAngle))) / 15.0;
}

- (IBAction)ToggleDrawer:(id)sender
{
	[drawer toggle:sender];
}

////

- (IBAction)showPreferencesWindow:(id)sender
{
	NSWindow * window1 = [prefController window];
    if (![window1 isVisible])
        [window1 center];
	
    [window1 makeKeyAndOrderFront:self];
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
		m_GraphDays = 180;
		m_UseLocationTime = true;
		
		[[LocationController sharedInstance] addLocation:@"Poole" Lat:50.78 Long:-1.85 TZ:@"Europe/London"];
		[[LocationController sharedInstance] addLocation:@"London" Lat:51.51 Long:-0.12 TZ:@"Europe/London"];
		[[LocationController sharedInstance] addLocation:@"Paris" Lat:48.85 Long:2.36 TZ:@"Europe/Paris"];
		[[LocationController sharedInstance] addLocation:@"Berlin" Lat:52.52 Long:13.42 TZ:@"Europe/Berlin"];
		[[LocationController sharedInstance] addLocation:@"Madrid" Lat:40.38 Long:-3.71 TZ:@"Europe/Madrid"];
		[[LocationController sharedInstance] addLocation:@"Lisbon" Lat:38.77 Long:-9.13 TZ:@"Europe/Lisbon"];
		[[LocationController sharedInstance] addLocation:@"Rome" Lat:41.85 Long:12.33 TZ:@"Europe/Rome"];
		[[LocationController sharedInstance] addLocation:@"Oslo" Lat:59.95 Long:10.74 TZ:@"Europe/Oslo"];
		[[LocationController sharedInstance] addLocation:@"Moscow" Lat:55.78 Long:37.62 TZ:@"Europe/Moscow"];
		[[LocationController sharedInstance] addLocation:@"New York" Lat:40.7 Long:-74.17 TZ:@"America/New_York"];
		[[LocationController sharedInstance] addLocation:@"Los Angeles" Lat:34.05 Long:-118.25 TZ:@"America/Los_Angeles"];
		[[LocationController sharedInstance] addLocation:@"Toronto" Lat:43.67 Long:-79.6 TZ:@"America/Toronto"];
		[[LocationController sharedInstance] addLocation:@"Sydney" Lat:-33.86 Long:151.20 TZ:@"Australia/Sydney"];
		[[LocationController sharedInstance] addLocation:@"Auckland" Lat:-36.85 Long:174.78 TZ:@"Australia/Auckland"];
		[[LocationController sharedInstance] addLocation:@"Tokyo" Lat:35.68 Long:139.77 TZ:@"Asia/Tokyo"];
		[[LocationController sharedInstance] addLocation:@"Hong Kong" Lat:22.32 Long:113.92 TZ:@"Asia/Hong_Kong"];
		[[LocationController sharedInstance] addLocation:@"Cairo" Lat:30.06 Long:31.36 TZ:@"Africa/Cairo"];
		[[LocationController sharedInstance] addLocation:@"Nairobi" Lat:-1.28 Long:36.81 TZ:@"Africa/Nairobi"];
		[[LocationController sharedInstance] addLocation:@"Cape Town" Lat:-33.92 Long:18.42 TZ:@"Africa/Cape_Town"];
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

- (void)setTwilightType
{
	switch([[NSUserDefaults standardUserDefaults] integerForKey:@"GeneralTwilightType"])
	{
		case 1:
			m_dTwilightZenith = 102.0;
			break;
		case 0:
		default:
			m_dTwilightZenith = 96.0;
			break;
	}
}

- (void)handleSettingsChange:(NSNotification *)note
{
	[self Calculate:self];
}

- (void)handleLocationsChange:(NSNotification *)note
{
	[Table reloadData];
}

@end
