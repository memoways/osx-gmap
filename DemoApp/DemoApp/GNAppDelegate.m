
#import "GNAppDelegate.h"

@implementation GNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.mapView.roundZoomLevel = YES;
    self.mapView.tileManager.diskCacheEnabled = YES;
    [self addObserver:self forKeyPath:@"latitude" options:0 context:nil];
    [self addObserver:self forKeyPath:@"longitude" options:0 context:nil];
    [self addObserver:self forKeyPath:@"zoomLevel" options:0 context:nil];

    self.latitude = 46.779441;
    self.longitude = 6.644787;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"zoomLevel"])
        self.mapView.zoomLevel = self.zoomLevel;
    else
        self.mapView.centerCoordinate = GMCoordinateMake(self.latitude, self.longitude);

}

@end
