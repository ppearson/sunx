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

@interface SunView : NSView
{
	double CurrentAngle;
	double SunriseAngle;
	double SunsetAngle;
	double DawnAngle;
	double DuskAngle;
	
	NSString *strSunriseTime;
	NSString *strSunsetTime;
	NSString *strDayLength;
}

- (double)getCurrentAngle;
- (double)getSunriseAngle;
- (double)getSunsetAngle;
- (double)getDawnAngle;
- (double)getDuskAngle;

- (void)setCurrentAngle:(double)dAngle;
- (void)setSunriseAngle:(double)dAngle;
- (void)setSunsetAngle:(double)dAngle;
- (void)setDawnAngle:(double)dAngle;
- (void)setDuskAngle:(double)dAngle;

- (void)setSunriseTime:(NSString*)strTime;
- (void)setSunsetTime:(NSString*)strTime;
- (void)setDayLength:(NSString*)strDayLen;

- (double)processAngle:(double)dAngle;
- (void)drawAngleBar:(NSPoint)centrePoint Path:(NSBezierPath*)path Angle:(double)dAngle InnRad:(double)dInnRad OutRad:(double)dOutRad;
- (void)appendPoint:(NSPoint)centrePoint Path:(NSBezierPath*)path Angle:(double)dAngle Distance:(double)dDistance;

@end
