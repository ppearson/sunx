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
#import "AppController.h"
#include "GraphView.h"

@implementation MySun

- (void)awakeFromNib
{
	NSDate *today = [NSDate date];
	
	[Date1 setDateValue:today];
	
	[[AppController sharedInstance] loadPreferences];
	
	[TargetTime removeAllItems];
	[TargetTime addItemWithTitle:@"System Time"];
	[TargetTime addItemWithTitle:@"Location Time"];
	
	[Location setDataSource:[LocationController sharedInstance]];
	
	int nLocs = [[[LocationController sharedInstance] allLocations] count];
	
	if (nLocs > 12)
		nLocs = 12;
	
	[Location setNumberOfVisibleItems:nLocs];	
	[Location selectItemAtIndex:0];
	
	[self Calculate:self];
}

- (IBAction)Calculate:(id)sender
{
	int nSel = [Location indexOfSelectedItem];
	
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
	}
	else
	{
		strTimeZone = [loc getTimeZone];
	}
	
	NSDate *SelDate = [Date1 dateValue];
	NSCalendarDate *CalDate = [SelDate dateWithCalendarFormat:0 timeZone:0];
	
	int nYear = [CalDate yearOfCommonEra];
	int nMonth = [CalDate monthOfYear];
	int nDay = [CalDate dayOfMonth];
	
	NSString * strSunrise1 = [self CalcSunrise:nYear Month:nMonth Day:nDay Long:dLong Lat:dLat TZ:strTimeZone];
	NSString * strSunset1 = [self CalcSunset:nYear Month:nMonth Day:nDay Long:dLong Lat:dLat TZ:strTimeZone];
	
	// calculate current time position angle
	NSDate *today = [NSDate date];
	NSCalendarDate *CalDateToday = [today dateWithCalendarFormat:0 timeZone:[NSTimeZone timeZoneWithName:strTimeZone]];
	
	double dTimeGMT = [CalDateToday hourOfDay] * 60;
	dTimeGMT += [CalDateToday minuteOfHour];
	
	double dMinutesInDay = 60.0 * 24.0;
	double dNowAngle = (1.0 / (dMinutesInDay / (dTimeGMT))) * 360.0;
	
	[AngleView setCurrentAngle:dNowAngle];
	
	[GraphView1 setCurrentAngle:dNowAngle];
	
	// calculate day length
	
	double dSunrise = [AngleView getSunriseAngle];
	double dSunset = [AngleView getSunsetAngle];
	
	double dDay = dSunset - dSunrise;
	
	double dPerc = (dDay / 360.0);
	
	int nMinutesOfDaylight = dMinutesInDay * dPerc;
	
	int nHours = nMinutesOfDaylight / 60;
	int nMins = nMinutesOfDaylight % 60;
	
	NSString *strDayLength = @"";
	strDayLength = [NSString stringWithFormat:@"%ih %im", nHours, nMins];
	
	[AngleView setDayLength:strDayLength];	
	[AngleView setSunriseTime:strSunrise1];
	[AngleView setSunsetTime:strSunset1];
	
	[self UpdateDuration:self];
}

- (IBAction)UpdateLocation:(id)sender
{	
/*	int nSel = [Location indexOfSelectedItem];
	
	if (nSel < 0)
	{
		return;
	}
	
	LocationValue *loc = [[[LocationController sharedInstance] allLocations] objectAtIndex:nSel];
	
	NSString *strTitle = [loc getTitle];
	[Location setTitle:strTitle];*/
}

- (IBAction)UpdateDuration:(id)sender
{
	NSDate *SelDate = [Date1 dateValue];
	NSCalendarDate *CalDate = [SelDate dateWithCalendarFormat:0 timeZone:0];
	
	int nSel = [Location indexOfSelectedItem];
	
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
	}
	else
	{
		strTimeZone = [loc getTimeZone];
	}
	
	int nNumDaysFuture = [Duration1 intValue];
	
	[GraphView1 Reset:nNumDaysFuture];
	
	NSCalendarDate *nextDate = CalDate;
	
	int i = 0;
	
	for (i = 0; i < nNumDaysFuture; i++)
	{		
		nextDate = [CalDate dateByAddingYears:0 months:0 days:i hours:0 minutes:0 seconds:0];
		
		double dSunrise = [self CalcSunriseTimeAngle:nextDate Long:dLong Lat:dLat TZ:strTimeZone];
		double dSunset = [self CalcSunsetTimeAngle:nextDate Long:dLong Lat:dLat TZ:strTimeZone];
		
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
		
		//
		
		double dDay = dSunset - dSunrise;
		
		double dPerc = (dDay / 360.0);
		
		GraphValue *value3 = [[GraphValue alloc] autorelease];
		[value3 setYValue:dPerc];
		
		[GraphView1 addDaylengthValue:value3];
	}
	
	[GraphView1 setNeedsDisplay:YES];
	
}

