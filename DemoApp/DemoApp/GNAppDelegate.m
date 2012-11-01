
#import "GNAppDelegate.h"

@implementation GNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.mapView = [GMMapView.alloc initWithFrame:(CGRect){CGPointZero, self.wrapperView.frame.size}];
    self.mapView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.wrapperView addSubview:self.mapView];
        // self.mapView.roundZoomLevel = YES;
    self.mapView.tileManager.diskCacheEnabled = YES;
    self.mapView.zoomLevel = 14;
    self.mapView.centerCoordinate = GMCoordinateMake(46.536264571, 6.599329227);
}


@end
