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

#import "SunView.h"

@implementation SunView

#define DegToRad(deg) (deg*0.017453)
#define RadToDeg(deg) (deg*57.2958)

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(handleSettingsChange:) name:@"PieSettingsUpdate" object:nil];
    }
    return self;
}

- (void)dealloc
{
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    NSRect bounds = [self bounds];
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:bounds];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:bounds];
	
	// convert angles
	double dSR = [self processAngle:SunriseAngle];
	double dSS = [self processAngle:SunsetAngle];
	double dCA = [self processAngle:CurrentAngle];
	double dDA = [self processAngle:DawnAngle];
	double dDU = [self processAngle:DuskAngle];
	
	double dMainRadius = 41.0;
	
	NSPoint centrepoint = NSMakePoint(bounds.size.width / 2.0, bounds.size.height / 2.0);
	
	NSData *colour;
	colour = [[NSUserDefaults standardUserDefaults] objectForKey:@"PieDayColour"];
	NSColor *cColour = [NSKeyedUnarchiver unarchiveObjectWithData:colour];
	[cColour set];
	
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path moveToPoint:centrepoint];
	
	[path appendBezierPathWithArcWithCenter:centrepoint radius:dMainRadius startAngle:dSS endAngle:dSR clockwise:NO];
	[path lineToPoint:centrepoint];
	
	[path fill];
	[[NSColor blackColor] set];
	[path stroke];
	
	[path removeAllPoints];
	
	colour = [[NSUserDefaults standardUserDefaults] objectForKey:@"PieNightColour"];
	cColour = [NSKeyedUnarchiver unarchiveObjectWithData:colour];
	[cColour set];
	
	[path moveToPoint:centrepoint];
	
	[path appendBezierPathWithArcWithCenter:centrepoint radius:dMainRadius startAngle:dSR endAngle:dSS clockwise:NO];
	[path lineToPoint:centrepoint];
	
	[path fill];
	[[NSColor blackColor] set];
	[path stroke];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PieShowTwilight"] == true)
	{
		[path removeAllPoints];
		
		colour = [[NSUserDefaults standardUserDefaults] objectForKey:@"PieTwilightColour"];
		cColour = [NSKeyedUnarchiver unarchiveObjectWithData:colour];
		[cColour set];
		
		[path moveToPoint:centrepoint];
		
		[path appendBezierPathWithArcWithCenter:centrepoint radius:dMainRadius startAngle:dSR endAngle:dDA clockwise:NO];
		[path lineToPoint:centrepoint];
		
		[path fill];
		[[NSColor blackColor] set];
		[path stroke];
		
		[path removeAllPoints];
		
		[path moveToPoint:centrepoint];
		
		[path appendBezierPathWithArcWithCenter:centrepoint radius:dMainRadius startAngle:dDU endAngle:dSS clockwise:NO];
		[path lineToPoint:centrepoint];
		
		[cColour set];
		[path fill];
		[[NSColor blackColor] set];
		[path stroke];
	}
	
	// draw time quandrant angle lines
	
	[[NSColor blackColor] set];
	
	int i;
	for (i = 0; i < 4; i++)
	{
		[path removeAllPoints];
		
		[self drawAngleBar:centrepoint Path:path Angle:(90.0 * i) InnRad:(dMainRadius - 5.0) OutRad:(dMainRadius + 5.0)];
		[path stroke];		
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PieShowCurrentTime"] == true)
	{
		// draw current time bar angle
		[path removeAllPoints];
		[[NSColor redColor] set];
		
		double fRad = DegToRad(dCA);
		double fX, fY = 0.0f;
		
		fY = (float)sin(fRad);
		fX = (float)cos(fRad);
		
		double dStartX = centrepoint.x + (fX * (dMainRadius - 3.0));
		double dStartY = centrepoint.y + (fY * (dMainRadius - 3.0));
		
		[path moveToPoint:NSMakePoint(dStartX, dStartY)];
		
		double dCentreWidth = 10.0;
		[self appendPoint:centrepoint Path:path Angle:(dCA - 90.0) Distance:(dCentreWidth / 2.0) - 2.0];
		[self appendPoint:centrepoint Path:path Angle:(dCA + 90.0) Distance:(dCentreWidth / 2.0) - 2.0];
		
		[path lineToPoint:NSMakePoint(dStartX, dStartY)];
		
		NSRect rect3 = NSMakeRect(centrepoint.x - (dCentreWidth / 2.0), centrepoint.y - (dCentreWidth / 2.0), dCentreWidth, dCentreWidth);
		NSBezierPath *path2 = [NSBezierPath bezierPathWithOvalInRect:rect3];
		
		colour = [[NSUserDefaults standardUserDefaults] objectForKey:@"PieCurrentTimeColour"];
		cColour = [NSKeyedUnarchiver unarchiveObjectWithData:colour];
		[cColour set];
		[path fill];
		
		[[NSColor blackColor] set];
		[path stroke];
		
		[cColour set];
		[path2 fill];
		
		[[NSColor blackColor] set];
		[path2 stroke];
	}
	
	// draw time quadrant times 	
	NSMutableDictionary *attributes1 = [NSMutableDictionary dictionary];
	[attributes1 setObject:[NSFont fontWithName:@"Helvetica" size:11] forKey:NSFontAttributeName];
	
	double dTextOffset = dMainRadius + 12.0;
	
	NSString *strText = @"00";
	NSSize extent = [strText sizeWithAttributes:attributes1];
	[strText drawAtPoint:NSMakePoint((centrepoint.x + 1 - (extent.width / 2)), (centrepoint.y - dTextOffset - (extent.height / 2) + 2)) withAttributes:attributes1];
	
	strText = @"06";
	extent = [strText sizeWithAttributes:attributes1];
	[strText drawAtPoint:NSMakePoint((centrepoint.x - dTextOffset - (extent.width / 2)), (centrepoint.y  - (extent.height / 2))) withAttributes:attributes1];
	
	strText = @"12";
	extent = [strText sizeWithAttributes:attributes1];
	[strText drawAtPoint:NSMakePoint((centrepoint.x + 1 - (extent.width / 2)), (centrepoint.y + dTextOffset - (extent.height / 2))) withAttributes:attributes1];
	
	strText = @"18";
	extent = [strText sizeWithAttributes:attributes1];
	[strText drawAtPoint:NSMakePoint((centrepoint.x + dTextOffset - (extent.width / 2)), (centrepoint.y  - (extent.height / 2))) withAttributes:attributes1];
}

