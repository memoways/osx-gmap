#import "GNAppDelegate.h"

@implementation GNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.mapView = [GMMapView.alloc initWithFrame:(CGRect) {CGPointZero, self.wrapperView.frame.size}];
    self.mapView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.wrapperView addSubview:self.mapView];
    // self.mapView.roundZoomLevel = YES;
    self.mapView.tileManager.diskCacheEnabled = YES;
    self.mapView.zoomLevel = 14;
    self.mapView.centerCoordinate = GMCoordinateMake(46.536264571, 6.599329227);


    NSString *directoryPath = [NSBundle.mainBundle pathForResource:@"Tracks" ofType:nil];
    NSArray *trackPaths = [NSFileManager.defaultManager contentsOfDirectoryAtPath:directoryPath error:nil];

    for (NSString *trackPath in trackPaths)
    {
        NSData *data = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:trackPath]];
        NSArray *track = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        GMPolygon *polygon = GMPolygon.new;

        for (NSDictionary *coord in track)
        {
            CGFloat latitude = [[coord objectForKey:@"latitude"] doubleValue];
            CGFloat longitude = [[coord objectForKey:@"longitude"] doubleValue];
            [polygon addPointAtCoordinate:GMCoordinateMake(latitude, longitude)];
        }

        [self.mapView.overlayManager addOverlay:polygon];
        break;
    }
    
}


@end
