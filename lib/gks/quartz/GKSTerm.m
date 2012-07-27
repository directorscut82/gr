
#include "gks.h"
#include "gkscore.h"

#import "GKSTerm.h"
#import "GKSView.h"

@implementation GKSTerm

- (void) awakeFromNib
{  
  [[NSNotificationCenter defaultCenter] addObserver:self 
                                        selector:@selector(keepOnDisplay:) 
                                        name:@"GKSViewKeepOnDisplayNotification" object:nil];   
  if (!connection)
    {
      // Deprecated in Mac OS X v10.6
      //connection = [NSConnection defaultConnection];
      connection = [NSConnection new];
      [connection setRootObject:self];
      [connection registerName:@"GKSQuartz"];
      num_windows = 0;
      curr_win_id = 0;
    }
}

- (int) GKSQuartzCreateWindow
{
  int win = [self getNextWindowID];
 
  if (win < MAX_WINDOWS)
    {
      NSRect screenFrame = [[[NSScreen screens] objectAtIndex:0] frame];
      window[win] = [[NSWindow alloc]
                      initWithContentRect: NSMakeRect(NSMinX(screenFrame), NSMaxY(screenFrame) - 500, 500, 500)
                      styleMask: NSTitledWindowMask | NSClosableWindowMask |
                      NSMiniaturizableWindowMask
                      backing: NSBackingStoreBuffered defer: NO];
      [window[win] setBackgroundColor: [NSColor colorWithCalibratedWhite: 1 alpha: 1]];
      view[win] = [[GKSView alloc] initWithFrame: NSMakeRect(0,0, 500,500)];
      [window[win] setContentView:view[win]];
      [window[win] makeFirstResponder: view[win]];
      [window[win] makeKeyAndOrderFront: nil];
      [window[win] setTitle: @"GKSTerm"];
      [window[win] display];
      
      [view[win] setWinID: win];
      
      cascadingPoint = [window[win] cascadeTopLeftFromPoint: cascadingPoint];
      
      close_window[win]=YES;
      [[NSNotificationCenter defaultCenter] addObserver:self
              selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification
              object:window[win]];
      return win;
    }
  else
    return -1;
}

- (void) windowWillClose:(NSNotification *)notification
{
  NSWindow *nswin = [notification object];
  for (int win = 0; win < MAX_WINDOWS; win++) {
    if (window[win] != nil && close_window[win] && window[win] == nswin) {
      [view[win] close];
      view[win] = nil;
      window[win] = nil;
    }
  }
}

- (void) GKSQuartzDraw: (int) win displayList: (id) displayList
{ 
  [view[win] setDisplayList: displayList];
}

- (void) GKSQuartzCloseWindow: (int) win
{
  if (close_window[win])
    {
      if (view[win] != nil) {
        [view[win] close];
      }
      if (window[win] != nil) {
        [window[win] close];
      }
    }
  view[win] = nil;
  window[win] = nil;
  
  curr_win_id = win;
}

- (IBAction) cascadeWindows: (id) sender
{
  int i;
  NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
  cascadingPoint = NSMakePoint( NSMinX(screenFrame), NSMaxY(screenFrame) );
      
  for (i = 0; i < num_windows; i++) 
    {
      if (window[i])
        {        
          [self setWindowPos:window[i]];
          [window[i] makeKeyAndOrderFront:self];
        }
    }
}

- (void) setWindowPos: (NSWindow *) plotWindow
{
  cascadingPoint = [plotWindow cascadeTopLeftFromPoint:cascadingPoint];
}

- (void) keepOnDisplay: (NSNotification *) aNotification
{
  GKSView *tmpView = [aNotification object];  
  int win = [tmpView getWinID];
  close_window[win] = NO;
}

- (int) getNextWindowID
{
  int i = 0;
  
  do
    {
      if (!window[curr_win_id])
        {
          num_windows++;
          return curr_win_id;
        }
      i++;
      curr_win_id = curr_win_id++ % MAX_WINDOWS;
    }
  while (i < MAX_WINDOWS);
  
  return i;
}

@end