- (bool)IsOpaque
{
	return YES;
}

- (double)getCurrentAngle
{
	return CurrentAngle;
}

- (double)getSunriseAngle
{
	return SunriseAngle;
}

- (double)getSunsetAngle
{
	return SunsetAngle;
}

- (double)getDawnAngle
{
	return DawnAngle;
}

- (double)getDuskAngle
{
	return DuskAngle;
}

- (void)setCurrentAngle:(double)dAngle
{
	CurrentAngle = dAngle;
}

- (void)setSunriseAngle:(double)dAngle
{
	SunriseAngle = dAngle;
}

- (void)setSunsetAngle:(double)dAngle
{
	SunsetAngle = dAngle;
}

- (void)setDawnAngle:(double)dAngle
{
	DawnAngle = dAngle;
}

- (void)setDuskAngle:(double)dAngle
{
	DuskAngle = dAngle;
}

- (double)processAngle:(double)dAngle
{
	double dTemp = 0.0;
	
	if (dAngle < 90.0)
	{
		dTemp = (90 - dAngle);
		dAngle = 180.0 + dTemp;
	}
	else if (dAngle < 180.0)
	{
		dTemp = (180.0 - dAngle);
		dAngle = 90 + dTemp;
	}
	else if (dAngle > 270.0)
	{
		dTemp = (360.0 - dAngle);
		dAngle = 270.0 + dTemp;
	}
	else if (dAngle > 180.0)
	{
		dTemp = (270.0 - dAngle);
		dAngle = dTemp;
	}
	
	return dAngle;
}

- (void)drawAngleBar:(NSPoint)centrePoint Path:(NSBezierPath*)path Angle:(double)dAngle InnRad:(double)dInnRad OutRad:(double)dOutRad
{
	double fRad = DegToRad(dAngle);
	double dX, dY = 0.0;
	
	dY = (double)sin(fRad);
	dX = (double)cos(fRad);	
	
	double dStartX = centrePoint.x + (dX * dInnRad);
	double dStartY = centrePoint.y + (dY * dInnRad);
	double dEndX = centrePoint.x + (dX * dOutRad);
	double dEndY = centrePoint.y + (dY * dOutRad);
	
	[path moveToPoint:NSMakePoint(dStartX, dStartY)];
	[path lineToPoint:NSMakePoint(dEndX, dEndY)];	
}

- (void)appendPoint:(NSPoint)centrePoint Path:(NSBezierPath*)path Angle:(double)dAngle Distance:(double)dDistance
{
	double fRad = DegToRad(dAngle);
	double dX, dY = 0.0;
	
	dY = (double)sin(fRad);
	dX = (double)cos(fRad);	
	
	double dNewPointX = centrePoint.x + (dX * dDistance);
	double dNewPointY = centrePoint.y + (dY * dDistance);

	[path lineToPoint:NSMakePoint(dNewPointX, dNewPointY)];
}

- (void)handleSettingsChange:(NSNotification *)note
{
	[self setNeedsDisplay:YES];
}

@end
