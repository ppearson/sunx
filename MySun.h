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
#import "SunView.h"
#import "GraphView.h"

@interface MySun : NSObject
{
    IBOutlet id Date1;
	IBOutlet id TargetTime;
	IBOutlet id Duration1;
	NSWindow *window;
	
	IBOutlet SunView *AngleView;
	IBOutlet GraphView *GraphView1;
	
	IBOutlet NSDrawer *drawer;
	IBOutlet NSTableView *Table;
}

- (void)awakeFromNib;
- (IBAction)Calculate:(id)sender;
- (void)tableViewSelectionDidChange:(NSNotification *)notification;

- (IBAction)UpdateDuration:(id)sender;

- (IBAction)ToggleDrawer:(id)sender;

double RadToDeg(double dAngle);
double DegToRad(double dAngle);

- (double) CalcGamma:(int) nJulianDay;
- (double) CalcGamma2:(int) nJulianDay Hour:(int) nHour;
- (double) CalcEqOfTime:(double) dGamma;
- (double) CalcSolarDec:(double) dGamma;

- (NSString*) CalcSunrise:(int) nYear Month:(int) nMonth Day:(int) nDay Long:(double)dLong Lat:(double)dLat TZ:(NSString*)timezone;
- (NSString*) CalcSunset:(int) nYear Month:(int) nMonth Day:(int) nDay Long:(double)dLong Lat:(double)dLat TZ:(NSString*)timezone;

- (double) CalcSunriseTimeAngle:(NSCalendarDate*) Date Long:(double)dLong Lat:(double)dLat TZ:(NSString*)timezone;
- (double) CalcSunsetTimeAngle:(NSCalendarDate*) Date Long:(double)dLong Lat:(double)dLat TZ:(NSString*)timezone;

//- (double) CalcSunriseTimeAngle:(int) nDay Long:(double)dLong Lat:(double)dLat;

- (double) CalcHourAngle:(double) dLat SolarDec: (double) dSolarDec Time:(bool) bTime;
- (double) CalcDayLength:(double) dHourAngle;

@end
