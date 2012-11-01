
#import <Cocoa/Cocoa.h>
#import <GMap/GMap.h>

@interface GNAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *wrapperView;
@property GMMapView *mapView;

@end
