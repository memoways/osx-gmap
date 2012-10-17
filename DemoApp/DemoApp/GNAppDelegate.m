
#import "GNAppDelegate.h"

@implementation GNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.mapView.centerCoordinate = GMCoordinateMake(46.781351, 6.648743);
    self.mapView.zoomLevel = 13;
    
}

@end
