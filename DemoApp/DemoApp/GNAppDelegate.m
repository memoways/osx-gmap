#import "GNAppDelegate.h"


static NSColor *randomColor(void)
{
    return [NSColor colorWithCalibratedRed:(CGFloat)rand() / (CGFloat) RAND_MAX green:(CGFloat)rand() / (CGFloat) RAND_MAX blue:(CGFloat)rand() / (CGFloat) RAND_MAX alpha:1];
}

@implementation GNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.mapView = [GMMapView.alloc initWithFrame:(CGRect) {CGPointZero, self.wrapperView.frame.size}];
    self.mapView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.wrapperView addSubview:self.mapView];
    // self.mapView.roundZoomLevel = YES;
    
    self.mapView.zoomLevel = 14;
    self.mapView.centerCoordinate = GMCoordinateMake(46.536264571, 6.599329227);

    sranddev();

    NSString *directoryPath = [NSBundle.mainBundle pathForResource:@"Tracks" ofType:nil];
    NSArray *trackPaths = [NSFileManager.defaultManager contentsOfDirectoryAtPath:directoryPath error:nil];

    for (NSString *trackPath in trackPaths)
    {
        NSData *data = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:trackPath]];
        NSArray *track = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        GMPolygon *polygon = GMPolygon.new;

        polygon.lineWidth = 5;
        polygon.strokeColor = [NSColor redColor];

        for (NSDictionary *coord in track)
        {
            CGFloat latitude = [[coord objectForKey:@"latitude"] doubleValue];
            CGFloat longitude = [[coord objectForKey:@"longitude"] doubleValue];
            [polygon addPointAtCoordinate:GMCoordinateMake(latitude, longitude)];
        }

        [self.mapView.overlayManager addOverlay:polygon];
    }

    directoryPath = [NSBundle.mainBundle pathForResource:@"Circles" ofType:nil];
    NSArray *circlesPaths = [NSFileManager.defaultManager contentsOfDirectoryAtPath:directoryPath error:nil];

    for (NSString *circlesPath in circlesPaths)
    {
        NSData *data = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:circlesPath]];
        NSArray *circles = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        for (NSDictionary *coord in circles)
        {
        GMCircle *circle = GMCircle.new;

        circle.lineWidth = 2;
        circle.strokeColor = [NSColor redColor];
        circle.fillColor = [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.5];
circle.centerPointColor = [NSColor blueColor];
            circle.centerPointSize = 6;

            CGFloat latitude = [[coord objectForKey:@"latitude"] doubleValue];
            CGFloat longitude = [[coord objectForKey:@"longitude"] doubleValue];
            CGFloat radius = [[coord objectForKey:@"radius"] doubleValue];
            circle.radius = radius;
            circle.centerCoordinate = GMCoordinateMake(latitude, longitude);
            [self.mapView.overlayManager addOverlay:circle];
        }

    }
}


@end
