
#import <QuartzCore/QuartzCore.h>
#import "GMDrawDelegate.h"
#import "GMMapView.h"

@interface GMDrawDelegate ()

@property (assign) GMMapView *mapView;
@property (readonly) NSInteger tileZoomLevel;

- (NSURL *)tileURLForX:(NSInteger)x y:(NSInteger)y;

@end


@implementation GMDrawDelegate

- (id)initWithMapView:(GMMapView *)mapView
{
    self = [super init];
    if (!self) return nil;
    
    self.mapView = mapView;
    return self;
}

-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    CGPoint center = GMCoordinateToPoint(self.mapView.centerCoordinate);
    
    NSInteger n = 1 << self.tileZoomLevel;
    CGFloat tileX = center.x * n;
    CGFloat tileY = center.y * n;
    
    CGRect tileBounds = CGContextGetClipBoundingBox(context);
    CGRect layerBounds = layer.bounds;
    
    NSInteger x = tileBounds.origin.x / tileBounds.size.width;
    NSInteger y = tileBounds.origin.y / tileBounds.size.height;
    
    tileX += x;
    tileY -= y;
    
    NSURL *url = [self tileURLForX:tileX y:tileY];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);
    
    CGContextDrawImage(context, tileBounds, image);
    CGImageRelease(image);
}

- (NSInteger)tileZoomLevel
{
    return round(self.mapView.zoomLevel);
}

- (NSURL *)tileURLForX:(NSInteger)x y:(NSInteger)y
{
    return [NSURL URLWithString:[NSString stringWithFormat:self.mapView.tileURLFormat, self.tileZoomLevel, x, y]];
}

@end
