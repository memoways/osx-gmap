#import "GNAppDelegate.h"


static NSColor *randomColor(void)
{
    sranddev();
    return [NSColor colorWithCalibratedRed:(CGFloat)rand() / (CGFloat) RAND_MAX green:(CGFloat)rand() / (CGFloat) RAND_MAX blue:(CGFloat)rand() / (CGFloat) RAND_MAX alpha:1];
}

@implementation GNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSColor setIgnoresAlpha:NO];

    self.mapView = [GMMapView.alloc initWithFrame:(CGRect) {CGPointZero, self.wrapperView.frame.size}];
    self.mapView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.wrapperView addSubview:self.mapView];
    

    self.mapView.zoomLevel = 14;
    self.mapView.centerCoordinate = GMCoordinateMake(46.536264571, 6.599329227);
    self.mapView.overlaysDraggable = YES;
    self.mapView.overlaysClickable = YES;
    self.mapView.delegate = self;

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

        [self.mapView addOverlay:polygon];
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
            circle.coordinate = GMCoordinateMake(latitude, longitude);
            
            [self.mapView addOverlay:circle];
        }
    }
}

- (void)mapView:(GMMapView *)mapView overlayClicked:(GMOverlay *)overlay locationInView:(CGPoint)location
{
    if (![overlay isKindOfClass:GMCircle.class])
        return;

    CGRect rect = CGRectZero;

    rect.origin = [self.mapView convertPoint:location toView:nil];
    rect = [self.window convertRectToScreen:rect];
    self.inspectorPanel.frameOrigin = rect.origin;
    [self.inspectorPanel makeKeyAndOrderFront:self];

    self.selectedCircle = (GMCircle *)overlay;
}

- (void)mapView:(GMMapView *)mapView clickedAtPoint:(GMMapPoint)mapPoint locationInView:(CGPoint)location
{
    if (!self.addCircleOnClick)
        return;
    
    GMCircle *circle = GMCircle.new;

    circle.lineWidth = 2;
    circle.strokeColor = [NSColor redColor];
    circle.fillColor = [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.5];
    circle.centerPointColor = [NSColor blueColor];
    circle.centerPointSize = 6;
    circle.radius = 500;
    circle.mapPoint = mapPoint;
    [self.mapView addOverlay:circle];

}

- (void)mapView:(GMMapView *)mapView simpleClickedAtPoint:(GMMapPoint)mapPoint locationInView:(CGPoint)location
{
	NSLog(@"simple click @ (%@,%@)", @(mapPoint.x), @(mapPoint.y));
}

- (void)mapView:(GMMapView *)mapView doubleClickedAtPoint:(GMMapPoint)mapPoint locationInView:(CGPoint)location
{
	NSLog(@"double click @ (%@,%@)", @(mapPoint.x), @(mapPoint.y));
}

- (IBAction)fitOverlays:(id)sender
{
    [self.mapView zoomToFitOverlays:self.mapView.overlays];
}


@end
