
#import <Cocoa/Cocoa.h>
#import <GMap/GMap.h>

@interface GNAppDelegate : NSObject <NSApplicationDelegate, GMMapViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *wrapperView;
@property GMMapView *mapView;

@end
