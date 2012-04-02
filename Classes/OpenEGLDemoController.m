//  OpenEGLDemoController.m
//
//  Created by Scott Davilla and Thomas Cool on 10/20/10.
/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../BackRow/BackRow.h"

#import "OpenEGLDemoController.h"

//--------------------------------------------------------------
//--------------------------------------------------------------
// notification messages
extern NSString* kBRScreenSaverActivated;
extern NSString* kBRScreenSaverDismissed;
extern NSString* BRApplianceChangedNotification;
extern NSString* BRMainMenuIsVisibleNotification;

//--------------------------------------------------------------
//--------------------------------------------------------------
@interface OpenEGLDemoController (PrivateMethods)
- (void) observeDefaultCenterStuff: (NSNotification *) notification;
- (void) disableScreenSaver;
- (void) enableScreenSaver;
@end
//
@implementation OpenEGLDemoController
- (id) init
{  
  NSLog(@"%s", __PRETTY_FUNCTION__);

  self = [super init];
  if ( !self )
    return ( nil );

  NSNotificationCenter *center;
  // first the default notification center, which is all
  // notifications that only happen inside of our program
  center = [NSNotificationCenter defaultCenter];
  [center addObserver: self
    selector: @selector(observeDefaultCenterStuff:)
    name: nil
    object: nil];
    
  CGRect interfaceFrame = [BRWindow interfaceFrame];
  NSLog(@"interfaceframe: %f, %f, %f, %f", interfaceFrame.origin.x, interfaceFrame.origin.y, interfaceFrame.size.width, interfaceFrame.size.height);
  m_glView = [[EAGLView alloc] initWithFrame:interfaceFrame];

  return self;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  NSLog(@"s", __PRETTY_FUNCTION__);
  return TRUE;
}

- (void)dealloc
{
  NSLog(@"%s", __PRETTY_FUNCTION__);

  [m_glView stopAnimation];
  [m_glView release];
  [m_window release];

  NSNotificationCenter *center;
  // take us off the default center for our app
  center = [NSNotificationCenter defaultCenter];
  [center removeObserver: self];

  [super dealloc];
}

- (void)controlWasActivated
{
  NSLog(@"%s", __PRETTY_FUNCTION__);

  [super controlWasActivated];

  //inject the eagl layer into the brwindow rootlayer
  [[BRWindow rootLayer] addSublayer:m_glView.layer];

  [m_glView startAnimation];  
}

- (void)controlWasDeactivated
{
  NSLog(@"%s", __PRETTY_FUNCTION__);
  [m_glView stopAnimation];
  [m_glView.layer removeFromSuperlayer];

  [super controlWasDeactivated];
}

- (BOOL) recreateOnReselect
{ 
  NSLog(@"%s", __PRETTY_FUNCTION__);
  return YES;
}

- (BOOL)brEventAction:(id)action
{
  NSLog(@"%s", __PRETTY_FUNCTION__);

  return [super brEventAction:action];
}

#pragma mark -
#pragma mark private helper methods
//
- (void)observeDefaultCenterStuff: (NSNotification *) notification
{
  //NSLog(@"default: %@", [notification name]);
  if ([notification name] == kBRScreenSaverActivated)
    [m_glView stopAnimation];
  
  if ([notification name] == kBRScreenSaverDismissed)
    [m_glView startAnimation];
}

- (void) disableScreenSaver
{
  /*
  NSLog(@"%s", __PRETTY_FUNCTION__);
  //store screen saver state and disable it
  //!!BRSettingsFacade setScreenSaverEnabled does change the plist, but does _not_ seem to work
  m_screensaverTimeout = [[BRSettingsFacade singleton] screenSaverTimeout];
  [[BRSettingsFacade singleton] setScreenSaverTimeout:-1];
  [[BRSettingsFacade singleton] flushDiskChanges];
  */
}

- (void) enableScreenSaver
{
  /*
  NSLog(@"%s", __PRETTY_FUNCTION__);
  //reset screen saver to user settings
  [[BRSettingsFacade singleton] setScreenSaverTimeout: m_screensaverTimeout];
  [[BRSettingsFacade singleton] flushDiskChanges];
  */
}

@end