- (NSString*) CalcSunrise:(int) nYear Month:(int) nMonth Day:(int)nDay Long:(double)dLong Lat:(double)dLat TZ:(NSString*)timezone
{
	NSCalendarDate *newDate = [NSCalendarDate dateWithYear:nYear month:nMonth day:nDay hour:0
									minute:0 second:0 timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];

	int nJulianDay = [newDate dayOfYear];	
		
	double dGamma = [self CalcGamma:nJulianDay];
	double dEqTime = [self CalcEqOfTime:dGamma];
	double dSolarDec = [self CalcSolarDec:dGamma];

	double dHourAngle = [self CalcHourAngle:dLat SolarDec:dSolarDec Time:true];
	double dDelta = dLong - RadToDeg(dHourAngle);
	double dTimeDiff = 4 * dDelta;
	double dTimeGMT = 720 + dTimeDiff - dEqTime;
	
	double dGammaSunrise = [self CalcGamma2:nJulianDay Hour:(int)(dTimeGMT / 60)];
	dEqTime = [self CalcEqOfTime:dGammaSunrise];
	dSolarDec = [self CalcSolarDec:dGammaSunrise];

	dHourAngle = [self CalcHourAngle:dLat SolarDec:dSolarDec Time:true];
	dDelta = -dLong - RadToDeg(dHourAngle);
	dTimeDiff = 4 * dDelta;
	dTimeGMT = 720 + dTimeDiff - dEqTime;
	
	NSTimeZone *pZone = [NSTimeZone timeZoneWithName:timezone];
	int nDiffSecs = [pZone secondsFromGMT];
	int nMinutes = nDiffSecs / 60;
	
	double dMinutesInDay = 60.0 * 24.0;
	double dSunriseAngle = (1.0 / (dMinutesInDay / (dTimeGMT + nMinutes))) * 360.0;
	
	[AngleView setSunriseAngle:dSunriseAngle];
	[AngleView setNeedsDisplay:YES];
   	
	NSCalendarDate *SunriseTime = [newDate dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 seconds:(dTimeGMT * 60)];
	    
	NSString *DateString = @"";
	
	DateString = [SunriseTime descriptionWithCalendarFormat:@"%H:%M" timeZone:[NSTimeZone timeZoneWithName:timezone] locale:nil];
	
	return DateString;
}

- (double) CalcSunriseTimeAngle:(NSCalendarDate*)Date Long:(double)dLong Lat:(double)dLat TZ:(NSString*)timezone
{
	int nDay = [Date dayOfYear];
	
	double dGamma = [self CalcGamma:nDay];
	double dEqTime = [self CalcEqOfTime:dGamma];
	double dSolarDec = [self CalcSolarDec:dGamma];
	
	double dHourAngle = [self CalcHourAngle:dLat SolarDec:dSolarDec Time:true];
	double dDelta = dLong - RadToDeg(dHourAngle);
	double dTimeDiff = 4 * dDelta;
	double dTimeGMT = 720 + dTimeDiff - dEqTime;
	
	double dGammaSunrise = [self CalcGamma2:nDay Hour:(int)(dTimeGMT / 60)];
	dEqTime = [self CalcEqOfTime:dGammaSunrise];
	dSolarDec = [self CalcSolarDec:dGammaSunrise];
	
	dHourAngle = [self CalcHourAngle:dLat SolarDec:dSolarDec Time:true];
	dDelta = -dLong - RadToDeg(dHourAngle);
	dTimeDiff = 4 * dDelta;
	dTimeGMT = 720 + dTimeDiff - dEqTime;
	
	NSTimeZone *pZone = [NSTimeZone timeZoneWithName:timezone];
	int nDiffSecs = [pZone secondsFromGMTForDate:Date];
	int nMinutes = nDiffSecs / 60;
	
	double dMinutesInDay = 60.0 * 24.0;
	double dSunriseAngle = (1.0 / (dMinutesInDay / (dTimeGMT + nMinutes))) * 360.0;
	
	return dSunriseAngle;
}

