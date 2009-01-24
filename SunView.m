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
        // Initialization code here.
    }
    return self;
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
	
	NSPoint centrepoint = NSMakePoint(bounds.size.width / 2.0, bounds.size.height / 2.0);
	
//	centrepoint.y += 10;
//	centrepoint.x -= 10;
	
	[[NSColor yellowColor] set];
//	[NSBezierPath fillRect:rect1];
	
	NSBezierPath* path = [NSBezierPath bezierPath];
	
	[path appendBezierPathWithArcWithCenter:centrepoint radius:35.0 startAngle:dSS endAngle:dSR clockwise:NO];
	[path lineToPoint:centrepoint];
//	[path closePath];
	[path fill];
	[[NSColor blackColor] set];
	[path stroke];
	
	[path removeAllPoints];
	
	[[NSColor blueColor] set];
	[path appendBezierPathWithArcWithCenter:centrepoint radius:35.0 startAngle:dSR endAngle:dSS clockwise:NO];
	[path lineToPoint:centrepoint];
	[path fill];
	[[NSColor blackColor] set];
	[path stroke];
	
	[path removeAllPoints];

	[[NSColor whiteColor] set];
	[path appendBezierPathWithArcWithCenter:centrepoint radius:25.0 startAngle:0.0 endAngle:360.0];
	[path fill];
	[[NSColor blackColor] set];
	[path stroke];	
	
	// draw time quandrant angle lines
	
	[[NSColor blackColor] set];
	
	int i;
	for (i = 0; i < 4; i++)
	{
		[path removeAllPoints];
		
		[self drawAngleBar:centrepoint Path:path Angle:(90.0 * i) InnRad:20.0 OutRad:38.0];
		[path stroke];		
	}
	
	// draw current time bar angle
	
	[path removeAllPoints];
	[[NSColor redColor] set];
	
	[self drawAngleBar:centrepoint Path:path Angle:dCA InnRad:20.0 OutRad:40.0];
	[path stroke];
	
	////
	
	
	NSMutableDictionary *attributes1 = [NSMutableDictionary dictionary];
	[attributes1 setObject:[NSFont fontWithName:@"Helvetica" size:11] forKey:NSFontAttributeName];
	
	int nOffset = 44;
	
	NSString *strText = @"00";
	NSSize extent = [strText sizeWithAttributes:attributes1];
	[strText drawAtPoint:NSMakePoint((centrepoint.x + 1 - (extent.width / 2)), (centrepoint.y - nOffset - (extent.height / 2) + 2)) withAttributes:attributes1];
	
	strText = @"06";
	extent = [strText sizeWithAttributes:attributes1];
	[strText drawAtPoint:NSMakePoint((centrepoint.x - nOffset - (extent.width / 2)), (centrepoint.y  - (extent.height / 2))) withAttributes:attributes1];
	
	strText = @"12";
	extent = [strText sizeWithAttributes:attributes1];
	[strText drawAtPoint:NSMakePoint((centrepoint.x + 1 - (extent.width / 2)), (centrepoint.y + nOffset - (extent.height / 2))) withAttributes:attributes1];
	
	strText = @"18";
	extent = [strText sizeWithAttributes:attributes1];
	[strText drawAtPoint:NSMakePoint((centrepoint.x + nOffset - (extent.width / 2)), (centrepoint.y  - (extent.height / 2))) withAttributes:attributes1];

	strText = @"Sunrise: ";	
	[strText drawAtPoint:NSMakePoint(3, extent.height) withAttributes:attributes1];
	
	extent = [strSunriseTime sizeWithAttributes:attributes1];
	[strSunriseTime drawAtPoint:NSMakePoint(bounds.size.width - 3 - extent.width, extent.height) withAttributes:attributes1];
	
	strText = @"Sunset: ";
	[strText drawAtPoint:NSMakePoint(3, 2) withAttributes:attributes1];
	
	extent = [strSunriseTime sizeWithAttributes:attributes1];
	[strSunsetTime drawAtPoint:NSMakePoint(bounds.size.width - 3 - extent.width, 2) withAttributes:attributes1];
	
	// draw day length	
	strText = @"Day length";
	
	extent = [strText sizeWithAttributes:attributes1];
	[strText drawAtPoint:NSMakePoint(bounds.size.width - extent.width - 4, bounds.size.height - extent.height) withAttributes:attributes1];
	
	extent = [strDayLength sizeWithAttributes:attributes1];
	[strDayLength drawAtPoint:NSMakePoint(bounds.size.width - extent.width - 4, bounds.size.height - (extent.height * 2)) withAttributes:attributes1];
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

- (void)setSunriseTime:(NSString*)strTime
{
	strTime = [strTime copy];
	[strSunriseTime release];
	strSunriseTime = strTime;
}

- (void)setSunsetTime:(NSString*)strTime
{
	strTime = [strTime copy];
	[strSunsetTime release];
	strSunsetTime = strTime;
}

- (void)setDayLength:(NSString*)strDayLen
{
	strDayLen = [strDayLen copy];
	[strDayLength release];
	strDayLength = strDayLen;
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
	double fX, fY = 0.0f;
	
	fY = (float)sin(fRad);
	fX = (float)cos(fRad);	
	
	double dStartX = centrePoint.x + (fX * dInnRad);
	double dStartY = centrePoint.y + (fY * dInnRad);
	double dEndX = centrePoint.x + (fX * dOutRad);
	double dEndY = centrePoint.y + (fY * dOutRad);
	
	[path moveToPoint:NSMakePoint(dStartX, dStartY)];
	[path lineToPoint:NSMakePoint(dEndX, dEndY)];	
}

@end
