
#import <Cocoa/Cocoa.h>
#import <GMap/GMap.h>

@interface GNAppDelegate : NSObject <NSApplicationDelegate, GMMapViewDelegate>

@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet NSView *wrapperView;
@property (nonatomic) GMMapView *mapView;

@property (nonatomic) IBOutlet NSPanel *inspectorPanel;
@property (nonatomic) GMCircle *selectedCircle;

@property (nonatomic) BOOL addCircleOnClick;

@end