- (double) CalcSunsetTimeAngle:(NSCalendarDate*)Date Long:(double)dLong Lat:(double)dLat TZ:(NSString*)timezone
{
	int nDay = [Date dayOfYear];
	
	double dGamma = [self CalcGamma:nDay + 1];
	double dEqTime = [self CalcEqOfTime:dGamma];
	double dSolarDec = [self CalcSolarDec:dGamma];
	
	double dHourAngle = [self CalcHourAngle:dLat SolarDec:dSolarDec Time:false];
	double dDelta = -dLong - RadToDeg(dHourAngle);
	double dTimeDiff = 4 * dDelta;
	double dTimeGMT = 720 + dTimeDiff - dEqTime;
	
	double dGammaSunrise = [self CalcGamma2:nDay Hour:(int)(dTimeGMT / 60)];
	dEqTime = [self CalcEqOfTime:dGammaSunrise];
	dSolarDec = [self CalcSolarDec:dGammaSunrise];
	
	dHourAngle = [self CalcHourAngle:dLat SolarDec:dSolarDec Time:false];
	dDelta = -dLong - RadToDeg(dHourAngle);
	dTimeDiff = 4 * dDelta;
	dTimeGMT = 720 + dTimeDiff - dEqTime;
	
	NSTimeZone *pZone = [NSTimeZone timeZoneWithName:timezone];
	int nDiffSecs = [pZone secondsFromGMTForDate:Date];
	int nMinutes = nDiffSecs / 60;
	
	double dMinutesInDay = 60.0 * 24.0;
	double dSunsetAngle = (1.0 / (dMinutesInDay / (dTimeGMT + nMinutes))) * 360.0;
	
	return dSunsetAngle;
}

- (NSString*) CalcSunset:(int)nYear Month:(int)nMonth Day:(int)nDay Long:(double)dLong Lat:(double)dLat TZ:(NSString*)timezone
{
	NSCalendarDate *newDate = [[[NSCalendarDate alloc] initWithYear:nYear 
    month:nMonth day:nDay hour:0 minute:0 second:0 
    timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]] autorelease];

	int nJulianDay = [newDate dayOfYear];

	double dGamma = [self CalcGamma:nJulianDay + 1];
	double dEqTime = [self CalcEqOfTime:dGamma];
	double dSolarDec = [self CalcSolarDec:dGamma];

	double dHourAngle = [self CalcHourAngle:dLat SolarDec:dSolarDec Time:false];
	double dDelta = -dLong - RadToDeg(dHourAngle);
	double dTimeDiff = 4 * dDelta;
	double dTimeGMT = 720 + dTimeDiff - dEqTime;
	
	double dGammaSunrise = [self CalcGamma2:nJulianDay Hour:(int)(dTimeGMT / 60)];
	dEqTime = [self CalcEqOfTime:dGammaSunrise];
	dSolarDec = [self CalcSolarDec:dGammaSunrise];

	dHourAngle = [self CalcHourAngle:dLat SolarDec:dSolarDec Time:false];
	dDelta = -dLong - RadToDeg(dHourAngle);
	dTimeDiff = 4 * dDelta;
	dTimeGMT = 720 + dTimeDiff - dEqTime;
	
	NSTimeZone *pZone = [NSTimeZone timeZoneWithName:timezone];
	int nDiffSecs = [pZone secondsFromGMT];
	int nMinutes = nDiffSecs / 60;
	
	double dMinutesInDay = 60.0 * 24.0;
	double dSunsetAngle = (1.0 / (dMinutesInDay / (dTimeGMT + nMinutes))) * 360.0;
	
	[AngleView setSunsetAngle:dSunsetAngle];
	[AngleView setNeedsDisplay:YES];
   	
	NSCalendarDate *SunriseTime = [newDate dateByAddingYears:0 months:0 
    days:0 hours:0 minutes:0 seconds:(dTimeGMT * 60)];
	    
	NSString *DateString = @"";
	
	DateString = [SunriseTime descriptionWithCalendarFormat:@"%H:%M" timeZone:[NSTimeZone timeZoneWithName:timezone] locale:nil];
	
	return DateString;
}

double RadToDeg(double dAngle)
{
	double dNewAngle = 180 * dAngle / 3.1415926535;
		
	return dNewAngle;
}

double DegToRad(double dAngle)
{
	double dNewAngle = 3.1415926535 * dAngle / 180;
		
	return dNewAngle;
}

- (double) CalcGamma:(int)nJulianDay
{
	double dGamma = (2.0 * 3.1415926535 / 365.0) * (nJulianDay - 1);
		
	return dGamma;
}

- (double) CalcGamma2:(int)nJulianDay Hour:(int) nHour
{
	double dGamma2 = (2.0 * 3.1415926535 / 365.0) * (nJulianDay - 1 + (nHour / 24));
		
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
				sin(dGamma) - 0.006758 * cos(2 * dGamma) + 0.000907 * sin(2 * dGamma));
		
	return dCalcSolarDec;
}

- (double) CalcHourAngle:(double) dLat SolarDec: (double) dSolarDec Time:(bool) bTime
{
	double dLatRad = DegToRad(dLat);
		
	if (bTime)
	{
		return (acos(cos(DegToRad(90.833)) / (cos(dLatRad) * cos(dSolarDec)) - tan(dLatRad) * tan(dSolarDec)));
	}
	else
	{
		return -(acos(cos(DegToRad(90.833)) / (cos(dLatRad) * cos(dSolarDec)) - tan(dLatRad) * tan(dSolarDec)));
	}
}

- (double) CalcDayLength:(double) dHourAngle
{
	return (2 * abs(RadToDeg(dHourAngle))) / 15;
}

@end
