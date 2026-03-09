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

#import "GraphView.h"
#import "GraphValue.h"

@implementation GraphView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		aGraphValues = [[NSMutableArray alloc] init];
		
		aTags = [[NSMutableArray alloc] init];
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(handleSettingsChange:) name:@"GraphSettingsUpdate" object:nil];
	}
	return self;
}

- (void)dealloc
{
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	
	[aGraphValues removeAllObjects];
	[aTags removeAllObjects];
	
	[aGraphValues release];
	[aTags release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	NSRect bounds = [self bounds];
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:bounds];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:bounds];
	
	double dMarginX = 25;
	double dMarginY = 12;
	
	NSRect innerBounds = NSInsetRect(bounds, dMarginX, dMarginY);
	NSRect plotArea = NSOffsetRect(innerBounds, (dMarginX/2), (dMarginY/2));
	
	[[NSColor blackColor] set];
	
	[NSBezierPath strokeRect:plotArea];
	
	double dLeftStart = plotArea.origin.x;
	
	NSBezierPath* pathSR = [NSBezierPath bezierPath];
	NSBezierPath* pathSS = [NSBezierPath bezierPath];
	NSBezierPath* pathDL = [NSBezierPath bezierPath];
	
	int nNumValues = [self graphValuesCount];
	if (nNumValues < 1)
	{
		return;
	}
	
	if (nDaysToShow < nNumValues)
	{
		nNumValues = nDaysToShow;
	}
	
	double dInc = plotArea.size.width / nNumValues;
	
	/////
	
	double dMaxY = 0.0;
	double dMinY = 360.0;
	
	int k = 0;
	for (k = 0; k < nNumValues; k++)
	{
		GraphValue *pGraphVal = [self getGraphValue:k];
		double dSRVal = [pGraphVal getSunriseValue];
		double dSSVal = [pGraphVal getSunsetValue];
		
		if (dSRVal < dMinY && !isnan(dSRVal))
			dMinY = dSRVal;
		
		if (dSRVal > dMaxY)
			dMaxY = dSRVal;
		
		if (dSSVal < dMinY && !isnan(dSSVal))
			dMinY = dSSVal;
		
		if (dSSVal > dMaxY)
			dMaxY = dSSVal;
	}
	
	// 
	
	dMaxY += 1.0;
	dMinY -= 1.0;
	
	double dYRange = dMaxY - dMinY;
	
	double dYScale = plotArea.size.height / dYRange;
	
	NSDate *today = [NSDate date];
	NSCalendarDate *CalDate = [today dateWithCalendarFormat:0 timeZone:0];
	
	///// draw Y axis grid
	
	int nStartHour = dMinY + 15 - ((int)dMinY % 15);

	for (k = nStartHour; k < (int)dMaxY; k += 15)
	{
		int nHour = k / 15;
		
		NSCalendarDate *newDate = [NSCalendarDate dateWithYear:[CalDate yearOfCommonEra] month:[CalDate monthOfYear] day:[CalDate monthOfYear] hour:nHour
														minute:0 second:0 timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
		
		NSString *strTime = [newDate descriptionWithCalendarFormat:@"%H:%M" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
		
		NSBezierPath* YLine = [NSBezierPath bezierPath];
		
		double dYValue = (k * dYScale) - (dMinY * dYScale) + (dMarginY * 1.5);
		[YLine moveToPoint:NSMakePoint(plotArea.origin.x, dYValue)];
		[YLine lineToPoint:NSMakePoint((plotArea.origin.x + plotArea.size.width), dYValue)];
		
		[[NSColor grayColor] set];
		[YLine stroke];
		
		NSMutableDictionary *attributes1 = [NSMutableDictionary dictionary];
		[attributes1 setObject:[NSFont fontWithName:@"Helvetica" size:11] forKey:NSFontAttributeName];
		
		NSSize extent = [strTime sizeWithAttributes:attributes1];
		
		[strTime drawAtPoint:NSMakePoint(plotArea.origin.x - extent.width - 3, dYValue - (extent.height / 2.0)) withAttributes:attributes1];		
	}
	
	double dXPos = dLeftStart + dInc;
	
	//// Draw Sunrise
	
	GraphValue *pGraphVal = [self getGraphValue:0];
	double dSRVal = [pGraphVal getSunriseValue];
	double dSSVal = [pGraphVal getSunsetValue];
	double dDLVal = [pGraphVal getDayLengthValue];
	
	[pathSR moveToPoint:NSMakePoint(dLeftStart, ((dSRVal * dYScale) - (dMinY * dYScale)) + (dMarginY * 1.5))];
	
	[pathSS moveToPoint:NSMakePoint(dLeftStart, ((dSSVal * dYScale) - (dMinY * dYScale)) + (dMarginY * 1.5))];
	
	[pathDL moveToPoint:NSMakePoint(dLeftStart, ((dDLVal * plotArea.size.height)) + (dMarginY * 1.5))];
	
	int i = 0;
	for (i = 0; i < nNumValues; i++)
	{
		pGraphVal = [self getGraphValue:i];
		dSRVal = [pGraphVal getSunriseValue];
		dSSVal = [pGraphVal getSunsetValue];
		dDLVal = [pGraphVal getDayLengthValue];
		
		[pathSR lineToPoint:NSMakePoint(dXPos, (dSRVal * dYScale) - (dMinY * dYScale) + (dMarginY * 1.5))];
		
		[pathSS lineToPoint:NSMakePoint(dXPos, (dSSVal * dYScale) - (dMinY * dYScale) + (dMarginY * 1.5))];
		
		[pathDL lineToPoint:NSMakePoint(dXPos, (dDLVal * plotArea.size.height) + (dMarginY * 1.5))];
		
		// draw X grid value if ness
		
		int nTag = [pGraphVal getXTag];
		if (nTag != -1)
		{
			NSBezierPath* XLine = [NSBezierPath bezierPath];
			[XLine moveToPoint:NSMakePoint(dXPos, plotArea.origin.y)];
			[XLine lineToPoint:NSMakePoint(dXPos, (plotArea.origin.y + plotArea.size.height))];
			
			[[NSColor grayColor] set];
			
			[XLine stroke];
			
			NSString *strTagText = [self getTag:nTag];
			
			NSMutableDictionary *attributes1 = [NSMutableDictionary dictionary];
			[attributes1 setObject:[NSFont fontWithName:@"Helvetica" size:11] forKey:NSFontAttributeName];
			
			[strTagText drawAtPoint:NSMakePoint(dXPos, plotArea.origin.y - 15) withAttributes:attributes1];
		}
		dXPos += dInc;
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GraphShowSunrise"] == YES)
	{
		NSData *colour;
		colour = [[NSUserDefaults standardUserDefaults] objectForKey:@"GraphSunriseColour"];
		NSColor *cColour = [NSKeyedUnarchiver unarchiveObjectWithData:colour];
		[cColour set];
		[pathSR stroke];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GraphShowSunset"] == YES)
	{
		NSData *colour;
		colour = [[NSUserDefaults standardUserDefaults] objectForKey:@"GraphSunsetColour"];
		NSColor *cColour = [NSKeyedUnarchiver unarchiveObjectWithData:colour];
		[cColour set];
		[pathSS stroke];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GraphShowDayLength"] == YES)
	{
		NSData *colour;
		colour = [[NSUserDefaults standardUserDefaults] objectForKey:@"GraphDayLengthColour"];
		NSColor *cColour = [NSKeyedUnarchiver unarchiveObjectWithData:colour];
		[cColour set];
		[pathDL stroke];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GraphShowCurrentTime"] == YES)
	{
		NSBezierPath* CurrentTimeLine = [NSBezierPath bezierPath];
		
		double dYValue = ([self getCurrentAngle] * dYScale) - (dMinY * dYScale) + (dMarginY * 1.5);
		[CurrentTimeLine moveToPoint:NSMakePoint(plotArea.origin.x - 30, dYValue)];
		[CurrentTimeLine lineToPoint:NSMakePoint((plotArea.origin.x + plotArea.size.width), dYValue)];
		
		NSData *colour;
		colour = [[NSUserDefaults standardUserDefaults] objectForKey:@"GraphCurrentTimeColour"];
		NSColor *cColour = [NSKeyedUnarchiver unarchiveObjectWithData:colour];
		[cColour set];
		[CurrentTimeLine stroke];
	}
}

- (void)Reset:(int)nDays;
{
	[aGraphValues removeAllObjects];
	[aTags removeAllObjects];
	
	nDaysToShow = nDays;
}

- (void)addGraphValue:(GraphValue*)v;
{
	[aGraphValues addObject:v];
}

- (GraphValue*)getGraphValue:(int)i
{
	GraphValue *pVal = [aGraphValues objectAtIndex:i];
	return pVal;
}

- (int)graphValuesCount
{
	return [aGraphValues count];
}

- (int)addTag:(NSString*)Title
{
	[aTags addObject:Title];
	
	int nCount = [aTags count] - 1;
	return nCount;
}

- (NSString*)getTag:(int)i
{
	NSString *strTag = [aTags objectAtIndex:i];
	return strTag;
}

- (double)getCurrentAngle
{
	return dCurrentAngle;
}

- (void)setCurrentAngle:(double)dAngle
{
	dCurrentAngle = dAngle;
}

- (void)handleSettingsChange:(NSNotification *)note
{
	[self setNeedsDisplay:YES];
}

@end
