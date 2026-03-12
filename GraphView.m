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
	
	double dMarginX = 25.0;
	double dMarginY = 12.0;
	
	NSRect innerBounds = NSInsetRect(bounds, dMarginX, dMarginY);
	NSRect plotArea = NSOffsetRect(innerBounds, (dMarginX/2.0), (dMarginY/2.0));
	dMarginY *= 1.5;
	
	int nNumValues = [self graphValuesCount];
	if (nNumValues < 1)
	{
		return;
	}
	
	int graphType = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"GraphGraphType"];
	
	double dLeftStart = plotArea.origin.x;
	
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
		
		if (graphType == 0)
		{
			double dSRVal = [pGraphVal getSunriseValue];
			double dSSVal = [pGraphVal getSunsetValue];
			
			if (dSRVal < dMinY && !isnan(dSRVal))
				dMinY = dSRVal;
			
			if (dSSVal > dMaxY && !isnan(dSSVal))
				dMaxY = dSSVal;
		}
		else if (graphType == 1)
		{
			double dDawnVal = [pGraphVal getDawnValue];
			double dDuskVal = [pGraphVal getDuskValue];
			
			if (dDawnVal < dMinY && !isnan(dDawnVal))
				dMinY = dDawnVal;
			
			if (dDuskVal > dMaxY && !isnan(dDuskVal))
				dMaxY = dDuskVal;
		}
	}
	
	if (graphType == 0)
	{
		[[NSColor whiteColor] set];
	}
	else if (graphType == 1)
	{
		[[NSColor colorWithSRGBRed:0.98 green:0.98 blue:0.98 alpha:1.0] set];
	}
	[NSBezierPath fillRect:plotArea];
	
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:plotArea];
	
	// 
	
	dMaxY += 1.0;
	dMinY -= 1.0;
	
	double dYRange = dMaxY - dMinY;
	
	double dYScale = plotArea.size.height / dYRange;
	
	NSDate* today = [NSDate date];
	NSCalendarDate* CalDate = [today dateWithCalendarFormat:0 timeZone:0];
	
	// draw Y axis grid
	
	int nStartHour = dMinY + 15 - ((int)dMinY % 15);

	for (k = nStartHour; k < (int)dMaxY; k += 15)
	{
		int nHour = k / 15;
		
		NSCalendarDate *newDate = [NSCalendarDate dateWithYear:[CalDate yearOfCommonEra] month:[CalDate monthOfYear] day:[CalDate monthOfYear] hour:nHour
			minute:0 second:0 timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
		
		NSString *strTime = [newDate descriptionWithCalendarFormat:@"%H:%M" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
		
		NSBezierPath* YLine = [NSBezierPath bezierPath];
		
		double dYValue = (k * dYScale) - (dMinY * dYScale) + dMarginY;
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
	
	// these are (optionally) drawn for both graph types
	NSBezierPath* pathSR = [NSBezierPath bezierPath];
	NSBezierPath* pathSS = [NSBezierPath bezierPath];
	NSBezierPath* pathDL = [NSBezierPath bezierPath];
	
	if (graphType == 0)
	{
		GraphValue *pGraphVal = [self getGraphValue:0];
		double dSRVal = [pGraphVal getSunriseValue];
		double dSSVal = [pGraphVal getSunsetValue];
		double dDLVal = [pGraphVal getDayLengthValue];
		
		[pathSR moveToPoint:NSMakePoint(dLeftStart, ((dSRVal * dYScale) - (dMinY * dYScale)) + dMarginY)];
		[pathSS moveToPoint:NSMakePoint(dLeftStart, ((dSSVal * dYScale) - (dMinY * dYScale)) + dMarginY)];
		[pathDL moveToPoint:NSMakePoint(dLeftStart, ((dDLVal * plotArea.size.height)) + dMarginY)];
		
		int i = 0;
		for (i = 0; i < nNumValues; i++)
		{
			pGraphVal = [self getGraphValue:i];
			dSRVal = [pGraphVal getSunriseValue];
			dSSVal = [pGraphVal getSunsetValue];
			dDLVal = [pGraphVal getDayLengthValue];
			
			[pathSR lineToPoint:NSMakePoint(dXPos, (dSRVal * dYScale) - (dMinY * dYScale) + dMarginY)];
			[pathSS lineToPoint:NSMakePoint(dXPos, (dSSVal * dYScale) - (dMinY * dYScale) + dMarginY)];
			[pathDL lineToPoint:NSMakePoint(dXPos, (dDLVal * plotArea.size.height) + dMarginY)];
			
			// draw X grid value if needed
			
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
				
				double textPosX = dXPos - 10.0;
				[strTagText drawAtPoint:NSMakePoint(textPosX, plotArea.origin.y - 15) withAttributes:attributes1];
			}
			dXPos += dInc;
		}
	}
	else if (graphType == 1)
	{
		GraphValue* pGraphVal = [self getGraphValue:0];
		double dDawnVal = [pGraphVal getDawnValue];
		double dSRVal = [pGraphVal getSunriseValue];
		double dSSVal = [pGraphVal getSunsetValue];
		double dDuskVal = [pGraphVal getDuskValue];
		double dDLVal = [pGraphVal getDayLengthValue];
		
		NSBezierPath* pathNight0 = [NSBezierPath bezierPath];
		NSBezierPath* pathDawn = [NSBezierPath bezierPath];
		NSBezierPath* pathDusk = [NSBezierPath bezierPath];
		NSBezierPath* pathNight1 = [NSBezierPath bezierPath];
		
		NSMutableArray* dawnPositions = [[NSMutableArray alloc] initWithCapacity:365];
		NSMutableArray* sunrisePositions = [[NSMutableArray alloc] initWithCapacity:365];
		NSMutableArray* sunsetPositions = [[NSMutableArray alloc] initWithCapacity:365];
		NSMutableArray* duskPositions = [[NSMutableArray alloc] initWithCapacity:365];
		
		double yPosDawn = ((dDawnVal * dYScale) - (dMinY * dYScale)) + dMarginY;
		double yPosSunrise = ((dSRVal * dYScale) - (dMinY * dYScale)) + dMarginY;
		double yPosSunset = ((dSSVal * dYScale) - (dMinY * dYScale)) + dMarginY;
		double yPosDusk = ((dDuskVal * dYScale) - (dMinY * dYScale)) + dMarginY;
		
		[dawnPositions addObject:[NSValue valueWithPoint:NSMakePoint(dLeftStart, yPosDawn)]];
		[sunrisePositions addObject:[NSValue valueWithPoint:NSMakePoint(dLeftStart, yPosSunrise)]];
		[sunsetPositions addObject:[NSValue valueWithPoint:NSMakePoint(dLeftStart, yPosSunset)]];
		[duskPositions addObject:[NSValue valueWithPoint:NSMakePoint(dLeftStart, yPosDusk)]];
		
		[pathSR moveToPoint:NSMakePoint(dLeftStart, ((dSRVal * dYScale) - (dMinY * dYScale)) + dMarginY)];
		[pathSS moveToPoint:NSMakePoint(dLeftStart, ((dSSVal * dYScale) - (dMinY * dYScale)) + dMarginY)];
		[pathDL moveToPoint:NSMakePoint(dLeftStart, ((dDLVal * plotArea.size.height)) + dMarginY)];
		
		int i = 0;
		for (i = 0; i < nNumValues; i++)
		{
			pGraphVal = [self getGraphValue:i];
			dDawnVal = [pGraphVal getDawnValue];
			dSRVal = [pGraphVal getSunriseValue];
			dSSVal = [pGraphVal getSunsetValue];
			dDuskVal = [pGraphVal getDuskValue];
			dDLVal = [pGraphVal getDayLengthValue];
			
			yPosDawn = ((dDawnVal * dYScale) - (dMinY * dYScale)) + dMarginY;
			if (dDawnVal < 0.0)
			{
				yPosDawn = plotArea.origin.y;
			}
			yPosSunrise = ((dSRVal * dYScale) - (dMinY * dYScale)) + dMarginY;
			yPosSunset = ((dSSVal * dYScale) - (dMinY * dYScale)) + dMarginY;
			yPosDusk = ((dDuskVal * dYScale) - (dMinY * dYScale)) + dMarginY;
			if (dDuskVal < 0.0)
			{
				yPosDusk = plotArea.origin.y + plotArea.size.height;
			}
			
			[dawnPositions addObject:[NSValue valueWithPoint:NSMakePoint(dXPos, yPosDawn)]];
			[sunrisePositions addObject:[NSValue valueWithPoint:NSMakePoint(dXPos, yPosSunrise)]];
			[sunsetPositions addObject:[NSValue valueWithPoint:NSMakePoint(dXPos, yPosSunset)]];
			[duskPositions addObject:[NSValue valueWithPoint:NSMakePoint(dXPos, yPosDusk)]];
			
			
			[pathSR lineToPoint:NSMakePoint(dXPos, (dSRVal * dYScale) - (dMinY * dYScale) + dMarginY)];
			[pathSS lineToPoint:NSMakePoint(dXPos, (dSSVal * dYScale) - (dMinY * dYScale) + dMarginY)];
			[pathDL lineToPoint:NSMakePoint(dXPos, (dDLVal * plotArea.size.height) + dMarginY)];
			
			// draw X grid value if needed
			
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
				double textPosX = dXPos - 10.0;
				[strTagText drawAtPoint:NSMakePoint(textPosX, plotArea.origin.y - 15) withAttributes:attributes1];
			}
			dXPos += dInc;
		}
		
		[pathNight0 moveToPoint:NSMakePoint(dLeftStart, plotArea.origin.y)];
		[pathNight0 lineToPoint:NSMakePoint(dLeftStart, yPosDawn)];
		
		[pathDawn moveToPoint:NSMakePoint(dLeftStart, yPosDawn)];
		[pathDawn lineToPoint:NSMakePoint(dLeftStart, yPosSunrise)];
		
		[pathDusk moveToPoint:NSMakePoint(dLeftStart, yPosSunset)];
		[pathDusk lineToPoint:NSMakePoint(dLeftStart, yPosDusk)];
		
		[pathNight1 moveToPoint:NSMakePoint(dLeftStart, yPosDusk)];
		[pathNight1 lineToPoint:NSMakePoint(dLeftStart, plotArea.origin.y + plotArea.size.height)];
		
		// plot from left to right at the top of the area
		for (i = 0; i < nNumValues + 1; i++)
		{
			NSPoint dawnP = [dawnPositions[i] pointValue];
			NSPoint sunriseP = [sunrisePositions[i] pointValue];
			NSPoint duskP = [duskPositions[i] pointValue];
			
			[pathNight0 lineToPoint:dawnP];
			[pathDawn lineToPoint:sunriseP];
			[pathDusk lineToPoint:duskP];
		}
		
		[pathNight1 lineToPoint:NSMakePoint(plotArea.origin.x + plotArea.size.width, plotArea.origin.y + plotArea.size.height)];
		
		// then plot from right to left along the bottom of the area, basically reversing the source points
		for (i = 0; i < nNumValues + 1; i++)
		{
			int reversedIndex = nNumValues - i;
			
			NSPoint dawnP = [dawnPositions[reversedIndex] pointValue];
			NSPoint sunsetP = [sunsetPositions[reversedIndex] pointValue];
			NSPoint duskP = [duskPositions[reversedIndex] pointValue];
			
			// Note: pathNight0 can just be plotted back to origin as a single point for a straight line
			[pathDawn lineToPoint:dawnP];
			[pathDusk lineToPoint:sunsetP];
			[pathNight1 lineToPoint:duskP];
		}
		
		//
		
		// and plot back to the beginning (bottom right) again to close the shapes.
		[pathNight0 lineToPoint:NSMakePoint(dLeftStart + plotArea.size.width, plotArea.origin.y)];
		
		[[NSColor colorWithSRGBRed:0.490 green:0.396 blue:0.651 alpha:0.8] set];
		[pathNight0 fill];
		
		[[NSColor colorWithSRGBRed:1.0 green:0.7294 blue:0.5058 alpha:0.8] set];
		[pathDawn fill];
		
		[[NSColor colorWithSRGBRed:1.0 green:0.7294 blue:0.5058 alpha:0.8] set];
		[pathDusk fill];
		
		[[NSColor colorWithSRGBRed:0.490 green:0.396 blue:0.651 alpha:0.8] set];
		[pathNight1 fill];
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
		
		// TODO: only draw it if within the Y bounds of the plot...
		
		double dYValue = ([self getCurrentAngle] * dYScale) - (dMinY * dYScale) + dMarginY;
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
